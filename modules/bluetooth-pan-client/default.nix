# Bluetooth PAN client: join the Pi's NAP (ririka) as a PANU. The Pi runs the
# NAP/DHCP side (see ../bluetooth). NetworkManager owns the connection. Not autoconnected.
#   Start: nmcli con up bt-ririka
#   Stop:  nmcli con down bt-ririka
{ ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  networking.networkmanager.ensureProfiles.profiles.bt-ririka = {
    connection = { id = "bt-ririka"; type = "bluetooth"; autoconnect = false; };
    bluetooth = { bdaddr = "2C:CF:67:19:46:40"; type = "panu"; };
    ipv4.method = "auto";
    ipv6.method = "ignore";
  };
}
