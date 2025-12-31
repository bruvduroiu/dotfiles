{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication rec {
  pname = "icloudpd";
  version = "1.32.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "icloud-photos-downloader";
    repo = "icloud_photos_downloader";
    rev = "v${version}";
    hash = "sha256-XwMY3OBGYDA/DKTXYgxuMV9pbamy8NbitMrEbsEmlMk=";
  };

  # Relax strict version pins in pyproject.toml to allow nixpkgs versions
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'setuptools==80.9.0' 'setuptools' \
      --replace-fail 'wheel==0.45.1' 'wheel' \
      --replace-fail 'requests==2.32.3' 'requests' \
      --replace-fail 'schema==0.7.7' 'schema' \
      --replace-fail 'tqdm==4.67.1' 'tqdm' \
      --replace-fail 'piexif==1.1.3' 'piexif' \
      --replace-fail 'urllib3==1.26.20' 'urllib3' \
      --replace-fail 'typing_extensions==4.14.0' 'typing_extensions' \
      --replace-fail 'Flask==3.1.1' 'Flask' \
      --replace-fail 'waitress==3.0.2' 'waitress' \
      --replace-fail 'tzlocal==5.3.1' 'tzlocal' \
      --replace-fail 'pytz==2025.2' 'pytz' \
      --replace-fail 'certifi==2025.4.26' 'certifi' \
      --replace-fail 'keyring==25.6.0' 'keyring' \
      --replace-fail 'keyrings-alt==5.0.2' 'keyrings-alt' \
      --replace-fail 'srp==1.0.22' 'srp'
  '';

  build-system = with python3Packages; [
    setuptools
    wheel
  ];

  dependencies = with python3Packages; [
    requests
    schema
    tqdm
    piexif
    urllib3
    typing-extensions
    flask
    waitress
    tzlocal
    pytz
    certifi
    keyring
    keyrings-alt
    srp
  ];

  # Tests require network access and iCloud credentials
  doCheck = false;

  meta = {
    description = "A command-line tool to download photos from iCloud";
    homepage = "https://github.com/icloud-photos-downloader/icloud_photos_downloader";
    changelog = "https://github.com/icloud-photos-downloader/icloud_photos_downloader/blob/v${version}/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "icloudpd";
    maintainers = [];
  };
}
