#
# Copyright (C) 2019 BlissRoms & Aren Clegg
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#  Version: ROM Builder 0.5
#  Updated: 8/10/2019
#

#!/bin/bash

# Create build-rom.cfg variables
rm -rf build-rom.cfg
cat > build-rom.cfg << EOF
rompath=$(pwd)
bliss_device=""
build_options=""
bliss_branch=""
rom_variant=""
clean="n"
cleanOption=""
official="n"
officialOption=""
patchOption=""
releaseOption=""
sync="n"
syncOption=""
upload="n"
EOF

#Import build-rom.cfg variables
source build-rom.cfg

# Clear Terminal Screeen
clear

# Define USER and define how many threads the cpu has
if [ -z "$USER" ];then
        export USER="$(id -un)"
fi

if [[ $(uname -s) = "Darwin" ]];then
        jobs=$(sysctl -n hw.ncpu)
elif [[ $(uname -s) = "Linux" ]];then
        jobs=$(nproc)
fi


# Code that interputs the command line switches
while test $# -gt 0
do
  case $1 in

  # Normal option processing
    -h | --help)
      echo "Usage: $0 options device_name"
      echo "options:"
      echo "-c | --clean    : Does make clean && make clobber"
      echo "-o | --official : Builds the rom as OFFICIAL"
      echo "-s | --sync     : Repo sync repos"
      echo "-u | --upload   : Uploads Official Builds to Bliss and Local sFTP"
      echo "-----------------------------------------------------------------"
      echo "Treble Only Flags"
      echo "-----------------------------------------------------------------"
      echo "-p | --patch    : "
      echo "-r | --release  : "
      echo ""
      ;;
    -c | --clean)
      clean="y";
      echo "Clean build."
      ;;
    -s | --sync)
      sync="y"
      echo "Repo sync."
      ;;
    -o | --official)
      official="y"
      echo "Building Official Bliss ROM."
      ;;
    -p | --patch)
      patchOption="p";
      echo "patching selected."
      ;;
    -r | --release)
      releaseOption="r";
      echo "Building as release selected."
      ;;
    -u | --upload)
      upload="y"
      echo "Upload to Bliss and Personal sFTP."
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

read -p "Continuing in 1 second..." -t 1
echo "Continuing..."

# If statement for $sync
if  [[ $sync == "y" && $1 = "arm" ]];then
    repo sync -c -j$jobs --force-sync
#elif [ $sync == "y" ];then
    syncOption="s"
fi

# If statment for $clean
if [[ $clean == "y" && $1 = "arm" ]];then
    make -j$jobs clean
#elif [ $clean == "y" ];then
    cleanOption="c"
fi

# If statement for $official
if [[ $official == "y" && $1 = "arm" ]];then
    export BLISS_BUILDTYPE=OFFICIAL
#elif [ $official == "y" ];then
    officialOption="o"
else
    export BLISS_BUILDTYPE=UNOFFICIAL
fi

# Official Bliss FTP server upload function
blissSFTP(){
FILEPATH=$rompath/out/target/product/$bliss_variant_name
cd $FILEPATH
echo ""
BLISSZIP=$(ls Bliss-*.zip)
BLISSMD5=$(ls Bliss-*.md5)
BLISSLOG=$(ls Changelog-Bliss-*.txt)

if [[ -a $BLISSZIP && -a $BLISSMD5 && -a $BLISSLOG ]]; then
   echo $BLISSZIP
   echo $BLISSMD5
   echo $BLISSLOG
else
   echo "Upload(s) Failed due to missing files"
   return 0
fi

BLISSPASS=password
sshpass -p $password sftp -P xx xxxx@xxxx <<EOF
cd Pie/$bliss_variant_name
put $BLISSZIP
put $BLISSMD5
put $BLISSLOG
bye
EOF

BLISSPASS=password
sshpass -p $BLISSPASS sftp -P xx xxx@xxx <<EOF
cd $bliss_variant_name
put $BLISSZIP
put $BLISSMD5
put $BLISSLOG
bye
EOF

}

# Build rom function
blissBuildVariant_arm() {
        lunch bliss_$2-userdebug
        make -j$jobs blissify
}

# Build treble rom function
blissBuildVariant_treble() {
       bash /build/make/core/treble/build-treble.sh $1 $2 $3
}

bliss_branch=$3
bliss_device=$2
rom_variant=$1
build_options=$cleanOption$syncOption$officialOption$patchOption$releaseOption

# If rom_variant is empty, stop the script
if [ -z $rom_variant ];then
  echo "No Rom variant was selected"
  exit
fi

# If bliss_device is empty, stop the script
if [ -z $bliss_device ];then
  echo "No Device was selected"
  exit
fi

# If build_options is not empty add the - options flag
if [ ! -z "$build_options" ];then
   build_options=-$cleanOption$syncOption$officialOption$patchOption$releaseOption
fi

# If statment for building arm or treble
if [ $rom_variant = "arm" ];then
   . build/envsetup.sh
   blissBuildVariant_arm $rom_variant $bliss_device

elif [ $rom_variant = "treble" ];then
   blissBuildVariant_treble $build_options $bliss_device $bliss_branch
fi

# If statment for FTP uploading
if [[ $upload == "y" && $official="y" ]];then
   blissSFTP $bliss_device
fi
