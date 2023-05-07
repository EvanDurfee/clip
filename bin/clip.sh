#!/bin/sh

print_help () {
    echo TODO
}

getopt -T >/dev/null
if [ $? -eq 4 ]; then
  # GNU enhanced getopt is available
  ARGS=$(getopt --name "$PROG" --long help,in,out,primary,clipboard --options hiopc -- "$@")
else
  # Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=$(getopt hiopc "$@")
fi
eval set -- $ARGS

default_read_from_stdin=true
default_write_to_stdout=false
if [ -t 0 ]; then
    default_read_from_stdin=false
    default_write_to_stdout=true
fi

read_from_stdin=false
write_to_stdout=false
use_primary=false
use_clipboard=false
while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
            print_help
            exit 0
            ;;
        -i | --in)
            read_from_stdin=true
            ;;
        -o | --out)
            write_to_stdout=true
            ;;
        -p | --primary)
            use_primary=true
            ;;
        -c | --clipboard)
            use_clipboard=true
            ;;
        --)
            shift
            break
            ;;
    esac
    shift
done

if ! $read_from_stdin && ! $write_to_stdout; then
    read_from_stdin=$default_read_from_stdin
    write_to_stdout=$default_write_to_stdout
fi

if ! $use_primary && ! $use_clipboard; then
    use_clipboard=true
fi

paste () {
    # Currently linux and BSD only; no darwin, wsl, etc.
    if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        if $use_primary; then wl-paste --primary --no-newline; fi
        if $use_clipboard; then wl-paste --no-newline; fi
    elif [ "$XDG_SESSION_TYPE" = "x11" ]; then
        if hash xsel 2>/dev/null; then
            if $use_primary; then xsel --output --primary; fi
            if $use_clipboard; then xsel --output --clipboard; fi
        elif hash xclip 2>/dev/null; then
            if $use_primary; then xclip -out -selection primary; fi
            if $use_clipboard; then xclip -out -selection clipboard; fi
        else
            printf 'Must have either xclip or xsel installed' >&2
            exit 2
        fi
    else
        # tty or unrecognized session, fall back to osc52
        printf 'Unable to paste without an x11 or wayland session\n' >&2
        exit 3
        # I'm as of yet unable to make these work; the osc52 command is only processed when
        #  printed visibly to the terminal emulator; I cannot redirect or capture it
        # It's more of a security risk anyhow
        # if $use_primary; then printf "\033]52;p;?\a" | cut -c6- | base64 -d; fi
        # if $use_clipboard; then printf "\033]52;c;?\a" | cut -c6- | base64 -d; fi
    fi
}

copy () {
    # Currently linux and BSD only; no darwin, wsl, etc.
    if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        if $use_primary && $use_clipboard; then
            buff=$(base64 -)
            printf "%s" "$buff" | base64 -d | wl-copy --primary
            printf "%s" "$buff" | base64 -d | wl-copy
        elif $use_primary; then
            wl-copy --primary
        elif $use_clipboard; then
            wl-copy
        fi
    elif [ "$XDG_SESSION_TYPE" = "x11" ]; then
        if hash xsel 2>/dev/null; then
            if $use_primary && $use_clipboard; then
                buff=$(base64 -)
                printf "%s" "$buff" | base64 -d | xsel --input --primary
                printf "%s" "$buff" | base64 -d | xsel --input --clipboard
            elif $use_primary; then
                xsel --input --primary
            elif $use_clipboard; then
                xsel --input --clipboard
            fi
        elif hash xclip 2>/dev/null; then
            # xclip doesn't close stdout properly; workaround by writing to /dev/null
            if $use_primary && $use_clipboard; then
                buff=$(base64 -)
                printf "%s" "$buff" | base64 -d | xclip -in -selection primary >/dev/null
                printf "%s" "$buff" | base64 -d | xclip -in -selection clipboard >/dev/null
            elif $use_primary; then
                xclip -in -selection primary >/dev/null
            elif $use_clipboard; then
                xclip -in -selection clipboard >/dev/null
            fi
        else
            printf 'Must have either xclip or xsel installed' >&2
            exit 2
        fi
    else
        # tty or unrecognized session, fall back to osc52
        if $use_primary && $use_clipboard; then
            buff=$(base64 -)
            printf "%s" "$buff" | xargs printf "\033]52;p;%s\a"
            printf "%s" "$buff" | xargs printf "\033]52;c;%s\a"
        elif $use_primary; then
            base64 | xargs printf "\033]52;p;%s\a"
        elif $use_clipboard; then
            base64 | xargs printf "\033]52;c;%s\a"
        fi
    fi
}

if $read_from_stdin; then
    copy
fi

if $write_to_stdout; then
    paste
fi
