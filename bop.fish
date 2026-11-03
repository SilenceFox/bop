function bop --description 'Quickly use Emacs bookmarks in terminal sessions'
    set -q BOP_BOOKMARK_PATH; or set -gx BOP_BOOKMARK_PATH "$HOME/.emacs.d/bookmarks"
    set -q BOP_USE_FZF; or set -gx BOP_USE_FZF 1

    if not contains -- "$BOP_USE_FZF" 0 1
        printf 'bop: BOP_USE_FZF must be 0 or 1\n' >&2
        return 1
    end

    set -l file (string replace -r '^~/' "$HOME/" -- "$BOP_BOOKMARK_PATH")
    if not test -r "$file"
        printf 'bop: cannot read bookmarks: %s\n' "$file" >&2
        return 1
    end

    set -l entries (awk '
        /^[[:space:]]*\(+"/ {
            name = $0
            sub(/^[[:space:]]*\(+"/, "", name)
            sub(/".*$/, "", name)
        }
        /^[[:space:]]*\(filename \. "/ {
            path = $0
            sub(/^.*\(filename \. "/, "", path)
            sub(/".*$/, "", path)
            print name "\t" path
        }
    ' "$file")
    or return 1

    if test (count $argv) -eq 0; or contains -- "$argv[1]" -h --help
        set -l name_width 0
        set -l number_width (string length -- (count $entries))
        test $number_width -ge 2; or set number_width 2
        for entry in $entries
            set -l name (string split -m1 \t -- "$entry")[1]
            set -l width (string length --visible -- "$name")
            test $width -le $name_width; or set name_width $width
        end

        set -l number_color ''
        set -l name_color ''
        set -l muted_color ''
        set -l reset ''
        if isatty stdout; and not set -q NO_COLOR; and test "$TERM" != dumb
            set number_color (set_color --bold cyan)
            set name_color (set_color green)
            set muted_color (set_color brblack)
            set reset (set_color normal)
        end

        for i in (seq (count $entries))
            set -l parts (string split -m1 \t -- "$entries[$i]")
            set -l padding (string repeat -n (math $name_width - (string length --visible -- "$parts[1]")) ' ')
            printf '%s%*d%s  %s%s%s%s  %s→  %s%s\n' \
                "$number_color" $number_width $i "$reset" \
                "$name_color" "$parts[1]" "$padding" "$reset" \
                "$muted_color" "$parts[2]" "$reset"
        end
        return
    end

    set -l result

    if string match -qr '^[0-9]+$' -- "$argv[1]"
        set -l idx (math "$argv[1]")
        if test $idx -ge 1; and test $idx -le (count $entries)
            set result $entries[$idx]
        end
    else if test "$BOP_USE_FZF" = 1
        if not command -q fzf
            printf 'bop: fzf not found; install it or set BOP_USE_FZF to 0\n' >&2
            return 1
        end
        set result (printf '%s\n' $entries | fzf --filter="$argv[1]" --delimiter='\t' --nth=1 | head -n 1)
    else
        set -l query (string escape --style=regex -- "$argv[1]")
        for entry in $entries
            set -l name (string split -m1 \t -- "$entry")[1]
            if string match -iqr -- "$query" "$name"
                set result "$entry"
                break
            end
        end
    end

    if test -z "$result"
        printf 'bop: bookmark not found: %s\n' "$argv[1]" >&2
        return 1
    end

    set -l target (string split -m1 \t -- "$result")[2]
    set target (string replace -r '^~' "$HOME" -- "$target")

    test -f "$target"; and set target (path dirname "$target")
    cd "$target"
end
