------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "DP-5",
    mode     = "1920x1080@165",
    position = "0x0",
    scale    = "1",
})

hl.monitor({
    output   = "HDMI-A-5",
    mode     = "1920x1080@60",
    position = "1920x0",
    scale    = "1",
})
