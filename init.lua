-- monkeywidgets
--  a low effort attempt, to build a hackish but functional AwesomeWM widget-system the easy way.
local widgets = {}
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local assets = os.getenv("HOME") .. "/.config/awesome/monkeywidgets/icons/"

do -- Configuration
  widgets.width = 10
  widgets.height = nil
  widgets.vertical = true
  widgets.ticks = true
  widgets.tick_size = 1

  widgets.background = '#222222'
  widgets.border     = '#444444'
  widgets.color      = '#33ffcc'
end

do -- Core Widget Library
  widgets.create = function(icon, cmd, timer, callback, buttons, tooltip)
    local img = wibox.widget.imagebox(assets .. icon)
    local icon = wibox.container.margin(img, 4, 4, 6, 6)

    local bar = wibox.widget {
      color            = widgets.color,
      background_color = widgets.background,
      margins          = 1,
      paddings         = 1,
      ticks            = widgets.ticks,
      ticks_size       = widgets.tick_size,
      widget           = wibox.widget.progressbar,
    }

    local rotate = wibox.widget {
      bar,
      forced_width  = widgets.width,
      forced_height = widgets.height,
      direction     = widgets.vertical and 'east' or nil,
      layout        = wibox.container.rotate,
    }

    local bg = wibox.container.background(rotate, widgets.border, gears.shape.rectangle)
    local widget = wibox.container.margin(bg, 0, 4, 4, 4)

    widget.refresh = function()
      awful.spawn.easy_async(cmd, function(stdout)
        callback(widget, stdout)
      end)
    end

    widget.icon = icon
    widget.img = img
    widget.bar = bar
    widget.bg = bg

    local tooltip = tooltip

    awful.widget.watch(cmd, timer, callback, widget)
    awful.tooltip {objects = { widget, widget.icon }, timer_function = tooltip}

    widget:buttons(buttons)
    widget.icon:buttons(buttons)

    return widget
  end
end

do -- Battery Widget
  widgets.battery = function(bat)
    local widget
    local command = 'cat /sys/class/power_supply/'..bat..'/energy_now'

    local worker = function(widget, stdout)
      awful.spawn.easy_async_with_shell('acpi', function(out)
        local _, _, val = string.find(out, '(.+)\n')
        widget.state = val:gsub("%%, ", "%%\n")
      end)

      awful.spawn.easy_async_with_shell('cat /sys/class/power_supply/'..bat..'/status', function(out)
        local _, _, val = string.find(out, '(.+)\n')
        widget.charging = val == 'Charging' and true or nil
      end)

      if not widget.maxcharge then
        awful.spawn.easy_async_with_shell('cat /sys/class/power_supply/'..bat..'/energy_full', function(out)
          widget.maxcharge = out
          widget.refresh()
        end)
      end

      if tonumber(widget.maxcharge) and tonumber(stdout) then
        local value = stdout / widget.maxcharge

        if widget.charging then
          widget.img:set_image(assets..'bat-ac.png')
        elseif value < .1 then
          widget.img:set_image(assets..'bat-0.png')
        elseif value < .2 then
          widget.img:set_image(assets..'bat-20.png')
        elseif value < .3 then
          widget.img:set_image(assets..'bat-30.png')
        elseif value < .5 then
          widget.img:set_image(assets..'bat-50.png')
        elseif value < .6 then
          widget.img:set_image(assets..'bat-60.png')
        elseif value < .8 then
          widget.img:set_image(assets..'bat-80.png')
        elseif value < .9 then
          widget.img:set_image(assets..'bat-90.png')
        elseif value then
          widget.img:set_image(assets..'bat-100.png')
        end

        widget.bar.value = value
      end
    end

    local buttons = {}

    local tooltip = function(a)
      return widget.state
    end

    widget = widgets.create('bat-0.png', command, 1, worker, buttons, tooltip)

    return widget
  end
end

