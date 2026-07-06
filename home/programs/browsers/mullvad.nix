{ pkgs, inputs, ... }:

let
  inherit (inputs.secrets.vars.i2pProxy) host port;

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

      // I2P tunnels are end-to-end encrypted and a .i2p/b32 address is the
      // hash of the destination's key (self-authenticating), so layered TLS is
      // redundant. Stop HTTPS-Only mode from upgrading http:// eepsites and
      // throwing "connection is not secure" warning pages. Safe here only
      // because the browser is locked to the I2P proxy with no outproxy, so it
      // cannot reach clearnet to downgrade a real site.
      lockPref("dom.security.https_only_mode", false);
      lockPref("dom.security.https_only_mode_ever_enabled", false);
      lockPref("dom.security.https_first", false);
    '';
  };
in
{
  home.packages = [ mullvad-browser-i2p ];
}
