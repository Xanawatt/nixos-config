# Point-to-point WireGuard underlay tunnels (formerly igp_*.conf on the Ubuntu
# install). Table = off: no routes are installed by wg-quick, a routing daemon
# decides what goes over them. Keys are agenix secrets encrypted to the host key
# and the admin's key (see ~/.secrets/secrets.nix).
{ config, ... }:

let
  tunnel = name: { address, port, peerKey, endpoint, linkLocalPeer, keyFile }: {
    inherit address;
    listenPort = port;
    mtu = 1420;
    table = "off";
    privateKeyFile = keyFile;
    postUp = "ip address add dev ${name} fe80::1646 peer ${linkLocalPeer}";
    peers = [{
      publicKey = peerKey;
      allowedIPs = [ "0.0.0.0/0" "::/0" ];
      inherit endpoint;
      persistentKeepalive = 25;
    }];
  };
in
{
  age.secrets.wg-igp.file = ../../machines/ririka/secrets/ririka-wg-igp.age;
  age.secrets.wg-hazuki.file = ../../machines/ririka/secrets/ririka-wg-hazuki.age;

  networking.wg-quick.interfaces = {
    igp_hazuki = tunnel "igp_hazuki" {
      address = [ "192.168.255.44/31" ];
      port = 53022;
      peerKey = "EA5yNAPbCXbV2vlxx1tC/X1KEmkHgTDEt5HMv+4SvSQ=";
      endpoint = "129.159.115.27:53022";
      linkLocalPeer = "fe80::1747";
      keyFile = config.age.secrets.wg-hazuki.path;
    };
    igp_kanade = tunnel "igp_kanade" {
      address = [ "192.168.255.48/31" ];
      port = 53024;
      peerKey = "7QUBU6NIaG82IZA6ft9KGKkIQzahm1/MsJCMNQvbYGQ=";
      endpoint = "195.252.199.45:53024";
      linkLocalPeer = "fe80::2056";
      keyFile = config.age.secrets.wg-igp.path;
    };
    igp_yuuko = tunnel "igp_yuuko" {
      address = [ "192.168.255.43/31" ];
      port = 53021;
      peerKey = "vJM7iQX8B5rbtItE9hHxMZ148XiLOAMWm/RsSzopVH0=";
      endpoint = "99.2.49.107:53021";
      linkLocalPeer = "fe80::118";
      keyFile = config.age.secrets.wg-igp.path;
    };
  };

  networking.firewall.allowedUDPPorts = [ 53021 53022 53024 ];
}
