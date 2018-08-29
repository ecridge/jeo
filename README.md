# The Jeo Keyboard Layout

Jeo is a keyboard layout which is optimised for software development.
[Learn more](https://jeolayout.org/)

![The Jeo Keyboard Layout](docs/images/iso-desktop.png)

## macOS install

At the moment, the best way to use Jeo on macOS is via [Hammerspoon][].  This
is pretty straightforward to set up – go check out the [jeospoon][] repo.

The only caveat is that Hammerspoon has no effect during ‘secure text entry’,
which means that you’ll have to make do with QWERTY when typing in passwords.
Note that Terminal.app has a setting where you can force _everything_ you type
to be sent via secure entry; I suggest you turn that off if you want to use Jeo
at the shell…

[Hammerspoon]: https://www.hammerspoon.org/
[jeospoon]: https://github.com/joecridge/jeospoon

## Linux install

Installing on Linux comes in two parts: modifying your system’s XKB
configuration files to include the layout, and then actually enabling it.

### The tedious part

You’ll need to locate your system’s XKB configuration directory.  This is
probably somewhere like `/usr/share/X11/xkb`, but we’ll call it `XKB_HOME`.

Append the contents of `xkb/symbols/gb` to `"$XKB_HOME/symbols/gb"`, and
likewise for `xkb/symbols/us` into `"$XKB_HOME/symbols/us"`.

Copy `xkb/compat/jeo` into `"$XKB_HOME/compat"` and then register the `jeo`
compatibility component with `"$XKB_HOME/compat/complete"`:

```text
default xkb_compatibility "complete" {
    include "basic"
    ...
    augment "jeo"
};
```

Identify the `gb` layout in `"$XKB_HOME/rules/base.xml"`.  It will look like
this:

```xml
<layout>
  <configItem>
    <name>gb</name>
    ...
  </configItem>
  <variantList>
    ...
  </variantList>
<layout>
```

Add these items into the `<variantList>`:

```xml
<variant>
  <configItem>
    <name>jeo</name>
    <description>English (Jeo)</description>
  </configItem>
</variant>
<variant>
  <configItem>
    <name>jeo-mac</name>
    <description>English (Jeo, Macintosh)</description>
  </configItem>
</variant>
<variant>
  <configItem>
    <name>jeo-kinesis</name>
    <description>English (Jeo, Kinesis Advantage)</description>
  </configItem>
</variant>
```

And add these items into the `us` variant list:

```xml
<variant>
  <configItem>
    <name>jeo</name>
    <description>English (US, Jeo)</description>
  </configItem>
</variant>
<variant>
  <configItem>
    <name>jeo-mac</name>
    <description>English (US, Jeo, Macintosh)</description>
  </configItem>
</variant>
```

Repeat the last two steps for `"$XKB_HOME/rules/evdev.xml"`.

Lastly, insert these lines into the `! variant` sections of both
`"$XKB_HOME/rules/base.lst"` and `"$XKB_HOME/rules/evdev.lst"`:

```text
  jeo             gb: English (Jeo)
  jeo-mac         gb: English (Jeo, Macintosh)
  jeo-kinesis     gb: English (Jeo, Kinesis Advantage)
  jeo             us: English (US, Jeo)
  jeo-mac         us: English (US, Jeo, Macintosh)
```

Now restart `keyboard-setup` to register the changes:

```bash
systemctl restart keyboard-setup
```

### The fun part

You need to decide which _layout_ (ANSI or ISO) and _variant_ (desktop or
notebook) best describes your keyboard.  Generally it goes something like this:

* Is your return key L-shaped?  If yes, you want the ISO layout; otherwise, you
  want the ANSI layout.

* Are you typing on some sort of MacBook?  If yes, you want the notebook
  layout; otherwise, you want the desktop layout.

(There are some [rendered layouts][variants] on the website if you want to know
exactly what you’re letting yourself in for…)

Now that that’s decided, you can switch on the appropriate layout either via
GNOME settings (see comments) or via the command line:

```bash
# ANSI desktop
# Choose 'English (United States)', then 'English (US, Jeo)', or:
setxkbmap us jeo

# ANSI notebook
# Choose 'English (United States'), then 'English (US, Jeo, Macintosh)', or:
setxkbmap us jeo-mac

# ISO desktop
# Choose 'English (United Kingdom)', then 'English (Jeo)', or:
setxkbmap gb jeo

# ISO notebook
# Choose 'English (United Kingdom)', then 'English (Jeo, Macintosh)', or:
setxkbmap gb jeo-mac
```

There is also some (experimental) support for more exotic devices:

```bash
# Kinesis Advantage
# Choose 'English (United Kingdom)', then 'English (Jeo, Kinesis Advantage)', or:
setxkbmap gb jeo-kinesis
```

You may wish to set Jeo as the layout on just one particular device.  You can
achieve this by getting the device ID from `xinput -list` and then passing it
to `setxkbmap` via the `-device` argument.

[variants]: https://jeolayout.org/#variants
