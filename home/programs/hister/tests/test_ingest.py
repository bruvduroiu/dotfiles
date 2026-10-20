import importlib
import sys
from pathlib import Path

import pytest
from docling_core.types.doc import (
    BoundingBox,
    DocItemLabel,
    DoclingDocument,
    ProvenanceItem,
    Size,
)

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
ingest = importlib.import_module("ingest")


def paged_document(pages, filled):
    doc = DoclingDocument(name="Trial")
    for page in pages:
        doc.add_page(page_no=page, size=Size(width=100, height=100))
    for page in filled:
        for line in ["Searchable text", "More text"]:
            text = f"{line} on page {page}."
            doc.add_text(
                label=DocItemLabel.TEXT,
                text=text,
                prov=ProvenanceItem(
                    page_no=page,
                    bbox=BoundingBox(l=0, t=10, r=50, b=0),
                    charspan=(0, len(text)),
                ),
            )
    return doc


@pytest.fixture
def document():
    doc = paged_document([1, 2], [1, 2])
    return {
        "status": "success",
        "document": {
            "json_content": doc.model_dump(mode="json"),
            "md_content": doc.export_to_markdown(),
        },
    }


@pytest.fixture
def config(tmp_path):
    root = tmp_path / "originals"
    root.mkdir()
    state = tmp_path / "state"
    return {
        "state_dir": str(state),
        "docling_url": "http://localhost:1",
        "conversion_timeout": 5,
        "max_file_bytes": 1000,
        "max_conversions": 10,
        "extensions": [".pdf", ".docx"],
        "documents": {"papers": {"path": str(root)}},
        "collections": {"papers": {"path": str(state / "converted/papers")}},
    }


@pytest.fixture
def client(monkeypatch, document):
    class FakeDocling:
        submissions = []
        results = []
        failure = None

        def __init__(self, *_):
            pass

        def get(self, _):
            return {"docling": "test"}

        def submit(self, path, options):
            self.submissions.append(path)
            return "a-b"

        def result(self, task):
            self.results.append(task)
            if self.failure:
                raise self.failure
            return document

    monkeypatch.setattr(ingest, "Docling", FakeDocling)
    return FakeDocling


def source(config, name="paper.pdf"):
    path = Path(config["documents"]["papers"]["path"]) / name
    path.write_bytes(b"fake PDF for orchestration test")
    return path


def manifest(config):
    return ingest.load_json(Path(config["state_dir"]) / "manifest.json")


def outputs(config):
    return list((Path(config["state_dir"]) / "converted/papers").glob("*.md"))


def test_incremental_rename_and_deletion(config, client):
    path = source(config)
    assert ingest.ingest(config) == 0
    assert len(client.submissions) == 1
    assert ingest.ingest(config) == 0
    assert len(client.submissions) == 1
    path = path.rename(path.with_name("renamed.pdf"))
    assert ingest.ingest(config) == 0
    assert len(client.submissions) == 1  # content cache survives rename
    assert len(outputs(config)) == 1
    assert str(path) in outputs(config)[0].read_text()
    path.unlink()
    assert ingest.ingest(config) == 0
    assert not outputs(config)
    assert not manifest(config)["documents"]


def test_failure_preserves_last_success(config, client):
    path = source(config)
    ingest.ingest(config)
    before = outputs(config)[0].read_text()
    path.write_bytes(b"changed file")
    client.failure = ValueError("OCR failed")
    assert ingest.ingest(config) == 1
    assert outputs(config)[0].read_text() == before
    record = next(iter(manifest(config)["documents"].values()))
    assert "OCR failed" in record["error"]
    assert "task_id" not in record


def test_timeout_resumes_job(config, client, monkeypatch):
    source(config)
    client.failure = TimeoutError("still pending")
    assert ingest.ingest(config) == 1
    client.failure = None
    retry = next(iter(manifest(config)["documents"].values()))["retry_after"]
    monkeypatch.setattr(ingest.time, "time", lambda: retry + 1)
    assert ingest.ingest(config) == 0
    assert len(client.submissions) == 1
    assert client.results == ["a-b", "a-b"]


