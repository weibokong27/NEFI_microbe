#!/bin/bash

usage(){
echo "
Written by Brian Bushnell
Last modified June 13, 2016

Description:  Finds NCBI taxIDs of common ancestors of gi numbers.
Input should be formatted like this:
ori15	gi|818890693,gi|818890691,gi|837354594

Usage:  gi2ancestors.sh in=<input file> out=<output file>


Standard parameters:
in=<file>       Input text file with names sequence names and GI numbers.
out=<file>      Output file.
overwrite=f     (ow) Set to false to force the program to abort rather than
                overwrite an existing file.

Java Parameters:
-Xmx            This will be passed to Java to set memory usage, overriding 
                the program's automatic memory detection.  -Xmx20g will 
                specify 20 gigs of RAM, and -Xmx200m will specify 200 megs.
                The max is typically 85% of physical memory.
-eoom           This flag will cause the process to exit if an out-of-memory exception occurs.  Requires Java 8u92+.
-da             Disable assertions.

Please contact Brian Bushnell at bbushnell@lbl.gov if you encounter any problems.
"
}

#This block allows symlinked shellscripts to correctly set classpath.
pushd . > /dev/null
DIR="${BASH_SOURCE[0]}"
while [ -h "$DIR" ]; do
  cd "$(dirname "$DIR")"
  DIR="$(readlink "$(basename "$DIR")")"
done
cd "$(dirname "$DIR")"
DIR="$(pwd)/"
popd > /dev/null

#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/"
CP="$DIR""current/"

z="-Xmx10g"
z2="-Xms10g"
EA="-ea"
EOOM=""
set=0

if [ -z "$1" ] || [[ $1 == -h ]] || [[ $1 == --help ]]; then
	usage
	exit
fi

calcXmx () {
	source "$DIR""/calcmem.sh"
	parseXmx "$@"
	if [[ $set == 1 ]]; then
		return
	fi
	freeRam 10000m 84
	z="-Xmx${RAM}m"
	z2="-Xms${RAM}m"
}
calcXmx "$@"

gi2ancestors() {
	if [[ $SHIFTER_RUNTIME == 1 ]]; then
		#Ignore NERSC_HOST
		shifter=1
	elif [[ $NERSC_HOST == genepool ]]; then
		module unload oracle-jdk
		module load oracle-jdk/1.8_144_64bit
		module load pigz
	elif [[ $NERSC_HOST == denovo ]]; then
		module unload java
		module load java/1.8.0_144
		module load pigz
	elif [[ $NERSC_HOST == cori ]]; then
		module use /global/common/software/m342/nersc-builds/denovo/Modules/jgi
		module use /global/common/software/m342/nersc-builds/denovo/Modules/usg
		module unload java
		module load java/1.8.0_144
		module load pigz
	fi
	local CMD="java $EA $EOOM $z -cp $CP tax.FindAncestor $@"
	echo $CMD >&2
	eval $CMD
}

gi2ancestors "$@"
