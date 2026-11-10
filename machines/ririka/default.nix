{ nixos-raspberrypi, lib, pkgs, inputs, ...}:
let
  # CHANGE ME: your public key(s)
  sshKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC3qOHnWDGlLvECZ8r3vryHyStqyX+AxgjPioyPno1WpXx6tuaA2dPj47nKQelDzufoE+EdDVPmbEg2yzgwf2h7BeIK3jcHltG9ZWU9+KbcBcorhZm5gIe4mqc4it+p3xgt1LaTkR9M+wT+cfwu8TW15K1FIxSg0CUFrWXrEvoGBVHcnaBX2/dBUnOCe6ZKlunJkEYUJ9SXd8iBA8zzsZsBAVmYaIY+yHdGkd2j8u6DdjDWw5u8psni35bXeAVWOek15jCLOFN2lTLmzRcyKCIT4ngUHb6NYNByx3/xoMblbPyWN8oT9HYqiLEQfQSJdr6rhKlUdB/V+KOyC10IUrBj1Qle0WfcjtYkBpQfSNDCXCiVD+cLI06FGs8KIxx/AIkSrLxLhONfgBtvau2h1wtgzIk9k2zncsQovvVJjYnlhCaAYGyRsPnIbS4IEo+oCimvaCeunCNB+I6xWYqFj17SA9ksXwOwA0bpemhM327ZmP/syYfHWupIQbBLrPjHcp8= xanawatt@mark-dt-l"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICkxJe1KXlvJh25K+xoVSHfrQ8A7F0hNWzVBv5sRsb6U schne112@mark-ltw-l"
  ];
in
{
    imports = with nixos-raspberrypi.nixosModules; [
        raspberry-pi-5.base
    ] ++ [
        ./hardware-configuration.nix
        ../../modules/bluetooth-nap
    ];

    # Same boot method the installer image uses.
    boot.loader.raspberry-pi.bootloader = "kernel";

    networking.hostName = "ririka";
    time.timeZone = "America/Indiana/Indianapolis";

    zramSwap.enable = true;

    # ------------------------------------------------------------- networking
    # DHCP on every Ethernet and Wi-Fi interface. Fine for now; the fieldkit
    # config later narrows this to the management ports only.
    networking.useNetworkd = true;
    networking.useDHCP = true;
    services.resolved.enable = true;
    systemd.network.wait-online.enable = false;

    # Wi-Fi: iwctl station wlan0 connect <ssid>
    networking.wireless.iwd.enable = true;

    # Reach it as fieldpi.local
    services.avahi = {
        enable = true;
        nssmdns4 = true;
        publish = { enable = true; addresses = true; };
    };

    networking.firewall.enable = true;

    # ----------------------------------------------------------------- access
    services.openssh = {
        enable = true;
        settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password"; # for deploys
        };
    };

    users.users.xanawatt = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = sshKeys;
    };
    users.users.root.openssh.authorizedKeys.keys = sshKeys;
    security.sudo.wheelNeedsPassword = false;

    # -------------------------------------------------------------------- nix
    nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
        trusted-users = [ "root" "@wheel" ];
        extra-substituters = [ "https://nixos-raspberrypi.cachix.org" ];
        extra-trusted-public-keys = [
            "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
        ];
    };
    nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
    };

    environment.systemPackages = with pkgs; [
        vim git tmux htop curl dig
        tcpdump ethtool iw iperf3 mtr
    ];

    # CHANGE ME: the first two numbers of `nixos-version` on the installer.
    # Set once, never bump it afterwards.
    system.stateVersion = "26.05";
}
