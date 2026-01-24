{
  stdenv,
  lib,
  bun,
  bun2nix,
  opencode-cursor-auth-src,
}:
stdenv.mkDerivation {
  pname = "opencode-cursor-auth";
  version = "0.1.1";

  src = opencode-cursor-auth-src;

  nativeBuildInputs = [
    bun
    bun2nix.hook
  ];

  bunDeps = bun2nix.fetchBunDeps {
    bunNix = ./bun.nix;
  };

  bunInstallFlags =
    if stdenv.hostPlatform.isDarwin then
      [
        "--linker=hoisted"
        "--backend=copyfile"
      ]
    else
      [ "--linker=hoisted" ];

  dontUseBunCheck = true;

  buildPhase = ''
    runHook preBuild
    bun run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out

    # Runtime: opencode loads the plugin JS and expects dependencies to
    # resolve via standard Node resolution (node_modules up the directory tree).
    cp -R dist $out/dist
    cp -R node_modules $out/node_modules

    # Preserve package boundary ("type": "module") for ESM resolution.
    cp package.json $out/package.json
    cp opencode.json $out/opencode.json
    runHook postInstall
  '';

  meta = {
    description = "yet-another-opencode-cursor-auth packaged for opencode";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
