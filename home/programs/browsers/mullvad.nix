{ pkgs, ... }:

let
  host = "10.0.20.122";
  port = 4444;

  mullvad-browser-i2p = pkgs.mullvad-browser.override {
    extraPrefs = ''
      lockPref("network.proxy.type", 1); // 1 = manual
      lockPref("network.proxy.http", "${host}");
      lockPref("network.proxy.http_port", ${toString port});
      lockPref("network.proxy.ssl", "${host}");
      lockPref("network.proxy.ssl_port", ${toString port});
      lockPref("network.proxy.share_proxy_settings", true);

      // HTTP proxy resolves hostnames proxy-side; disable DoH/TRR so stuff
      // never leaks to a clearnet resolver.
      lockPref("network.trr.mode", 5); // 5 = off, never use TRR
      lockPref("network.proxy.socks_remote_dns", true);
    '';
  };
in
{
  home.packages = [ mullvad-browser-i2p ];
}
