{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.podman;
in
{
  options.services.podman = {
    autoUpdate = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Automatically update the podman images.";
      };

      onCalendar = lib.mkOption {
        type = lib.types.str;
        default = "Sun *-*-* 00:00";
        description = ''
          The systemd `OnCalendar` expression for the update. See
          {manpage}`systemd.time(7)` for a description of the format.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf cfg.autoUpdate.enable {
        systemd.user.services."podman-auto-update" = {
          Unit = {
            Description = "Podman auto-update service";
            Documentation = "man:podman-auto-update(1)";
            Wants = [ "network-online.target" ];
            After = [ "network-online.target" ];
          };

          Service = {
            Type = "oneshot";
            Environment = "PATH=${
              builtins.concatStringsSep ":" [
                "/run/wrappers/bin"
                "/run/current-system/sw/bin"
                "${config.home.homeDirectory}/.nix-profile/bin"
              ]
            }";
            ExecStart = "${cfg.package}/bin/podman auto-update";
            ExecStartPost = "${cfg.package}/bin/podman image prune -f";
            TimeoutStartSec = "300s";
            TimeoutStopSec = "10s";
          };
        };

        systemd.user.timers."podman-auto-update" = {
          Unit = {
            Description = "Podman auto-update timer";
          };

          Timer = {
            OnCalendar = cfg.autoUpdate.onCalendar;
            RandomizedDelaySec = 300;
            Persistent = true;
          };

          Install = {
            WantedBy = [ "timers.target" ];
          };
        };
      })
      {
        xdg.configFile."systemd/user/podman-user-wait-network-online.service.d/50-exec-search-path.conf".text =
          ''
            [Service]
            ExecSearchPath=${
              lib.makeBinPath (
                with pkgs;
                [
                  bashInteractive
                  systemd
                  coreutils
                ]
              )
            }:/bin
          '';
      }
    ]
  );
}
