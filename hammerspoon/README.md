# Jeo Keyboard Layout for Hammerspoon

This is an implementation of the [Jeo Keyboard Layout][JKL] for macOS Sierra
(and onwards) using [Hammerspoon](http://www.hammerspoon.org/).

![Layout diagram](https://user-images.githubusercontent.com/11491479/27187883-4a3be07a-51e4-11e7-82dd-ad47b31019ca.png)

## Installation

1.  Install Hammerspoon (`brew cask install hammerspoon`) and configure it to
    launch at login.

2.  Stop macOS listening to Caps Lock by opening System Preferences, choosing
    Keyboard and clicking the “Modifier Keys...” button. Change Caps Lock to
    “No Action” and click OK.

    _Do this for your internal _and_ external keyboard_.

3.  Install [Karabiner-Elements](https://github.com/tekezo/Karabiner-Elements)
    (`brew cask install karabiner-elements`) and add the following ‘simple
    modifications’:

    | From key    | To key                                |
    | ----------- | ------------------------------------- |
    | caps_lock   | quote key (')                         |
    | application | right_alt (equal to \`right_option\`) |
    | f14         | f16                                   |
    | f15         | f17                                   |

    Additionally, make the following changes in the Function Keys tab:

    | From key | To key |
    | -------- | ------ |
    | f5       | f5     |
    | f6       | f6     |

4.  Download and install Jeo:

    ```sh
     cd ~/.hammerspoon/
     git clone https://github.com/ecridge/jeospoon.git
    ```

5.  Add the following lines to your `~/.hammerspoon/init.lua`:

    ```lua
    jeo = require 'jeospoon'
    jeoEventTap = hs.eventtap.new(jeo.KEY_EVENTS, jeo.handleKeyEvent)
    jeoEventTap:start()
    ```

6.  Reload Hammerspoon.

## Configuration

You can set the editor and terminal to launch as follows:

```lua
jeo.setEditor('TextEdit')
jeo.setTerminal('Terminal')
```

(The values shown above are the defaults.)

## Pass-Through Mode

You can toggle pass-through mode (where this remapping is completely disabled)
by pressing ⌘⎋ (`Cmd-Esc`), or programmatically within hammerspoon:

```lua
jeo.enablePassThrough()  -- Keyboard is now standard QWERTY.
jeo.disablePassThrough() -- Keyboard is now Jeo remapped.
```

[JKL]: https://github.com/ecridge/jeo
