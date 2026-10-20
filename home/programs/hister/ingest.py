"""Incremental Docling conversion for Hister watched Markdown directories."""

import fnmatch
import hashlib
import json
import os
import re
import time
from importlib.metadata import version
from pathlib import Path

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


def atomic_write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(text, encoding="utf-8")
    temporary.replace(path)


def save_json(path: Path, value: dict) -> None:
    atomic_write(path, json.dumps(value, ensure_ascii=False, indent=2) + "\n")


def load_json(path: Path) -> dict:
    return json.loads(path.read_text()) if path.exists() else {}


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def scan(root: Path, extensions: list[str], excludes: list[str]) -> list[Path]:
    """Never follow symlinks or silently interpret an unreadable root as empty."""
    if not root.is_dir() or root.is_symlink():
        raise ValueError(f"Document root unavailable: {root}")

    def scan_error(error: OSError) -> None:
        raise error

    files = []
    for directory, dirs, names in os.walk(root, onerror=scan_error, followlinks=False):
        base = Path(directory)
        dirs[:] = [
            name
            for name in dirs
            if not name.startswith(".") and not (base / name).is_symlink()
        ]
        for name in names:
            path = base / name
            relative = path.relative_to(root).as_posix()
            if (
                not name.startswith(".")
                and not path.is_symlink()
                and path.suffix.lower() in extensions
                and not any(fnmatch.fnmatchcase(relative, p) for p in excludes)
            ):
                files.append(path)
    return sorted(files)


class Docling:
    def __init__(self, endpoint: str, timeout: int):
        self.endpoint = endpoint.rstrip("/")
        self.timeout = timeout
        self.session = requests.Session()
        # Retry reads only: retrying a submission can create duplicate jobs.
        retry = Retry(
            total=2,
            backoff_factor=1,
            allowed_methods={"GET"},
            status_forcelist=[429, 502, 503, 504],
        )
        self.session.mount("http://", HTTPAdapter(max_retries=retry))
        self.session.mount("https://", HTTPAdapter(max_retries=retry))

    def get(self, route: str) -> dict:
        response = self.session.get(self.endpoint + route, timeout=(10, 60))
        response.raise_for_status()
        data = response.json()
        if not isinstance(data, dict):
            raise ValueError("Docling returned a non-object JSON response")
        return data

    def submit(self, path: Path, options: dict) -> str:
        with path.open("rb") as stream:
            response = self.session.post(
                self.endpoint + "/v1/convert/file/async",
                files={"files": (path.name, stream, "application/octet-stream")},
                data=options,
                timeout=(10, 120),
            )
        response.raise_for_status()
        data = response.json()
        task = data.get("task_id") if isinstance(data, dict) else None
        if (
            not isinstance(task, str)
            or not task
            or any(c not in "0123456789abcdef-" for c in task)
        ):
            raise ValueError("Docling returned an invalid task ID")
        return task

    def result(self, task: str) -> dict:
        deadline = time.monotonic() + self.timeout
        while time.monotonic() < deadline:
            status = self.get(f"/v1/status/poll/{task}")["task_status"]
            if status == "success":
                result = self.get(f"/v1/result/{task}")
                if result.get("status") != "success":
                    raise ValueError(f"Docling result status: {result.get('status')}")
                return result
            if status not in {"pending", "started"}:
                raise ValueError(f"Docling task ended with status: {status}")
            time.sleep(2)
        # Keep task_id in the manifest so the next run resumes this job.
        raise TimeoutError(f"Docling task {task} is still pending")


PAGE_BREAK = re.compile(r"#_#_DOCLING_DOC_PAGE_BREAK_(\d+)_(\d+)_#_#")


def pages(document) -> list[tuple[int, str]]:
    """Split Markdown by page in one serializer pass.

    export_to_markdown(page_no=...) walks the whole document for every page, which
    takes hours on a book. Docling's internal page-break markers carry the page
    numbers, so keep them instead of replacing them with a fixed placeholder.
    """
    from docling_core.transforms.serializer.common import create_ser_result
    from docling_core.transforms.serializer.markdown import (
        MarkdownDocSerializer,
        MarkdownParams,
    )
    from docling_core.types.doc import DocItem

    class Serializer(MarkdownDocSerializer):
        def serialize_doc(self, *, parts, **kwargs):
            text = "\n\n".join(part.text for part in parts if part.text)
            return create_ser_result(text=text, span_source=parts)

    params = MarkdownParams(
        page_break_placeholder="", traverse_pictures=True, blocked_meta_names=set()
    )
    text = Serializer(doc=document, params=params).serialize().text
    # re.split interleaves captures: [body, prev, next, body, prev, next, body, ...]
    split = PAGE_BREAK.split(text)
    if len(split) > 1:
        first = int(split[1])
    else:
        first = next(
            (
                item.prov[0].page_no
                for item, _ in document.iterate_items(traverse_pictures=True)
                if isinstance(item, DocItem) and item.prov
            ),
            min(document.pages),
        )
    numbers = [first] + [int(n) for n in split[2::3]]
    return list(zip(numbers, split[::3]))


