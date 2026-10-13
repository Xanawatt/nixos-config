# virtualisation.nix
# QEMU/KVM + libvirt + virt-manager, configured for Windows 11 guests
# (UEFI/OVMF with Secure Boot, software TPM 2.0, SPICE USB redirection).
#
# Usage in configuration.nix:
#   imports = [ ./virtualisation.nix ];
#   my.virtualisation = {
#     enable = true;
#     users = [ "yourname" ];
#   };
{ config, lib, pkgs, ... }:

let
  cfg = config.my.virtualisation;
in
{
  options.my.virtualisation = {
    enable = lib.mkEnableOption "QEMU/KVM with libvirt and virt-manager";

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "alice" ];
      description = "Users allowed to manage VMs (added to the libvirtd and kvm groups).";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      onBoot = "ignore";          # don't auto-start guests at boot
      onShutdown = "shutdown";    # cleanly shut guests down with the host
      qemu = {
        package = pkgs.qemu_kvm;  # host-arch only, smaller than full qemu
        runAsRoot = false;
        swtpm.enable = true;      # TPM 2.0 emulation (required by Windows 11)
        vhostUserPackages = [ pkgs.virtiofsd ];  # virtiofs shared folders
        # OVMF (UEFI, incl. Secure Boot variants) ships with QEMU and is
        # available to libvirt by default on NixOS 25.11+.
        # On 25.05 or older, uncomment:
        # ovmf = {
        #   enable = true;
        #   packages = [ pkgs.OVMFFull.fd ];
        # };
      };
    };

    # virt-manager GUI (also sets up the dconf bits it needs)
    programs.virt-manager.enable = true;

    # Pass host USB devices into the guest through SPICE
    virtualisation.spiceUSBRedirection.enable = true;

    # Let VMs on the default NAT network get DHCP/DNS through the firewall
    networking.firewall.trustedInterfaces = [ "virbr0" ];

    # Start libvirt's "default" NAT network automatically
    systemd.services.libvirt-default-network = {
      description = "Autostart libvirt default network";
      after = [ "libvirtd.service" ];
      requires = [ "libvirtd.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.libvirt}/bin/virsh net-info default >/dev/null 2>&1 || exit 0
        ${pkgs.libvirt}/bin/virsh net-autostart default
        ${pkgs.libvirt}/bin/virsh net-start default 2>/dev/null || true
      '';
    };

    users.users = lib.genAttrs cfg.users (_: {
      extraGroups = [ "libvirtd" "kvm" ];
    });

    environment.systemPackages = with pkgs; [
      virt-viewer     # remote-viewer for SPICE consoles
      spice-gtk
      swtpm
      virtio-win      # VirtIO drivers for the Windows guest
    ];
  };
}
