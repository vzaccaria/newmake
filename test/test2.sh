#!/usr/bin/env sh 
set -e

silent=true

run() {
  if [[ $silent == false ]] ; then
    eval "$1 "
	else 
	eval "$1 &> /dev/null"
  fi
}

bold=$(tput bold)
reset=$(tput sgr0)

function print_important_message {
	if [[ $silent == false ]]; then
		echo ""
		printf "${bold}$1${reset}. "
		echo ""
	fi

}

srcdir=`dirname $0`
srcdir=`cd $srcdir; pwd`

run "pushd ${srcdir}/test2"

print_important_message "Removing previous test data"
run "rm -rf _site"
run "rm -rf .build"
run "rm -f ../actual.tree"

print_important_message "Creating makefile"
run "coffee nmake.coffee"

run "mkdir .build"
print_important_message "Running pre-test"
run "make all"

print_important_message "Cleaning up"
run "make clean"

print_important_message "Checking if cleaned"
tree -a > ../actual.tree
diff-files ../actual.tree orig.tree  -m "Test base 1 - Cleaned"

print_important_message "Building for final check"
run "make all"

tree -a > ../actual.tree
diff-files ../actual.tree final.tree -m "Test base 1 - Exec"

run "rm -f ../actual.tree"

run "popd"