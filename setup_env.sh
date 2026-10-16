#!/usr/bin/env bash
set -euo pipefail
# This script should not be run manually. It is called by `mkShell` in the Nix Flake.

mode=fix
case "${1:-}" in
    --check) mode=check ;;
    "") ;; # do nothing if empty string
    *)  echo "Usage: $(basename "$0") [--check]" >&2; exit 2 ;;
esac

tiles=4
spatz=0



cd "$(git rev-parse --show-toplevel)"

# check submodules
check_submodules() {
    while read -r _key path; do
	submodule_status=$(git submodule status -- "$path")

	local state=ATTENTION
	case "${submodule_status:0:1}" in
	    " ") state=OK ;;
	    "-") state=MISSING;;
	    "+") echo "The submodule(s) are at a different commit than recorded" ;;
	    "U") echo "Merge conflict in submodules" ;;
	    *)   echo "Unknown error in submodules" ;;
	esac
	
	if [ "$state" = "OK" ]; then
	    if [ -n "$(git -C "$path" status --porcelain)" ]; then
	       state=ATTENTION
	       printf '%-12s: has uncommitted changes\n' "$path"
	    fi
	elif [ "$state" = "MISSING" ]; then
	    if [ "$mode" = "check" ]; then
		printf '%-12s: is uninitialised. No fix will be applied in check mode.\n' "$path"
	    else
		printf '%-12s: initialising...\t' "$path"
		if git submodule update --init -- "$path"; then
		    printf 'Initialised.\n'
		    state=INITIALISED
		else
		    printf 'Failed.\n'
		    state=FAILED
		fi
	    fi
	fi

	printf '\n%-12s: %s\n' "$path" "$state"
    done < <(git config --file .gitmodules --get-regexp '\.path$')
}

check_submodules 


