# NetworkManager owns roaming links (Wi-Fi, ethernet profiles);
# systemd-networkd owns fixed topology (VM bridge).
{ ... }:

{
  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
    # Interfaces owned by networkd, libvirt, docker and WireGuard
    unmanaged = [
      "interface-name:br-vm"
      "interface-name:yuuko"
      "interface-name:virbr*"
      "interface-name:vnet*"
      "interface-name:docker*"
      "interface-name:br-*"
      "interface-name:veth*"
    ];

    # Switch with: nmcli con up eth-lab
    ensureProfiles.profiles = {
      eth-dhcp = {
        connection = { id = "eth-dhcp"; type = "ethernet"; interface-name = "enp0s31f6"; autoconnect-priority = 0; };
        ipv4.method = "auto";
        ipv6.method = "auto";
      };
      eth-lab = {
        connection = { id = "eth-lab"; type = "ethernet"; interface-name = "enp0s31f6"; autoconnect = false; };
        ipv4 = { method = "manual"; address1 = "10.1.2.50/24,10.1.2.1"; dns = "10.1.2.1;"; };
        ipv6.method = "disabled";
      };
      eth-direct = {
        connection = { id = "eth-direct"; type = "ethernet"; interface-name = "enp0s31f6"; autoconnect = false; };
        ipv4 = { method = "manual"; address1 = "192.168.77.2/24"; };
        ipv6.method = "link-local";
      };
    };
  };

  services.resolved.enable = true;

  systemd.network.enable = true;
  networking.useNetworkd = true;

  systemd.network.wait-online.enable = false;
  systemd.services.NetworkManager-wait-online.enable = false;

  # NAT'd bridge for VMs; works over any uplink, Wi-Fi included
  systemd.network = {
    netdevs."20-br-vm".netdevConfig = { Kind = "bridge"; Name = "br-vm"; };
    networks."20-br-vm" = {
      matchConfig.Name = "br-vm";
      address = [ "192.168.150.1/24" ];
      networkConfig = {
        DHCPServer = true;
        IPv4Forwarding = true;
        IPMasquerade = "ipv4";
        ConfigureWithoutCarrier = true;
      };
      dhcpServerConfig = { PoolOffset = 20; PoolSize = 100; EmitDNS = true; DNS = "_server_address"; };
    };
  };

  virtualisation.libvirtd.allowedBridges = [ "virbr0" "br-vm" ];
  networking.firewall.trustedInterfaces = [ "br-vm" ];
}
