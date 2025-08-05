{
  lib,
  stdenv,
  callPackage,
  vscode-generic,
  fetchurl,
  extraCommandLineArgs ? "",
  useVSCodeRipgrep ? stdenv.hostPlatform.isDarwin,
}:

let
  inherit (stdenv) hostPlatform;
  version = "0.1.42";
  sources = {
    x86_64-linux = fetchurl {
      url = "https://prod.download.desktop.kiro.dev/releases/202508020245--distro-linux-x64-tar-gz/202508020245-distro-linux-x64.tar.gz";
      hash = "sha256-2kUx4PEqVcLF2/gk1+bxjeVrfX6wOxfRpLeMevNNsR8=";
    };
    x86_64-darwin = fetchurl {
      url = "https://prod.download.desktop.kiro.dev/releases/202508020251-Kiro-dmg-darwin-x64.dmg";
      hash = "sha256-8P562N6b4PyNYgNICyrlVxphkQjXdv80VEXtk71iabE=";
    };
    aarch64-darwin = fetchurl {
      url = "https://prod.download.desktop.kiro.dev/releases/202508020230-Kiro-dmg-darwin-arm64.dmg";
      hash = "sha256-YBHnFmoVfrl4chEkj9YBP2aUZ4g9UY9AixgCFKV5FVU=";
    };
  };
  src = sources.${hostPlatform.system} or (throw "Unsupported platform for Kiro");
in
(callPackage vscode-generic {
  inherit useVSCodeRipgrep;
  commandLineArgs = extraCommandLineArgs;

  inherit version;
  pname = "kiro";

  # You can find the current VSCode version in the About dialog:
  # workbench.action.showAboutDialog (Help: About)
  vscodeVersion = "1.94.0";

  executableName = "kiro";
  longName = "Kiro";
  shortName = "kiro";
  libraryName = "kiro";
  iconName = "kiro";

  inherit src;
  sourceRoot = "Kiro";
  patchVSCodePath = true;

  tests = { };
  updateScript = ./update.sh;

  meta = {
    description = "IDE for Agentic AI workflows based on VS Code";
    homepage = "https://kiro.dev";
    license = lib.licenses.amazonsl;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ vuks ];
    platforms = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "kiro";
  };

}).overrideAttrs
  (oldAttrs: {
    passthru = (oldAttrs.passthru or { }) // {
      inherit sources;
    };
  })
