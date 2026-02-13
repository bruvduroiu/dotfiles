{ config, ... }:

let
  c = config.lib.stylix.colors.withHashtag;
  isDark = config.stylix.polarity == "dark";
  bgAlpha = if isDark then "0.6" else "0.85";
  hoverAlpha = if isDark then "0.9" else "0.95";
in {
  programs.waybar = {
    enable = true;
    style = ''
      @define-color foreground ${if isDark then c.base05 else c.base00};
      @define-color foreground-inactive ${if isDark then c.base04 else c.base03};
      @define-color background ${if isDark then c.base00 else c.base04};
      @define-color color9 ${c.base0E};

      * {
        font-family: JetBrainsMono Nerd Font;
        font-size: 17px;
        padding: 0;
        margin: 0;
      }

      window#waybar {
        all: unset;
        color: @foreground;
      }

      .modules-left,
      .modules-center,
      .modules-right {
        color: @foreground;
        background: alpha(@background, ${bgAlpha});
        margin: 5px 10px;
        padding: 0 5px;
        border-radius: 15px;
      }
      .modules-left {
        padding: 0 5px;
      }
      .modules-center {
        padding: 0 10px;
        margin: 5 0 5 0;
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #disk,
      #temperature,
      #backlight,
      #network,
      #pulseaudio,
      #wireplumber,
      #custom-media,
      #tray,
      #mode,
      #idle_inhibitor,
      #scratchpad,
      #power-profiles-daemon,
      #language,
      #mpd {
        padding: 0 10px;
        border-radius: 15px;
      }

      #clock:hover,
      #battery:hover,
      #cpu:hover,
      #memory:hover,
      #disk:hover,
      #temperature:hover,
      #backlight:hover,
      #network:hover,
      #pulseaudio:hover,
      #wireplumber:hover,
      #custom-media:hover,
      #tray:hover,
      #mode:hover,
      #idle_inhibitor:hover,
      #scratchpad:hover,
      #power-profiles-daemon:hover,
      #language:hover,
      #mpd:hover {
        background: alpha(@background, ${hoverAlpha});
      }

      #workspaces {
        padding: 0px 5px;
      }

      #workspaces button {
        all: unset;
        padding: 0px 5px;
        color: alpha(@color9, 0.4);
        transition: all 0.2s ease;
      }

      #workspaces button:hover {
        color: alpha(@color9, 0.7);
        border: none;
        text-shadow: 0px 0px 1.5px alpha(@color9, 0.5);
        transition: all 1s ease;
      }
      #workspaces button.active {
        color: @color9;
        border: none;
        text-shadow: 0px 0px 2px alpha(@color9, 0.5);
      }
      #workspaces button.empty {
        color: alpha(@foreground, 0.15);
        border: none;
        text-shadow: 0px 0px 1.5px alpha(@foreground, 0.1);
      }
      #workspaces button.empty:hover {
        color: alpha(@foreground, 0.3);
        border: none;
        text-shadow: 0px 0px 1.5px alpha(@foreground, 0.3);
        transition: all 1s ease;
      }
      #workspaces button.empty.active {
        color: @color9;
        border: none;
        text-shadow: 0px 0px 2px alpha(@color9, 0.5);
      }
    '';
    settings = [{
      layer = "top";
      position = "top";
      height = 24;
      spacing = 5;
      margin = "0";
      modules-left = ["clock" "custom/timew" "custom/playerctl"];
      modules-center = ["hyprland/workspaces"];
      modules-right = ["pulseaudio" "battery" "network" "group/hardware" "temperature" "tray" "privacy"];
      "hyprland/workspaces" = {
        format = "{icon}";
        format-icons = {
          "active" = "";
          "default" = "";
          "empty" = "";
        };
        on-click = "activate";
        icon-size = 10;
        sort-by-number= true;
        persistent-workspaces = {
          "1" = [];
          "2" = [];
          "3" = [];
          "4" = [];
          "5" = [];
        };
      };

      "hyprland/language" = {
        format = "{short}";
      };

      "hyprland/mode" = {
        format = "<span style=\"italic\">{}</span>";
      };

      "group/hardware" = {
        orientation = "inherit";
        modules = [
          "cpu"
          "memory"
          "disk"
        ];
        drawer = {
          transition-duration = 250;
        };
      };

      "custom/playerctl" = {
        format = " 󰐊 {}";
        return-type = "json";
        max-length = 40;
        exec = "playerctl -a metadata --format '{\"text\": \"{{artist}} - {{markup_escape(title)}}\", \"tooltip\": \"{{playerName}} : {{artist}} - {{markup_escape(title)}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F";
        on-click = "playerctl play-pause";
        on-click-right = "playerctl next";
      };

      "custom/weather" = {
        exec = "curl 'https://wttr.in/?format=%C+%t+Hum:+%h+%w'";
        on-click = "xdg-open 'https://wttr.in/'";
        interval = 900;
        format = "{}";
        tooltip = true;
      };

      "custom/timew" = {
        format = "󰔟 {}";
        exec = "timew get dom.active.json | jq -r '.tags | join(\" \")'";
        exec-if = "timew get dom.active";
        interval = 10;
      };

      "custom/updates" = {
        format = "󰚰 {}";
        exec = "checkupdates | wc -l";
        interval = 3600;
        on-click = "ghostty -e sudo pacman -Syu";
        signal = 8;
      };

      "custom/uptime" = {
        format = "󰔟 {}";
        exec = "uptime -p | sed 's/up //; s/ days/d/; s/ hours/h/; s/ minutes/m/'";
        interval = 60;
      };

      "idle_inhibitor" = {
        format = "{icon}";
        "format-icons" = {
          activated = "󰈈";
          deactivated = "󰈉";
        };
        tooltip = true;
      };

      clock = {
        format = "{:%H:%M}";
        interval = 15;
        format-alt = "󰃮 {:%Y-%m-%d}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        calendar = {
          mode = "month";
          mode-mon-col = 3;
          weeks-pos = "right";
          on-scroll = 1;
          on-click-right = "mode";
          format = {
            months = "<span color='#d3c6aa'><b>{}</b></span>";
            days = "<span color='#e67e80'>{}</span>";
            weeks = "<span color='#a7c080'><b>W{}</b></span>";
            weekdays = "<span color='#7fbbb3'><b>{}</b></span>";
            today = "<span color='#dbbc7f'><b><u>{}</u></b></span>";
          };
        };
        actions = {
          on-click-right = "mode";
          on-click-forward = "tz_up";
          on-click-backward = "tz_down";
          on-scroll-up = "shift_up";
          on-scroll-down = "shift_down";
        };
      };

      cpu = {
        format = "󰘚 {usage}%";
        tooltip = true;
        interval = 1;
        on-click = "ghostty -e btop";
      };

      memory = {
        format = "󰍛 {used:0.1f}G/{total:0.1f}G";
        interval = 1;
        on-click = "ghostty -e btop";
      };

      temperature = {
        critical-threshold = 80;
        format = "{icon} {temperatureC}°C";
        format-icons = ["󱃃" "󰔏" "󱃂"];
        on-click = "ghostty -e s-tui";
      };

      battery = {
        states = {
          good = 95;
          warning = 30;
          critical = 1;
        };
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-plugged = "󰚥 {capacity}%";
        format-alt = "{icon} {time}";
        format-icons = ["󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
      };

      network = {
        format-wifi = "󰖩 {essid} ({signalStrength}%)";
        format-ethernet = "󰈀 {ifname}";
        format-linked = "󰈀 {ifname} (No IP)";
        format-disconnected = "󰖪 Disconnected";
        format-alt = "{ifname}: {ipaddr}/{cidr}";
        tooltip-format = "{ifname}: {ipaddr}";
        on-click = "ghostty -e sudo nmtui";
      };

      bluetooth = {
        format = "\udb80\udcaf";
        format-disabled = "\udb80\udcb2";
        format-connected = "\udb80\udcb1";
        tooltip-format = "{controller_alias}\t{controller_address}";
        tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-bluetooth = "󰂰 {volume}%";
        format-bluetooth-muted = "󰂲 {icon}";
        format-muted = "󰝟";
        format-icons = {
          headphone = "󰋋";
          hands-free = "󰥰";
          headset = "󰋎";
          phone = "󰏲";
          portable = "󰄝";
          car = "󰄋";
          default = ["󰕿" "󰖀" "󰕾"];
        };
        on-click = "pwvucontrol";
        on-click-right = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
        on-scroll-up = "pactl set-sink-volume @DEFAULT_SINK@ +2%";
        on-scroll-down = "pactl set-sink-volume @DEFAULT_SINK@ -2%";
      };

      backlight = {
        format = "{icon} {percent}%";
        format-icons = ["󰃞" "󰃟" "󰃠"];
        on-scroll-up = "brightnessctl set +5%";
        on-scroll-down = "brightnessctl set 5%-";
      };

      disk = {
        interval = 30;
        format = "󰋊 {percentage_used}%";
        path = "/";
        on-click = "ghostty -e gdu /";
      };

      tray = {
        icon-size = 16;
        spacing = 16;
        show-passive-items = false;
      };

      privacy = {
        icon-spacing = 4;
        icon-size = 16;
        modules = [
          {
            type = "screenshare";
            tooltip = true;
            tooltip-icon-size = 24;
          }
          {
            type = "audio-in";
            tooltip = true;
            tooltip-icon-size = 24;
          }
        ];
      };
    }];
  };
}
