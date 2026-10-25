#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
source scripts/config.sh

failed=0
problems=0
not_built=0

mode=check
ask=yes

case "${1:-}" in
    --check) ask=no ;;
    "") ;; # do nothing if empty string
    *)  echo "Usage: $(basename "$0") [--check]" >&2; exit 2 ;;
esac

report() {
    local label=$1
    local state=$2
    
    if [ "$state" != "OK" ] && [ "$state" != "INITIALISED" ] && [ "$state" != "NOT_BUILT" ]; then
	problems=$((problems + 1))
    fi
    if [ "$mode" = "check" ] && [ "$state" = "OK" ]; then
	return
    fi
    printf '%-12s: %s\n' "$label" "$state"
}

# check submodules
check_submodules() {
    if [ "$mode" = "fix" ]; then
	echo "CHECKING SUBMODULES:"
    fi
    
    local _key
    local path
    while read -r _key path; do
	local submodule_status
	submodule_status=$(git submodule status -- "$path")

	local state=ATTENTION
	case "${submodule_status:0:1}" in
	    " ") state=OK ;;
	    "-") state=MISSING;;
	    "+") echo "$path is at a different commit than recorded" ;;
	    "U") echo "Merge conflict in $path" ;;
	    *)   echo "Unknown error in $path" ;;
	esac
	
	if [ "$state" = "OK" ]; then
	    if [ -n "$(git -C "$path" status --porcelain)" ]; then
		state=ATTENTION
		printf '%-12s: %s\n' "$path" "has uncommitted changes"
	    fi
	elif [ "$state" = "MISSING" ]; then
	    if [ "$mode" = "check" ]; then
		printf '%-12s: %s\n' "$path" "is uninitialised. No fix will be applied in check mode."
	    else
		printf '\n%-12s: initialising...\n' "$path"
		if git submodule update --init -- "$path"; then
		    state=INITIALISED
		else
		    state=FAILED
		    failed=1
		fi
	    fi
	fi

	report "$path" "$state"
    done < <(git config --file .gitmodules --get-regexp '\.path$')
}

check_bender() {
    local state=MISSING
    if [ -d "MAGIA/.bender" ]; then
	state=OK
    fi

    if [ "$mode" = "fix" ]; then
	printf '%-12s: %s\n' "Bender" "checking out dependencies..."
	if (cd MAGIA && bender checkout); then
	    if [ "$state" = "MISSING" ]; then
		state=INITIALISED
	    fi
	else
	    state=FAILED
	    failed=1
	fi
    fi

    report "Bender" "$state"
}

check_gvsoc() {
    local state=MISSING
    if [ -d "magia-sdk/gvsoc" ]; then
	state=OK
    fi

    if [ "$mode" = "fix" ]; then
	if [ "$state" = "MISSING" ]; then
	    printf '%-12s: %s\n' "GVSoC" "initialising..."
	    if (cd magia-sdk && make gvsoc_init); then
		state=INITIALISED
	    else
		state=FAILED
		failed=1
	    fi
	fi
    fi

    report "GVSoC" "$state"
}

check_builds() {
    local gvsoc_state=NOT_BUILT
    local verilator_state=NOT_BUILT

    if [ -x magia-sdk/gvsoc/install/bin/gvrun ]; then
	gvsoc_state=OK
    else
	not_built=$((not_built + 1))
    fi

    report "GVSoC build" "$gvsoc_state"

    if [ -x MAGIA/verilator/build/obj_dir/Vmagia_tb ]; then
	verilator_state=OK
    else
	not_built=$((not_built + 1))
    fi

    report "Verilator" "$verilator_state"
}

build_tests() {
    mode=fix
    if ! (cd magia-sdk && make gvsoc tiles="$tiles" spatz="$spatz"); then
	failed=1
    fi

    if ! (cd MAGIA && make verilate mesh_dv=1); then
	failed=1
    fi

    check_builds
}

check_submodules
check_bender
check_gvsoc

if [ "$problems" -gt 0 ]; then
    if [ "$ask" = "yes" ] && [ -t 0 ]; then
	read -r -p "Fix these now? [y/N] " answer
	case "$answer" in
	    y|Y|yes) 
		mode=fix
		problems=0

		check_submodules
		check_bender
		check_gvsoc ;;
	    *) ;;
	esac
    else
	echo "INFO: Run scripts/setup_env.sh to fix missing dependencies"
    fi
fi
	
check_builds

if [ "$not_built" -gt 0 ]; then
    if [ "$ask" = "yes" ] && [ -t 0 ]; then
	read -r -p "Build GVSoC and Verilator model now? (This may take a while) [y/N] " answer
	case "$answer" in
	    y|Y|yes) build_tests ;;
	    *) ;;
	esac
    fi
fi

exit "$failed"
