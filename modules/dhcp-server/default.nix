# DHCP server on the ethernet NIC, handing out 192.168.5.0/24.
# NetworkManager owns this NIC, so the server is a "shared" profile (NM runs
# dnsmasq for DHCP/DNS and NATs out the uplink). Not autoconnected.
#   Start: nmcli con up eth-dhcp-server
#   Stop:  nmcli con up eth-dhcp
{ ... }:

{
  networking.networkmanager.ensureProfiles.profiles.eth-dhcp-server = {
    connection = { id = "eth-dhcp-server"; type = "ethernet"; interface-name = "enp0s31f6"; autoconnect = false; };
    ipv4 = { method = "shared"; address1 = "192.168.5.1/24"; };
    ipv6.method = "ignore";
  };
}
