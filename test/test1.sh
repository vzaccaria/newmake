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

run "pushd ${srcdir}/test1"

print_important_message "Removing previous test data"
run "rm -rf _site"
run "rm -rf .build"
run "rm -f ../actual.tree"


print_important_message "Creating makefile"
run "coffee nmake.coffee"


print_important_message "Running test"
run "make all"
tree > ../actual.tree
diff-files ../actual.tree final.tree -m "Test base 0 - Exec"

run "rm -f ../actual.tree"


run "popd"