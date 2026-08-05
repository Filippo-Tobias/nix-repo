{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  glibc,
  gcc-unwrapped,
  pam,
  wayland,
  libxkbcommon,
  fontconfig,
}:

let
  data = builtins.fromJSON (builtins.readFile ./rosec.json);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "rosec";
  version = data.version;

  src = fetchzip {
    url = data.url;
    sha256 = data.hash;
  };

  # Bitwarden Password Manager provider plugin (WASM + policy + signature).
  wasmSrc = fetchzip {
    url = data.wasm_url;
    sha256 = data.wasm_hash;
    # Provider tarballs are a flat list of files (wasm + policy + minisig),
    # not a single top-level directory.
    stripRoot = false;
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  # wayland/libxkbcommon/fontconfig are dlopen'd at runtime by the rosec-prompt
  # GUI (iced/winit) and its text rendering — NOT captured by ldd, so
  # autoPatchelfHook's NEEDED-resolution ignores them. runtimeDependencies
  # appends their lib dirs to every patched binary's RUNPATH unconditionally.
  # Without this, rosec-prompt panics with
  # WaylandError(Connection(NoWaylandLib)) in a Wayland session.
  runtimeDependencies = [
    wayland
    libxkbcommon
    fontconfig
  ];
  buildInputs = [
    glibc
    gcc-unwrapped.lib
    pam
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    # Native binaries
    install -Dm755 \
      ${finalAttrs.src}/rosec \
      ${finalAttrs.src}/rosecd \
      ${finalAttrs.src}/rosec-prompt \
      ${finalAttrs.src}/rosec-pam-unlock \
      ${finalAttrs.src}/rosec-uhid \
      -t $out/bin

    # PAM module (for auto-unlock at login/screen-unlock)
    install -Dm755 ${finalAttrs.src}/pam_rosec.so $out/lib/security/pam_rosec.so

    # WASM provider plugins (discovered by rosecd from the system dir,
    # /usr/lib/rosec/providers on Arch; on NixOS, wire these into
    # ~/.local/share/rosec/providers via home-manager)
    install -Dm644 \
      ${finalAttrs.wasmSrc}/rosec_bitwarden_pm.wasm \
      ${finalAttrs.wasmSrc}/rosec_bitwarden_pm.wasm.policy.toml \
      ${finalAttrs.wasmSrc}/rosec_bitwarden_pm.wasm.minisig \
      -t $out/lib/rosec/providers/

    # Shell completions
    install -Dm644 ${finalAttrs.src}/contrib/bash/rosec.bash \
      $out/share/bash-completion/completions/rosec
    install -Dm644 ${finalAttrs.src}/contrib/zsh/_rosec \
      $out/share/zsh/site-functions/_rosec

    # Docs & license
    install -Dm644 ${finalAttrs.src}/README.md $out/share/doc/rosec/README.md
    install -Dm644 ${finalAttrs.src}/LICENSE $out/share/licenses/rosec/LICENSE

    runHook postInstall
  '';

  meta = {
    description = "Multi-provider Secret Service daemon with SSH agent, FUSE mount, and PAM unlock";
    homepage = "https://github.com/jmylchreest/rosec";
    license = lib.licenses.mit;
    mainProgram = "rosec";
    platforms = lib.platforms.linux;
  };
})
