{ stdenv
, lib
, buildGoModule
, fetchFromGitHub
, installShellFiles
, buildPackages
, testers
, goreleaser
}:
buildGoModule rec {
  pname = "goreleaser";
  version = "1.26.2";

  src = fetchFromGitHub {
    owner = "goreleaser";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-/vRN3JcfAK0p9y4kusQooziozG7Wn40b4XjsXe+fE7E=";
  };

  vendorHash = "sha256-1tJksVsGEWVd2wjic4k8ow+/Is9GaCnBMg0UAJzwpkA=";

  ldflags =
    [ "-s" "-w" "-X main.version=${version}" "-X main.builtBy=nixpkgs" ];

  # tests expect the source files to be a build repo
  doCheck = false;

  nativeBuildInputs = [ installShellFiles ];

  postInstall =
    let emulator = stdenv.hostPlatform.emulator buildPackages;
    in ''
      ${emulator} $out/bin/goreleaser man > goreleaser.1
      installManPage ./goreleaser.1
      installShellCompletion --cmd goreleaser \
        --bash <(${emulator} $out/bin/goreleaser completion bash) \
        --fish <(${emulator} $out/bin/goreleaser completion fish) \
        --zsh  <(${emulator} $out/bin/goreleaser completion zsh)
    '';

  passthru.tests.version = testers.testVersion {
    package = goreleaser;
    command = "goreleaser -v";
    inherit version;
  };

  meta = with lib; {
    description = "Deliver Go binaries as fast and easily as possible";
    homepage = "https://goreleaser.com";
    maintainers = with maintainers; [
      c0deaddict
      sarcasticadmin
      techknowlogick
      developer-guy
      caarlos0
    ];
    license = licenses.mit;
    mainProgram = "goreleaser";
  };
}
