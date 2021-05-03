# monkeywidgets

A low effort attempt to build a hackish but functional [AwesomeWM](https://awesomewm.org/) widget system for linux systems the easy way. If you know what you're doing, you better don't use this and rather use [Lain](https://github.com/lcpz/lain), [Vicious](https://github.com/vicious-widgets/vicious) or build your own.
This system is made purely by my own preferences and might not work for you (without touching the code). The goal is to write the widget code as short as possible while keeping it somewhat readable.

![preview](preview.png)

**Available Widgets:**
- Battery
- Volume (pulse)
- Backlight
- WiFi

## Install

    git clone https://github.com/shagu/monkeywidgets .config/awesome/monkeywidgets

### Dependencies

Some modules require system tools to be installed in order to query and/or set specific values.

- battery: `acpi`
- volume: `pacmd`
- backlight: `backlightctl`
- wifi: `wireless_tools` (iwconfig)

## Usage

An example usage in rc.lua would look as following:

    local widgets = require("monkeywidgets")
    widgets.tick_size = 1

    [...]

    local monkeybattery = widgets.battery('BAT1')

    [...]

    s.mywibox:setup {
      layout = wibox.layout.align.horizontal,
      { -- left
        layout = wibox.layout.fixed.horizontal,
        s.mytaglist,
        s.mypromptbox,
      },
      { -- middle
        layout = wibox.layout.fixed.horizontal,
        s.mytasklist,
      },
      { -- right
        layout = wibox.layout.fixed.horizontal,
        monkeybattery.icon,
        monkeybattery,
        mytextclock,
      },
    }

## Internals
the internal core widget allows 6 arguments, where the last two are optional:

    widgets.create = function(icon, cmd, timer, callback, buttons, tooltip)

- icon: the icon shown up beside bar
- cmd: the command that runs periodically
- timer: the interval the function should run
- callback: the code that runs on each call
- buttons: an awesomeWM button table
- tooltip: a function that shall run on mouse-over

Some module default setting can be overwritten from within the rc.lua (See [Usage](Usage)):

    widgets.width = 14
    widgets.height = nil
    widgets.vertical = true
    widgets.ticks = true
    widgets.tick_size = 1

    widgets.background = '#222222'
    widgets.border     = '#444444'
    widgets.color      = '#33ffcc'

Those should be self explanatory. If not, change them and see the results.

## Credits

The widget icons are taken from Google's [Material Design Icons](https://github.com/google/material-design-icons.git) repository.