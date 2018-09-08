# Installing Jeo on Linux

You need to decide which [variant][] of Jeo best describes your keyboard.  This
usually depends on whether your return (enter) key is L-shaped, and whether or
not your keyboard is part of a MacBook.

|                | L-shaped return key | Horizontal return key |
| -------------- | ------------------- | --------------------- |
| MacBook        | `iso-notebook`      | `ansi-notebook`       |
| Something else | `iso-desktop`       | `ansi-desktop`        |

There are also some more exotic (and experimental) variants available:

* `kinesis-advantage`

Once you’ve decided, compile the layout like so:

```bash
xkbcomp -I. 'keymaps/jeo(chosen-variant)'
```

This will spit out a file called `chosen-variant.xkm`, which you can put
somewhere safe, and load into your display whenever you want to type in Jeo:

```bash
xkbcomp chosen-variant.xkm $DISPLAY
```

You may wish to apply Jeo to one keyboard only.  To do so, find the ID of the
device using `xinput -list`, and then pass it on to `xkbcomp` using the `-i`
flag:

```bash
xkbcomp -i 42 chosen-variant.xkm $DISPLAY
```

> `xkbcomp` currently has a very bizarre [bug][] where if you specify a device
> with the `-i` flag, your changes to _that device_ won’t take effect
> immediately: XKB waits for a key press from _any other device_ first.

To return to your original layout, just use `setxkbmap`:

```bash
setxkbmap gb  # You can add e.g. `-device 42` here to act only on one device.
```

[bug]: https://gitlab.freedesktop.org/xorg/app/xkbcomp/issues/9
[variant]: https://jeolayout.org/#variants
