#!/usr/bin/env sh 
set -e


bold=$(tput bold)
reset=$(tput sgr0)

function print_important_message {
	echo ""
	printf "${bold}$1${reset}. "
	echo ""
}

srcdir=`dirname $0`
srcdir=`cd $srcdir; pwd`

pushd ${srcdir}/test1

print_important_message "Removing previous test data"
rm -rf _site 
rm -rf .build
rm -f ../actual.tree


print_important_message "Creating makefile"
coffee nmake.coffee


print_important_message "Running test"
make all
tree > ../actual.tree
diff ../actual.tree final.tree

if [ $? -eq 0 ]
then
   print_important_message "TEST OK"
else
   print_important_message "TEST FAILED!!!!"
fi

rm -f ../actual.tree


popd