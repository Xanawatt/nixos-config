{ config, lib, pkgs, modulesPath, ... }:
{
    imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

    boot.initrd.availableKernelModules = [ "usbhid" "usb_storage" ];

    fileSystems."/" = {
        device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
        fsType = "ext4";
    };

    fileSystems."/boot/firmware" = {
        device = "/dev/disk/by-uuid/2175-794E";
        fsType = "vfat";
        options = [ "nofail" ];
    };

    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}