do -- Backlight Widget
  widgets.backlight = function(bl)
    local widget
    local command = 'cat /sys/class/backlight/'..bl..'/brightness'

    local worker = function(widget, stdout)
      -- we don't have the max-brightness obtained yet
      if not widget.maxbrightness then
        awful.spawn.easy_async_with_shell('cat /sys/class/backlight/'..bl..'/max_brightness', function(out)
          widget.maxbrightness = out
          widget.refresh()
        end)
      end

      -- invalid values
      if not tonumber(widget.maxbrightness) or not tonumber(stdout) then
        return
      end

      -- set bar value
      widget.state = stdout / widget.maxbrightness
      widget.bar.value = widget.state
    end

    local buttons = awful.util.table.join(
      awful.button({ }, 4, function (s)
        awful.spawn.easy_async("brightnessctl s +10")
        widget.refresh()
      end),

      awful.button({ }, 5, function (s)
        awful.spawn.easy_async("brightnessctl s 10-")
        widget.refresh()
      end)
    )

    local tooltip = function()
      return "Brightness: <b>" .. math.floor(widget.state * 100 + .5) .. '%</b>'
    end

    widget = widgets.create('backlight.png', command, 10, worker, buttons, tooltip)

    return widget
  end
end

do -- Wifi Widget
  widgets.wifi = function(iface)
      local widget
      local command = 'bash -c "iwconfig '.. (iface or "") ..'"'

      local worker = function(widget, stdout)
        local _, _, current, max = string.find(stdout, "Link Quality=(.+)/(.-) .+")
        local _, _, essid = string.find(stdout, "ESSID:\"(.+)\".+")
        local _, _, freq = string.find(stdout, "Frequency:(.+)GHz.+")

        if tonumber(current) and tonumber(max) then
          local value = current / max * 100

          if value < .2 then
            widget.img:set_image(assets..'wifi-0.png')
          elseif value < .4 then
            widget.img:set_image(assets..'wifi-1.png')
          elseif value < .6 then
            widget.img:set_image(assets..'wifi-2.png')
          elseif value < .8 then
            widget.img:set_image(assets..'wifi-3.png')
          elseif value then
            widget.img:set_image(assets..'wifi-4.png')
          end

          freq = freq or "N/A"
          essid = essid or "N/A"

          widget.state = 'WiFi: <b>'..essid ..'</b> ('..freq..'GHz)\nQuality: '.. current..'/'.. max..' ('..math.floor(current / max * 100 + .5)..'%)'
          widget.bar.value = value
        else
          widget.img:set_image(assets..'wifi-off.png')
        end
      end

      local buttons = awful.util.table.join(
        awful.button({ }, 1, function (s)
          awful.util.spawn(terminal .. " -e nmtui")
        end)
      )

      local tooltip = function()
        return widget.state
      end

      widget = widgets.create('wifi-2.png', command, 1, worker, buttons, tooltip)

    return widget
  end
end

do -- Volume Widget (PulseAudio)
  widgets.volume = function()
    local widget
    local command = 'pamixer --get-volume'

    local worker = function(widget, stdout)
      local _, _, vol = string.find(stdout, '(.+)\n')

      awful.spawn.easy_async_with_shell('pamixer --get-mute', function(out)
        local _, _, mute = string.find(out, '(.+)\n')
        widget.mute = mute ~= "false" and "Muted"

        if widget and widget.mute then
          widget.img:set_image(assets..'vol-mute.png')
        elseif vol and tonumber(vol) then
          if tonumber(vol) < 30 then
            widget.img:set_image(assets..'vol-0.png')
          elseif tonumber(vol) < 60 then
            widget.img:set_image(assets..'vol-1.png')
          else
            widget.img:set_image(assets..'vol-2.png')
          end
        end
      end)

      widget.state = vol
      widget.bar.value = vol / 100
    end

    local buttons = awful.util.table.join(
      awful.button({ }, 1, function (s)
        awful.spawn.easy_async("pamixer -t", widget.refresh)
      end),

      awful.button({ }, 4, function (s)
        awful.spawn.easy_async("pamixer -i 2", widget.refresh)
      end),

      awful.button({ }, 5, function (s)
        awful.spawn.easy_async("pamixer -d 2", widget.refresh)
      end)
    )

    local tooltip = function()
      return 'Volume: <b>' .. widget.state .. '%</b>' .. ( widget.mute and ' ('..widget.mute..')' or '')
    end

    widget = widgets.create('vol-1.png', command, 1, worker, buttons, tooltip)

    return widget
  end
end

return widgets