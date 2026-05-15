{
  agentsInputs,
  pkgs,
  system,
}:

let
  inherit (pkgs) lib stdenv;

  versionData = builtins.fromJSON (builtins.readFile ./hashes.json);
  inherit (versionData) version hashes;

  platformMap = {
    aarch64-darwin = {
      asset = "ocv-darwin-arm64";
    };
    x86_64-darwin = {
      asset = "ocv-darwin-x64";
    };
    aarch64-linux = {
      asset = "ocv-linux-arm64";
    };
    x86_64-linux = {
      asset = "ocv-linux-x64";
    };
  };

  platform = platformMap.${system} or (throw "Unsupported system: ${system}");
in
stdenv.mkDerivation {
  pname = "opencode-vim";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/leohenon/opencode-vim/releases/download/v${version}/${platform.asset}";
    hash = hashes.${system} or (throw "Missing opencode-vim hash for ${system}");
  };

  nativeBuildInputs = [
    pkgs.makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    agentsInputs.llm-agents.packages.${system}.wrapBuddy
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;
  dontUnpack = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -m755 $src $out/bin/ocv
    wrapProgram $out/bin/ocv \
      --prefix PATH : ${
        lib.makeBinPath [
          pkgs.fzf
          pkgs.ripgrep
        ]
      }
    ln -s ocv $out/bin/opencode

    runHook postInstall
  '';

  passthru.category = "AI Coding Agents";

  meta = {
    description = "OpenCode fork with vim mode";
    homepage = "https://github.com/leohenon/opencode-vim";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = builtins.attrNames platformMap;
    mainProgram = "ocv";
  };
}
