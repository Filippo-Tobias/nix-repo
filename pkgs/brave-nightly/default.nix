{
  lib,
  brave,
  fetchurl,
}:

let
  nightlyData = builtins.fromJSON (builtins.readFile ./brave-nightly.json);
in
brave.overrideAttrs (oldAttrs: rec {
  pname = "brave-browser-nightly";
  version = nightlyData.version;

  src = fetchurl {
    url = "https://github.com/brave/brave-browser/releases/download/v${version}/brave-browser-nightly_${version}_amd64.deb";
    sha256 = nightlyData.hash;
  };

  prePatch = (oldAttrs.prePatch or "") + ''
    # Rename the primary application folder
    if [ -d opt/brave.com/brave-nightly ]; then
      mv opt/brave.com/brave-nightly opt/brave.com/brave
    fi

    # Rename the binary executable
    if [ -f opt/brave.com/brave/brave-browser-nightly ]; then
      mv opt/brave.com/brave/brave-browser-nightly opt/brave.com/brave/brave-browser
    fi

    # Fix the internal icon names in /opt
    for size in 16 24 32 48 64 128 256; do
      find opt/brave.com/brave -name "product_logo_$size*.png" ! -name "product_logo_$size.png" -exec mv {} opt/brave.com/brave/product_logo_$size.png \; || true
    done

    # Handle both hyphens and dots safely in usr/share
    find usr/share -depth -name "*nightly*" | while read -r path; do
      new_path="''${path//-nightly/}"
      new_path="''${new_path//.nightly/}"
      
      if [ "$path" != "$new_path" ]; then
        mv "$path" "$new_path"
      fi
    done

    # Ensure both possible Desktop shortcut names exist
    if [ -f usr/share/applications/com.brave.Browser.desktop ] && [ ! -f usr/share/applications/brave-browser.desktop ]; then
      cp usr/share/applications/com.brave.Browser.desktop usr/share/applications/brave-browser.desktop
    elif [ -f usr/share/applications/brave-browser.desktop ] && [ ! -f usr/share/applications/com.brave.Browser.desktop ]; then
      cp usr/share/applications/brave-browser.desktop usr/share/applications/com.brave.Browser.desktop
    fi

    # Trick the Nixpkgs string-replacement
    sed -i 's|/usr/bin/brave-browser-nightly|/usr/bin/brave-browser-stable|g' usr/share/applications/*.desktop || true
    sed -i 's|^Icon=.*|Icon=brave-browser|g' usr/share/applications/*.desktop || true
  '';
})
