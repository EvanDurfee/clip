# Clip

Command line utility for copying text to the system clipboard. Supports linux
(and hopefully BSD) systems running X11 sessions (via `xclip` or `xsel`) as
well as Wayland sessions (via `wl-clipboard`'s `wl-copy` and `wl-paste`).
For tty sessions, copy (but not paste) is implemented via an osc52 code for
terminals that support them (e.g. kitty).

## Usage

Copy to main clipboard

```shell
$> echo hello there | clip
```

Paste

```shell
$> clip
hello there
```

Copy to primary selection (e.g. middle mouse button for terminal emulators)

```shell
$> echo Primary selection | clip --primary
```

Paste primary

```shell
$> clip --primary
Primary selection
```

Copy and paste

```shell
$> echo Howdy | clip --in --out
Howdy
```

Copy to both primary and clipboard selections

```shell
$> echo Both clipboards | clip --primary --clipboard
```
