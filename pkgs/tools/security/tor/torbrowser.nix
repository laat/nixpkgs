{ stdenv, fetchurl, buildEnv
, xlibs, alsaLib, dbus, dbus_glib, glib, gtk, atk, pango, freetype, fontconfig
, gdk_pixbuf, cairo, zlib}:
let
  bits = if stdenv.system == "x86_64-linux" then "64"
         else "32";

  # isolated tor environment
  torEnv = buildEnv {
    name = "tor-env";
    paths = [
      stdenv.cc.cc zlib glib alsaLib dbus dbus_glib gtk atk pango freetype
      fontconfig gdk_pixbuf cairo xlibs.libXrender xlibs.libX11 xlibs.libXext
      xlibs.libXt
    ];
  };

  ldLibraryPath = if bits == "64" then torEnv+"/lib:"+torEnv+"/lib64"
        else torEnv+"/lib";

in stdenv.mkDerivation rec {
  name = "tor-browser-${version}";
  version = "4.0.6";

  src = fetchurl {
    url = "https://archive.torproject.org/tor-package-archive/torbrowser/${version}/tor-browser-linux${bits}-${version}_en-US.tar.xz";
    sha256 = if bits == "64" then
      "d954510bf812f624945bdba8e1c37e23573de89e2f159d7c89a3e3589a765559" else
      "89ce71312f5d73fc2af637a93d7697587b2132fce0e9f6e815b25ddba66518d0";
  };

  patchPhase = ''
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" Browser/firefox
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" Browser/TorBrowser/Tor/tor
  '';

  doCheck = true;
  checkPhase = ''
    # Just do a simple test if all libraries get loaded by running help on
    # firefox and tor
    echo "Checking firefox..."
    LD_LIBRARY_PATH=${ldLibraryPath} Browser/firefox --help 1> /dev/null
    echo "Checking tor..."
    LD_LIBRARY_PATH=${torEnv}/lib:Browser/TorBrowser/Tor Browser/TorBrowser/Tor/tor --help 1> /dev/null
  '';

  installPhase = ''
    mkdir -p $out/share/tor-browser
    mkdir -p $out/bin
    cp -R * $out/share/tor-browser

    cat > "$out/bin/tor-browser" << EOF
      export HOME="\$HOME/.torbrowser4"
      if [ ! -d \$HOME ]; then
        mkdir -p \$HOME && cp -R $out/share/tor-browser/Browser/TorBrowser/Data \$HOME/ && chmod -R +w \$HOME
        echo "pref(\"extensions.torlauncher.tordatadir_path\", \"\$HOME/Data/Tor/\");" >> \
          ~/Data/Browser/profile.default/preferences/extension-overrides.js
      fi
      export LD_LIBRARY_PATH=${ldLibraryPath}:$out/share/tor-browser/Browser/TorBrowser/Tor
      $out/share/tor-browser/Browser/firefox -no-remote -profile ~/Data/Browser/profile.default "$@"
    EOF
    chmod +x $out/bin/tor-browser
  '';

  buildInputs = [ stdenv ];

  meta = {
    description = "Tor Browser Bundle";
    homepage    = https://www.torproject.org/;
    platforms   = stdenv.lib.platforms.linux;
    maintainers = with stdenv.lib.maintainers;
      [ offline matejc doublec thoughtpolice ];
  };
}
