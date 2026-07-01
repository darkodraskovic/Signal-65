#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")" && pwd)"
cd "$project_dir"

kickasm_jar="/Users/darkodraskovic/dev/mega65/tools/kickass/KickAss65CE02-5.25.jar"
c1541="/Users/darkodraskovic/dev/mega65/tools/c1541"
xemu_xmega65="/Users/darkodraskovic/Documents/xemu/build/bin/xmega65.native"

src_file="src/main.asm"
bin_dir="bin"
d81_name="WDW.D81"
prg_name="main.prg"

usage() {
	echo "usage: ./make.sh [build|run]"
	echo
	echo "  build  assemble src/main.asm and create bin/$d81_name"
	echo "  run    build, then launch Xemu with bin/$prg_name"
}

build() {
	mkdir -p "$bin_dir"

	echo "assembling code"
	# Kick Assembler resolves -odir relative to the source file's directory.
	java -jar "$kickasm_jar" -vicesymbols -showmem "$src_file" -odir ../"$bin_dir"

	echo "making disk image"
	"$c1541" -format "disk,0" d81 "$bin_dir/$d81_name"

	echo "copying program to disk image"
	"$c1541" -attach "$bin_dir/$d81_name" 8 -write "$bin_dir/$prg_name" main
}

run() {
	build

	echo "launching Xemu"
	"$xemu_xmega65" -besure -prgmode 65 -prg "$bin_dir/$prg_name"
}

case "${1:-build}" in
	build)
		build
		;;
	run)
		run
		;;
	-h|--help|help)
		usage
		;;
	*)
		usage
		exit 1
		;;
esac
