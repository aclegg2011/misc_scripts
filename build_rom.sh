#!/bin/bash

rompath=$(pwd)

bliss_variant_name=""
clean="n"
sync="n"
official="n"

if [ -z "$USER" ];then
        export USER="$(id -un)"
fi
#export LC_ALL=C

if [[ $(uname -s) = "Darwin" ]];then
        jobs=$(sysctl -n hw.ncpu)
 elif [[ $(uname -s) = "Linux" ]];then
        jobs=$(nproc)
fi


while test $# -gt 0
do
  case $1 in

  # Normal option processing
    -h | --help)
      echo "Usage: $0 options device_name"
      echo "options:"
      echo "-c | --clean : Does make clean && make clobber"
      echo "       -s | --sync: Repo syncsed repos"
      echo ""
      ;;
    -v | --version)
      echo "Version: Bliss ROM Builder 0.3"
      echo "Updated: 10/19/2018"
      ;;
    -c | --clean)
      clean="y";
      echo "Clean build."
      ;;
    -s | --sync)
      sync="y"
      echo "Repo sync."
      ;;
     -o | --Official)
      official="y"
      echo "Building Official Bliss ROM."
      ;;

  # ...

  # Special cases
    --)
      break
      ;;
    --*)
      # error unknown (long) option $1
      ;;
    -?)
      # error unknown (short) option $1
      ;;

  # FUN STUFF HERE:
  # Split apart combined short options
    -*)
      split=$1
      shift
      set -- $(echo "$split" | cut -c 2- | sed 's/./-& /g') "$@"
      continue
      ;;

  # Done with options
    *)
      break
      ;;
  esac

  # for testing purposes:
  shift
done

if  [ $sync == "y" ];then
repo sync -c -j$jobs --force-sync
fi

if [ $clean == "y" ];then
    make -j$jobs clean
fi

if [ $official == "y" ];then
    export BLISS_BUILDTYPE=OFFICIAL
else
    export BLISS_BUILDTYPE=UNOFFICIAL
fi


buildVariant() {
        lunch bliss_$1-userdebug
         make -j32 blissify
}

if [ -z "$1" ];then
  echo "No Device was selected"
  exit
else
. build/envsetup.sh
echo "$1"
bliss_variant_name=$1
buildVariant $bliss_variant_name
fi
