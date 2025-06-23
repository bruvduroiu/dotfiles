{
  programs.waybar = {
    enable = true;
    style = (builtins.readFile ./style.css);
    settings = [{
      layer = "top";
      position = "top";
      height = 24;
      spacing = 5;
      margin = "0";
      modules-left = ["clock" "temperature" "custom/weather" ];
      modules-center = ["hyprland/workspaces"];
      modules-right = ["pulseaudio" "battery" "network" "cpu" "memory" "disk" "custom/updates" "tray"];
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
      "custom/playerctl" = {
        format = " 󰐊 {}";
        return-type = "json";
        max-length = 40;
        exec = "playerctl -a metadata --format '{\"text\": \"{{artist}} - {{markup_escape(title)}}\", \"tooltip\": \"{{playerName}} : {{artist}} - {{markup_escape(title)}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F";
        on-click = "playerctl play-pause";
        on-click-right = "playerctl next";
      };

      "custom/weather" = {
        exec = "curl 'https://wttr.in/?format=1'";
        interval = 3600;
        format = "{}";
        tooltip = true;
      };

      "custom/quote" = {
        format = "󰚛 {}";
        interval = 3600;
        exec = "fortune -s";
        on-click = "fortune | yad --text-info --width=400 --height=200 --title='Fortune'";
        tooltip = true;
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
        format = "{:%I:%M:%S %p}";
        interval = 1;
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
        on-click = "ghostty -e htop";
      };

      memory = {
        format = "󰍛 {}%";
        interval = 1;
        on-click = "ghostty -e htop";
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
        on-click = "ghostty -e nmtui";
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
        on-click = "pavucontrol";
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
      };
    }];
  };
}
