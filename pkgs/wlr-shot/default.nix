{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  pipewire,
  ffmpeg_6,
  wayland,
  libxkbcommon,
  mesa,
  vulkan-loader,
  libdrm,
  libglvnd,
  fontconfig,
}:

let
  data = builtins.fromJSON (builtins.readFile ./wlr-shot.json);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "wlr-shot";
  version = data.version;

  # Upstream publishes a static-features release tarball (sjourdois/wlr-utils),
  # which also ships wlr-chooser, wlr-overlayd, wlr-peek, wlr-draw and
  # wlr-switcher. Only wlr-shot and wlr-chooser are installed; the rest need a
  # running compositor session and are out of scope here.
  #
  # The archive holds one top-level directory, so unpackPhase enters it and every
  # later phase runs with it as the cwd -- hence the bare relative paths below.
  src = fetchurl {
    url = data.url;
    hash = data.hash;
  };

  sourceRoot = "wlr-utils-x86_64-unknown-linux-gnu";

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    pipewire
    ffmpeg_6
    wayland
    libxkbcommon
    mesa
    vulkan-loader
    libdrm
    libglvnd
    fontconfig
  ];

  dontBuild = true;
  dontConfigure = true;
  # Strip is fine; only performance-sensitive code would care.
  dontStrip = false;

  installPhase = ''
    runHook preInstall

    install -Dm755 wlr-shot $out/bin/wlr-shot

    # wlr-chooser is the interactive window picker wlr-shot's --pick-window
    # shells out to. Installing the binary (it is only spawned on demand, so it
    # needs no compositor connection at build time) makes that flag usable.
    if [ -x wlr-chooser ]; then
      install -Dm755 wlr-chooser $out/bin/wlr-chooser
    fi

    install -Dm644 README.md $out/share/doc/wlr-shot/README.md
    install -Dm644 LICENSE-MIT $out/share/licenses/wlr-shot/LICENSE-MIT
    install -Dm644 LICENSE-APACHE $out/share/licenses/wlr-shot/LICENSE-APACHE

    runHook postInstall
  '';

  # The prebuilt binary is a Debian/gnu build with no RUNPATH, so every NEEDED
  # entry and every dlopen'd library has to be resolved by hand.
  #
  # Two distinct groups, and the second one is easy to miss:
  #   * linked  -- pipewire, the six ffmpeg sonames, wayland, xkbcommon, gbm.
  #     autoPatchelfHook resolves these from buildInputs.
  #   * dlopen  -- libEGL/libGL and libvulkan, which the GPU capture path opens
  #     at runtime via libloading. These appear in no NEEDED entry, so
  #     autoPatchelfHook cannot see them and leaves them unresolved; without
  #     them the capture silently degrades to the shared-memory path or fails
  #     outright. runtimeDependencies appends their lib dirs to the RUNPATH
  #     unconditionally, which is the only hook that can cover them.
  runtimeDependencies = [ mesa vulkan-loader libdrm libglvnd fontconfig ];

  meta = {
    description = "Screen capture for wlroots compositors: screenshots of an output, region or window";
    longDescription = ''
      wlr-shot captures via ext-image-copy-capture-v1, so it can grab a window's
      own surface rather than the pixels currently on an output. That means it
      works for windows on other workspaces and for windows that are occluded,
      which grim and hyprshot cannot do. Hyprland implements the protocol.
    '';
    homepage = "https://github.com/sjourdois/wlr-utils";
    license = lib.licenses.mit or lib.licenses.asl20;
    mainProgram = "wlr-shot";
    platforms = lib.platforms.linux;
  };
})