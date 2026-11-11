# BIRD 2 routing daemon, ported from the Ubuntu install: OSPF over the igp_*
# WireGuard tunnels (see ../wireguard-igp) and iBGP route-reflector sessions
# to the two core routers, protected by BFD. The config is split into the same
# files as before (bird.conf, filters.conf, ospf*.conf, rr/*). The BFD
# passwords live in an agenix secret that defines the constants used below.
{ config, lib, pkgs, ... }:

let
  tunnels = [ "igp_hazuki" "igp_kanade" "igp_yuuko" ];
  confFiles = [
    "variables.conf"
    "filters.conf"
    "ospf.conf"
    "ospf_backbone.conf"
    "rr/kanade.conf"
    "rr/yuuko.conf"
  ];
in
{
  age.secrets.bird-bfd = {
    file = ../../machines/ririka/secrets/ririka-bird-bfd.age;
    owner = "bird";
    group = "bird";
    mode = "0400";
  };

  # Node addresses. loopback42 carries the router id / next-hop address,
  # loopback24 the legacy kitauji address; both are advertised as OSPF stubs.
  systemd.network.netdevs."50-loopback24".netdevConfig = { Name = "loopback24"; Kind = "bridge"; };
  systemd.network.netdevs."50-loopback42".netdevConfig = { Name = "loopback42"; Kind = "bridge"; };
  systemd.network.networks."50-loopback24" = {
    matchConfig.Name = "loopback24";
    networkConfig = { Address = "192.168.24.12/32"; ConfigureWithoutCarrier = true; };
    linkConfig.RequiredForOnline = "no";
  };
  systemd.network.networks."50-loopback42" = {
    matchConfig.Name = "loopback42";
    networkConfig = {
      Address = [ "172.22.179.107/32" "fd0b:4d5d:38d9:5::1/128" ];
      ConfigureWithoutCarrier = true;
    };
    linkConfig.RequiredForOnline = "no";
  };

  # Routing: forward, no reverse-path filtering (asymmetric paths over the tunnels).
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
  };

  # OSPF (proto 89), BFD and BGP all run inside the authenticated tunnels.
  networking.firewall.trustedInterfaces = tunnels;

  # The split config files install next to bird.conf under /etc/bird and are
  # pulled in with relative includes, like on the Ubuntu install.
  environment.etc = lib.genAttrs (map (f: "bird/${f}") confFiles) (n: {
    source = ./. + "/${lib.removePrefix "bird/" n}";
  }) // {
    "bird/bfd-secret.conf".source = config.age.secrets.bird-bfd.path;
  };

  services.bird = {
    enable = true;
    package = pkgs.bird2;
    config = builtins.readFile ./bird.conf;
    # The secret only exists at runtime; give the build-time check a stub and
    # the split files.
    preCheckConfig = ''
      cat > bfd-secret.conf <<'STUB'
      define BFD_IFACE_PASSWORD = "stub";
      define BFD_MULTIHOP_PASSWORD = "stub";
      STUB
      mkdir rr
      ${lib.concatMapStringsSep "\n" (f: "cp ${./. + "/${f}"} ${f}") confFiles}
    '';
  };
}