def test_missing_root_does_not_prune(config, client):
    path = source(config)
    ingest.ingest(config)
    path.parent.rename(path.parent.with_name("offline"))
    assert ingest.ingest(config) == 1
    assert len(outputs(config)) == 1
    assert "papers" in manifest(config)["collection_errors"]


def test_limit_does_not_delete_unprocessed_documents(config, client):
    for name in ["a.pdf", "b.pdf"]:
        source(config, name)
    ingest.ingest(config)
    for path in Path(config["documents"]["papers"]["path"]).glob("*.pdf"):
        path.write_text(path.name)
    config["max_conversions"] = 1
    ingest.ingest(config)
    assert len(outputs(config)) == 2
    assert len(manifest(config)["documents"]) == 2
    ingest.ingest(config)
    assert not any(r.get("error") for r in manifest(config)["documents"].values())


def test_scan_rejects_symlinks_and_excludes(config, tmp_path):
    root = Path(config["documents"]["papers"]["path"])
    external = tmp_path / "outside.pdf"
    external.write_text("private")
    (root / "alias.pdf").symlink_to(external)
    (root / "directory").symlink_to(tmp_path, target_is_directory=True)
    source(config, "skip.pdf")
    kept = source(config)
    assert ingest.scan(root, [".pdf"], ["skip.pdf"]) == [kept]


def test_source_changed_during_upload_is_not_published(
    config, client, monkeypatch, document
):
    path = source(config)

    def changed(_self, _task):
        path.write_text("changed while the server was reading")
        return document

    monkeypatch.setattr(client, "result", changed)
    assert ingest.ingest(config) == 1
    assert not outputs(config)


def test_docx_has_no_invented_page_numbers(document, tmp_path):
    text = ingest.render(document, tmp_path / "document.docx", "hash")
    assert "source-page" not in text
    assert "Searchable text" in text


def test_bad_conversion_keeps_previous_output(config, client, monkeypatch):
    path = source(config)
    ingest.ingest(config)
    previous = outputs(config)[0].read_text()
    path.write_text("changed")
    monkeypatch.setattr(
        client, "result", lambda *_: {"document": {"json_content": None}}
    )
    assert ingest.ingest(config) == 1
    assert outputs(config)[0].read_text() == previous


def test_backoff_does_not_block_a_new_source_version(config, client):
    path = source(config)
    client.failure = ValueError("failed OCR")
    assert ingest.ingest(config) == 1
    assert ingest.ingest(config) == 0  # backing off; no repeated submission
    assert len(client.submissions) == 1
    path.write_text("corrected source")
    client.failure = None
    assert ingest.ingest(config) == 0
    assert len(client.submissions) == 2
    assert len(outputs(config)) == 1


def test_pdf_keeps_original_path_and_pages(document, tmp_path):
    source = tmp_path / "paper.pdf"
    text = ingest.render(document, source, "hash")
    assert str(source) in text
    assert "## Page 1" in text
    assert "## Page 2" in text
    assert "source_sha256" in text


@pytest.mark.parametrize(
    ("pages", "filled"),
    [([1, 2, 3], [1, 3]), ([1, 2, 3], [2]), ([1], [1]), ([4, 5], [4, 5])],
)
def test_single_pass_pages_match_per_page_export(pages, filled):
    doc = paged_document(pages, filled)
    expected = {
        page: doc.export_to_markdown(page_no=page, traverse_pictures=True)
        for page in pages
    }
    found = {page: text.strip() for page, text in ingest.pages(doc)}
    assert found == {page: text for page, text in expected.items() if text}


def test_conversion_renders_once(config, client, monkeypatch):
    source(config)
    calls = []
    original = ingest.render
    monkeypatch.setattr(
        ingest, "render", lambda *args: calls.append(args) or original(*args)
    )
    assert ingest.ingest(config) == 0
    assert len(calls) == 1
