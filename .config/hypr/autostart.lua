-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function () 
   hl.exec_cmd("nm-applet")
   hl.exec_cmd("hyprpaper")
   hl.exec_cmd("blueman-applet")
   hl.exec_cmd("quickshell -c Bar")
   hl.exec_cmd("awww-daemon")
   hl.exec_cmd("awww img /home/patoll/Downloads/germoney/black.jpg")
   hl.exec_cmd("hypridle")
end)