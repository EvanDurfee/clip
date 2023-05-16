#!/bin/bash

print_help () {
    cat <<EOF
Usage: $0 [--system] {install|uninstall}

Install or uninstall clip, along with shell completions.

options:
  -h, --help        print usage information and exit

positional arguments:
  install           install clip
  uninstall         uninstall clip

Note: long options are only supported in the case of GNU's enhanced getopt
EOF
}

getopt -T >/dev/null
if [ $? -eq 4 ]; then
    # GNU enhanced getopt is available
    ARGS=$(getopt --name "$PROG" --long help,system --options hs -- "$@")
else
    # Original getopt is available (no long option names, no whitespace, no sorting)
    ARGS=$(getopt hs "$@")
fi
eval set -- "$ARGS"

while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
            print_help
            exit 0
            ;;
        --)
            shift
            break
            ;;
    esac
    shift
done

if [ $# -ne 1 ]; then
    printf "%s requires exactly one positional arg (install or uninstall)\n" "$0" >&2
    exit 1
fi

source_dir="$(readlink -f "${BASH_SOURCE[0]}")" && source_dir="$(dirname "$source_dir")"
if [ $? -ne 0 ]; then
    printf "Unable to determine source dir; is readlink available?\n" >&2
    exit 2
fi
target_bin="$HOME/.local/bin"
target_zsh_funcs="${XDG_DATA_HOME:-$HOME/.local/share}"/zsh/site-functions


_install_link () {
    if [ $# -ne 2 ]; then
        printf "Wrong number of _install_link args\n" >&2
        exit 5
    fi
    local source="$1"
    local target="$2"
    local target_dir
    target_dir="$(dirname "$target")"
    if ! [ -d "$target_dir" ]; then
        if ! mkdir -p "$target_dir"; then
            printf "Unable to create %s\n" "$target_dir" >&2
            return 1
        fi
    fi
    if [ -e "$target" ]; then
        printf "%s already exists, replacing...\n" "$target" >&2
        rm "$target" || return 1
    fi
    printf "Linking %s\n" "$target" >&2
    ln -s --relative "$source" "$target" || return 1
    return 0
}

_uninstall_link () {
     if [ $# -ne 1 ]; then
        printf "Wrong number of _uninstall_link args\n" >&2
        exit 5
    fi
    local target="$1"
    if [ -e "$target" ]; then
        printf "Unlinking %s\n" "$target" >&2
        rm "$target" || return 1
    else
        printf "%s doesn't exist, skipping\n" "$target" >&2
    fi
    return 0
}

command="$1"

case "$command" in
    install)
        printf "Installing...\n" >&2
        _install_link "$source_dir"/bin/clip.sh "$target_bin"/clip || exit $?
        _install_link "$source_dir"/completions/zsh/_clip "$target_zsh_funcs"/_clip || exit $?
        ;;
    uninstall)
        printf "Uninstalling...\n" >&2
        _uninstall_link "$target_bin"/clip || exit $?
        _uninstall_link "$target_zsh_funcs"/_clip || exit $?
        ;;
esac
printf "Done\n" >&2
exit 0
