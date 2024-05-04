{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.meshtasticd;
  package = pkgs.meshtasticd;
in
{
  options = {
    services.meshtasticd = {
      enable = mkEnableOption (lib.mdDoc "start the meshtasticd emulated device");

      # gps = mkOption {
      #   type = types.str;
      #   example = "/dev/ttyS0";
      #   description = lib.mdDoc "The path to a GPS device's output.";
      # };

      port = mkOption {
        type = types.port;
        default = 4403;
        description = lib.mdDoc ''
          Port to bind the meshtastic API server to.
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Whether to open the default ports in the firewall for the meshtasticd API.
        '';
      };

      logLevel = mkOption {
        default = "info";
        example = "warn";
        type = enum [ "debug" "info" "warn" "error" ];
        description = lib.mdDoc ''
          The verbosity of logging.
        '';
      };

      webserver = {
        enable = mkEnableOption (lib.mdDoc "Enable meshtasticd to serve the meshtastic web interface");

        port = mkOption {
          type = types.port;
          default = 8080;
          description = lib.mdDoc ''
            Port to bind the web server to.
          '';
        };

        openFirewall = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc ''
            Whether to open a port in the firewall for the meshtasticd web server.
          '';
        };

      };

      extraConfig = mkOption {
        default = "";
        type = types.lines; # TODO
        description = lib.mdDoc ''
          Extra configuration options that will be added to the config.yaml file used by the meshtasticd service.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment = {
      etc."meshtasticd/config.yaml" = { source = pkgs.writeText "hqplayerd.xml" cfg.config; }; # TODO make this write out the yaml build from the config
      systemPackages = [ pkg ];
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ] + mkIf cfg.webserver.enable [ cfg.webserver.port ];
    };

    systemd.services.meshtasticd = {
      wantedBy = [ "multi-user.target" ];
      # TODO
    };

    # TODO may need to make user and groups if we need to actually interact with hardware
    # users.groups = {
    #   hqplayer.gid = config.ids.gids.hqplayer;
    # };

    # users.users = {
    #   hqplayer = {
    #     description = "hqplayer daemon user";
    #     extraGroups = [ "audio" "video" ];
    #     group = "hqplayer";
    #     uid = config.ids.uids.hqplayer;
    #   };
    # };
  };
}
