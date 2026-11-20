#!/bin/bash
#
# clean_qb64.sh - remove the temporary folders and compilation leftovers that
# QB64 leaves behind in the qb64pe and qb64-classic trees.
#
# This is the bash/Haiku equivalent of QB64-PE's internal/clean.bat.
#
# Every time the compiler starts it takes a lock on internal/temp. If that
# folder is still locked - the IDE crashed, the program was killed, or a second
# instance is running - it moves on to internal/temp2, temp3 and so on, and
# copies internal/c/qbx.cpp to internal/c/qbxN.cpp so the two translation units
# do not collide. Neither tree ever removes those folders again, so after a few
# crashes they pile up, together with the object files and archives that every
# program compile produces under internal/c.
#
# This script returns both trees to their pre-build state:
#
#   * internal/temp and internal/temp<N> are deleted and internal/temp is
#     recreated with the dummy temp.bin lock file - exactly what clean.bat does;
#   * the internal/c/qbx<N>.cpp copies are deleted (qbx.cpp itself is kept);
#   * *.o, *.a and *.sym files under internal/c are deleted, so the compiler
#     rebuilds the runtime parts on the next program compile;
#   * the list/bookmark files the old Windows IDE dropped into qb64pe/source are
#     deleted (the current Linux/Haiku IDE keeps them in internal/temp).
#
# The IDE executables (qb64, qb64pe), the compiler sources in internal/source
# and everything else are left alone. internal/source must survive: both
# setup scripts copy it into internal/temp when the IDE is rebuilt.
#
# Usage: bash clean_qb64.sh [-n] [-y] [-b] [pe|classic|DIR ...]
#
#   -n, --dry-run   show what would be removed, delete nothing
#   -y, --yes       do not ask for confirmation
#   -b, --build     also delete a CMake build/ directory in each tree
#   -h, --help      show this help
#
# Without arguments both trees that exist next to this script are cleaned.

set -u

prog=$(basename "$0")
root=$(cd "$(dirname "$0")" && pwd) || exit 1

dry_run=0
assume_yes=0
remove_build=0
trees=()

usage() {
	sed -n '3,40p' "$0" | sed 's/^#\{1,2\} \{0,1\}//'
}

add_tree() {
	case $1 in
		pe | qb64pe) trees+=("$root/qb64pe") ;;
		classic | qb64-classic) trees+=("$root/qb64-classic") ;;
		*) trees+=("$1") ;;
	esac
}

while [ $# -gt 0 ]; do
	case $1 in
		-n | --dry-run) dry_run=1 ;;
		-y | --yes) assume_yes=1 ;;
		-b | --build) remove_build=1 ;;
		-h | --help) usage; exit 0 ;;
		--) shift; while [ $# -gt 0 ]; do add_tree "$1"; shift; done; break ;;
		-*) echo "$prog: unknown option '$1' (try --help)" >&2; exit 2 ;;
		*) add_tree "$1" ;;
	esac
	shift
done

if [ ${#trees[@]} -eq 0 ]; then
	for candidate in qb64pe qb64-classic; do
		[ -d "$root/$candidate" ] && trees+=("$root/$candidate")
	done
	# The script may also be copied into a tree and run from there.
	if [ ${#trees[@]} -eq 0 ] && [ -d "$root/internal" ] && [ -d "$root/source" ]; then
		trees+=("$root")
	fi
fi

if [ ${#trees[@]} -eq 0 ]; then
	echo "$prog: no qb64pe or qb64-classic tree found in $root" >&2
	exit 1
fi

# remove_paths <label> <path>...
# Prints a one-line report and deletes the paths that exist; in a dry run it
# only lists them. Paths come from globs, so non-matching ones are skipped.
remove_paths() {
	local label=$1
	shift
	local found=() p

	for p in "$@"; do
		[ -e "$p" ] && found+=("$p")
	done

	[ ${#found[@]} -eq 0 ] && return 0

	if [ "$dry_run" -eq 1 ]; then
		printf '  %-14s %s (%d)\n' "$label:" "would remove" "${#found[@]}"
		printf '    %s\n' "${found[@]}"
	else
		printf '  %-14s %s (%d)\n' "$label:" "removing" "${#found[@]}"
		rm -rf -- "${found[@]}"
	fi
}

clean_tree() {
	local tree=$1
	local label
	label=$(basename "$tree")

	if [ ! -d "$tree/internal" ] || [ ! -d "$tree/source" ]; then
		echo "$label: not a QB64 tree (no internal/ and source/), skipping" >&2
		return 1
	fi

	echo "$label:"

	# internal/temp, temp2, temp3, ... The glob never matches temp.bin.
	remove_paths "temp folders" "$tree"/internal/temp "$tree"/internal/temp[0-9]*

	# Put the empty lock file back, as clean.bat does with source\temp.bin.
	if [ "$dry_run" -eq 0 ]; then
		mkdir -p "$tree/internal/temp"
		if [ -f "$tree/internal/source/temp.bin" ]; then
			cp -p "$tree/internal/source/temp.bin" "$tree/internal/temp/temp.bin"
		else
			: >"$tree/internal/temp/temp.bin"
		fi
		echo "  temp.bin:      recreated"
	fi

	# qbx2.cpp ... qbx999.cpp; qbx.cpp itself does not match the glob.
	remove_paths "qbxN copies" "$tree"/internal/c/qbx[0-9]*.cpp

	# Object files, archives and debug symbols from earlier program compiles.
	# The compiler rebuilds whatever a program needs on its next compile.
	local leftovers=() p
	while IFS= read -r p; do
		leftovers+=("$p")
	done < <(find "$tree/internal/c" -type f \
		\( -name '*.o' -o -name '*.a' -o -name '*.sym' \) 2>/dev/null)
	[ ${#leftovers[@]} -gt 0 ] && remove_paths "objects" "${leftovers[@]}"

	# Files the Windows IDE used to write into source/ (see clean.bat).
	remove_paths "source files" \
		"$tree/source/undo2.bin" \
		"$tree/source/recompile.bat" \
		"$tree/source/debug.bat" \
		"$tree/source/files.txt" \
		"$tree/source/paths.txt" \
		"$tree/source/root.txt" \
		"$tree/source/bookmarks.bin" \
		"$tree/source/recent.bin"

	if [ "$remove_build" -eq 1 ]; then
		remove_paths "cmake build" "$tree/build"
	fi
}

if [ "$dry_run" -eq 0 ] && [ "$assume_yes" -eq 0 ]; then
	printf 'Clean %s? [y/N] ' "${trees[*]}"
	if [ -t 0 ]; then
		read -r reply
		case $reply in
			y | Y | yes | YES) ;;
			*) echo "aborted"; exit 0 ;;
		esac
	else
		echo
		echo "$prog: no terminal to ask on; use --yes to clean without confirmation" >&2
		exit 1
	fi
fi

status=0
for tree in "${trees[@]}"; do
	clean_tree "$tree" || status=1
done

if [ "$dry_run" -eq 1 ]; then
	echo "Dry run: nothing was deleted."
elif [ $status -eq 0 ]; then
	echo "Done. The qb64 and qb64pe executables were left in place; run"
	echo "./setup_haiku.sh (or the CMake build) if you also want the compiler"
	echo "itself rebuilt."
fi

exit $status