def render(result: dict, source: Path, source_hash: str) -> str:
    """Use Docling's own serializer, retaining PDF page boundaries for opening."""
    from docling_core.types.doc import DoclingDocument

    exported = result["document"]
    if not isinstance(exported, dict) or not isinstance(
        exported.get("json_content"), dict
    ):
        raise ValueError("Docling response is missing structured document JSON")
    document = DoclingDocument.model_validate(exported["json_content"])
    header = "\n".join(
        [
            "---",
            "source_path: " + json.dumps(str(source), ensure_ascii=False),
            "source_sha256: " + json.dumps(source_hash),
            "---",
            f"# {source.name}",
            "",
            f"Original: {source}",
            "",
        ]
    )
    if source.suffix.lower() == ".pdf" and document.pages:
        body = "\n\n".join(
            f"<!-- source-page: {page} -->\n## Page {page}\n\n{text.strip()}"
            for page, text in pages(document)
            if text.strip()
        )
    else:
        body = exported.get("md_content") or document.export_to_markdown(
            traverse_pictures=True
        )
    if not body.strip():
        raise ValueError("Docling produced no searchable text")
    return header + body + "\n"


def ingest(config: dict) -> int:
    """Publish successes; preserve old output on failure. Return failure count."""
    state = Path(config["state_dir"])
    manifest_path = state / "manifest.json"
    manifest = load_json(manifest_path)
    entries = manifest.setdefault("documents", {})
    client = Docling(config["docling_url"], config["conversion_timeout"])
    options = {
        "to_formats": ["md", "json"],
        "do_ocr": "true",
        "force_ocr": "false",
        "image_export_mode": "placeholder",
        **config.get("conversion_options", {}),
    }
    try:
        versions = client.get("/version")
    except (requests.RequestException, ValueError) as error:
        manifest["error"] = f"Docling unavailable: {error}"
        save_json(manifest_path, manifest)
        return 1
    # Version the renderer too: source and conversion options alone are not enough.
    profile = hashlib.sha256(
        json.dumps(
            {
                "versions": versions,
                "options": options,
                "renderer": 1,
                "docling_core": version("docling-core"),
            },
            sort_keys=True,
        ).encode()
    ).hexdigest()
    manifest.pop("error", None)
    failures = 0
    attempts = 0
    for collection, settings in config["documents"].items():
        root = Path(settings["path"])
        output = state / "converted" / collection
        output.mkdir(parents=True, exist_ok=True)
        try:
            files = scan(root, config["extensions"], settings.get("exclude", []))
        except (OSError, ValueError) as error:
            failures += 1
            manifest.setdefault("collection_errors", {})[collection] = str(error)
            continue
        manifest.setdefault("collection_errors", {}).pop(collection, None)
        seen = {
            collection + "/" + hashlib.sha256(str(path).encode()).hexdigest()
            for path in files
        }
        for path in files:
            # Stable per-path ID; shared conversion objects also allow cheap renames.
            key = collection + "/" + hashlib.sha256(str(path).encode()).hexdigest()
            record = entries.setdefault(key, {"source": str(path)})
            target = output / (key.split("/")[1] + ".md")
            signature = None
            try:
                if path.stat().st_size > config["max_file_bytes"]:
                    raise ValueError("Document exceeds configured maximum size")
                source_hash = digest(path)
                signature = source_hash + "-" + profile
                if record.get("signature") == signature and target.exists():
                    record.pop("error", None)
                    continue
                if (
                    record.get("retry_signature") == signature
                    and record.get("retry_after", 0) > time.time()
                ):
                    continue
                if attempts >= config.get("max_conversions", 10):
                    # Keep old output and retry next run, without claiming freshness.
                    record["error"] = "Pending conversion (per-run limit)"
                    continue
                attempts += 1
                cached = state / "objects" / (signature + ".json")
                if cached.exists():
                    text = render(load_json(cached), path, source_hash)
                else:
                    if record.get("pending_signature") != signature:
                        record.pop("task_id", None)
                    if not record.get("task_id"):
                        record.update(
                            task_id=client.submit(path, options),
                            pending_signature=signature,
                        )
                        save_json(manifest_path, manifest)
                    try:
                        result = client.result(record["task_id"])
                    except requests.HTTPError as error:
                        if error.response.status_code == 404:
                            record.pop("task_id", None)  # expired server-side job
                        raise
                    except ValueError:
                        record.pop("task_id", None)  # terminal failure; retry next run
                        raise
                    if digest(path) != source_hash:
                        record.pop("task_id", None)
                        raise ValueError(
                            "Source changed during conversion; retry next run"
                        )
                    # Validate/render before caching a response as usable.
                    text = render(result, path, source_hash)
                    save_json(cached, result)
                atomic_write(target, text)
                entries[key] = {
                    "source": str(path),
                    "signature": signature,
                    "source_hash": source_hash,
                    "converted_at": int(time.time()),
                }
            except (OSError, ValueError, KeyError, requests.RequestException) as error:
                failures += 1
                record["error"] = str(error)
                record["retry_signature"] = signature
                record["failures"] = record.get("failures", 0) + 1
                record["retry_after"] = time.time() + min(
                    3600, 60 * 2 ** min(record["failures"], 6)
                )
            save_json(manifest_path, manifest)
        # Prune only after a successful complete scan of this root.
        for key in list(entries):
            if key.startswith(collection + "/") and key not in seen:
                (output / (key.split("/")[1] + ".md")).unlink(missing_ok=True)
                del entries[key]
    manifest["last_run"] = int(time.time())
    save_json(manifest_path, manifest)
    return failures


def main() -> int:
    import fcntl
    import sys

    config = load_json(Path(sys.argv[1]))
    state = Path(config["state_dir"])
    state.mkdir(parents=True, exist_ok=True)
    with (state / "conversion.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        failures = ingest(config)
    if failures:
        print(
            f"{failures} conversion failures; see {state / 'manifest.json'}",
            file=sys.stderr,
        )
    return int(bool(failures))


if __name__ == "__main__":
    raise SystemExit(main())
