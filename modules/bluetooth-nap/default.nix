# Bluetooth PAN NAP server: clients (see ../bluetooth-pan-client) connect as PANU
# and land on br0, where systemd-networkd hands out DHCP and NATs out the uplink.
# Pairing is automatic (NoInputNoOutput agent) but the adapter is neither
# discoverable nor pairable by default; already-paired devices reconnect fine.
# To add a device, run `bt-pair-mode` on the Pi (open for 2 minutes).
{ pkgs, ... }:

let
  btPairMode = pkgs.writeShellScriptBin "bt-pair-mode" ''
    bluetoothctl discoverable-timeout 120
    bluetoothctl pairable-timeout 120
    bluetoothctl pairable on
    bluetoothctl discoverable on
    echo "Pairing open for 120s"
  '';
in

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General = {
      Name = "ririka";
      DiscoverableTimeout = 120;
      PairableTimeout = 120;
      AlwaysPairable = false;
      JustWorksRepairing = "always";
    };
  };

  environment.systemPackages = [ btPairMode ];

  # Bridge that BlueZ attaches bnepN interfaces to.
  systemd.network.netdevs."40-br0".netdevConfig = { Name = "br0"; Kind = "bridge"; };
  systemd.network.networks."40-br0" = {
    matchConfig.Name = "br0";
    networkConfig = {
      Address = "192.168.44.1/24";
      DHCPServer = true;
      ConfigureWithoutCarrier = true;
    };
    dhcpServerConfig = {
      PoolOffset = 10;
      PoolSize = 100;
      EmitDNS = true;
      DNS = "192.168.44.1";
    };
    linkConfig.RequiredForOnline = "no";
  };
  systemd.network.networks."41-bnep" = {
    matchConfig.Name = "bnep*";
    networkConfig.Bridge = "br0";
  };
  # Let resolved answer DNS queries from bluetooth clients.
  services.resolved.settings.Resolve.DNSStubListenerExtra = "192.168.44.1";

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.nat = {
    enable = true;
    internalInterfaces = [ "br0" ];
    externalInterface = "end0";
  };
  networking.firewall.trustedInterfaces = [ "br0" ];

  # Pairing agent + NAP registration (BlueZ drops the NAP when the registering
  # process exits, so bt-network stays in the foreground).
  systemd.services.bt-agent = {
    description = "Bluetooth auto-accept pairing agent";
    after = [ "bluetooth.service" ];
    requires = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bluez-tools}/bin/bt-agent -c NoInputNoOutput";
      Restart = "on-failure";
    };
  };

  systemd.services.bt-nap = {
    description = "Bluetooth NAP on br0";
    after = [ "bluetooth.service" "bt-agent.service" "sys-subsystem-bluetooth-devices-hci0.device" ];
    requires = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.bluez ];
    preStart = ''
      bluetoothctl power on
      bluetoothctl discoverable off
      bluetoothctl pairable off
    '';
    serviceConfig = {
      ExecStart = "${pkgs.bluez-tools}/bin/bt-network -s nap br0";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
