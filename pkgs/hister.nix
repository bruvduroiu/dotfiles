{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
}:

buildGoModule rec {
  pname = "hister";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "asciimoo";
    repo = "hister";
    rev = "v${version}";
    hash = "sha256-nGvesnSuWCsGjM0/Zp0tfZuP/V+EHLTOXKCHvjRrgSw=";
  };

  vendorHash = "sha256-3rAw9YMvDqh7aA1cft2NghfQ8jEiZdwykajJUwu7Zus=";

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion --cmd hister \
      --fish <($out/bin/hister completion fish)
  '';

  meta = {
    description = "Web history on steroids";
    homepage = "https://github.com/asciimoo/hister";
    license = lib.licenses.agpl3Only;
    mainProgram = "hister";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
