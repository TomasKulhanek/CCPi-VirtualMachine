#!/bin/bash
#
# Script to install/update the CCP-PETMR VM. It could also be used for any other system
# but will currently change your .sirfrc. This is to be avoided later on.
#
# Authors: Kris Thielemans, Evgueni Ovtchinnikov and Edoardo Pasca
# Copyright 2016-2018 University College London
# Copyright 2016-2018 Rutherford Appleton Laboratory STFC
#
# This is software developed for the Collaborative Computational
# Project in Positron Emission Tomography and Magnetic Resonance imaging
# (http://www.ccppetmr.ac.uk/).

#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0.txt
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
#=========================================================================


# Exit if something goes wrong
set -e
# give a sensible error message (note: works only in bash)
trap 'echo An error occurred in $0 at line $LINENO. Current working-dir: $PWD' ERR
SB_TAG='default'
num_parallel=2
while getopts ht:j: option
 do
 case "${option}"
  in
  t) SB_TAG=$OPTARG;;
  j) num_parallel=$OPTARG;;
  h)
   echo "Usage: $0 [-t tag] [-j n]"
   echo "Use the tag option to checkout a specific version."
   echo "Otherwise the most recent release will be used."
   echo "Use the -j option to change the number of parallel builds from the default ${num_parallel}"
   exit 
   ;;
  *)
   echo "Wrong option passed. Use the -h option to get some help." >&2
   exit 1
  ;;
 esac
done
# get rid of processed options
shift $((OPTIND-1))

if [ $# -ne 0 ]
then
  echo "Wrong command line format. Use the -h option to get some help." >&2
  exit 1
fi

if [ -r ~/.sirfrc ]
then
  source ~/.sirfrc
else
  if [ ! -e ~/.bashrc ]
  then 
    touch ~/.bashrc
  fi
  #added=`grep -c "source ~/.sirfrc" ~/.bashrc`
  added=`cat ~/.bashrc | gawk 'BEGIN{v=0;} {if ($0 == "source ~/.sirfrc") v=v+1;} END{print v}'`
  if [ $added -eq "0" ] 
  then
    echo "I will create a ~/.sirfrc file and source this from your .bashrc"
    echo "source ~/.sirfrc" >> ~/.bashrc
  else
  echo "source ~/.sirfrc already present $added times in .bashrc. Not adding"
  fi
fi

if [ -r ~/.sirf_VM_version ]
then
  source ~/.sirf_VM_version
else
  if [ -r /usr/local/bin/update_VM.sh ]
  then
    # we are on the old VM
    SIRF_VM_VERSION=0.1
    echo virtual | sudo -S apt-get -y install python-scipy python-docopt python-matplotlib
  else
    SIRF_VM_VERSION=0.9
  fi
  echo "export SIRF_VM_VERSION=$SIRF_VM_VERSION" > ~/.sirf_VM_version
fi

# location of sources
if [ -z $SIRF_SRC_PATH ]
then
  export SIRF_SRC_PATH=~/devel
fi
if [ ! -d $SIRF_SRC_PATH ]
then
  mkdir -p $SIRF_SRC_PATH
fi

SIRF_INSTALL_PATH=$SIRF_SRC_PATH/install

# SuperBuild
SuperBuild(){
  echo "==================== SuperBuild ====================="
  cd $SIRF_SRC_PATH
  if [ ! -d SIRF-SuperBuild ] 
  then
    git clone https://github.com/CCPPETMR/SIRF-SuperBuild.git
    cd SIRF-SuperBuild
  else
    cd SIRF-SuperBuild
    git fetch
  fi
  # go to SB_TAG
  if [ $1 = 'default' ] 
  then
   # get the latest tag matching v
   SB_TAG=`git fetch; git for-each-ref refs/tags/v* --sort=-taggerdate --format='%(refname:short)' --count=1`
  else
   SB_TAG=$1
  fi
  git checkout $SB_TAG
  cd ..
  mkdir -p buildVM
  
  cd buildVM
  cmake ../SIRF-SuperBuild \
      -DCMAKE_INSTALL_PREFIX=${SIRF_INSTALL_PATH} \
	  -USIRF_URL -USIRF_TAG -USTIR_URL -USTIR_TAG \
	  -UGadgetron_URL -UGadgetron_TAG -UISMRMRD_URL \
	  -UISMRMRD_TAG \
	  -DUSE_SYSTEM_SWIG=On \
	  -DUSE_SYSTEM_Boost=Off \
	  -DUSE_SYSTEM_Armadillo=On \
	  -DUSE_SYSTEM_FFTW3=On \
	  -DUSE_SYSTEM_HDF5=ON \
	  -DUSE_SYSTEM_ACE=Off \
	  -DBUILD_siemens_to_ismrmrd=On \
	  -DDEVEL_BUILD=OFF
  make -j${num_parallel}

  if [ ! -f ${SIRF_INSTALL_PATH}/share/gadgetron/config/gadgetron.xml ]
  then
      if [ -f ${SIRF_INSTALL_PATH}/share/gadgetron/config/gadgetron.xml.example ]
      then
          cp ${SIRF_INSTALL_PATH}/share/gadgetron/config/gadgetron.xml.example ${SIRF_INSTALL_PATH}/share/gadgetron/config/gadgetron.xml
      fi
  fi

  if [ $SIRF_VM_VERSION = "0.9" ] 
  then 
    echo "*********************************************************"
    echo "Your SIRF Installation is now Updated"
    echo "We reccommend to delete old files and directories:"
    echo ""
    echo "rm -rf $SIRF_SRC_PATH/build"
    echo "rm -rf $SIRF_SRC_PATH/gadgetron"
    echo "rm -rf $SIRF_SRC_PATH/ismrmrd"
    echo "rm -rf $SIRF_SRC_PATH/SIRF"
    echo "rm -rf $SIRF_SRC_PATH/STIR"
    echo "*********************************************************"
  fi
}

# define a function to get the source
# arguments: name_of_repo [git_ref]
clone_or_pull()
{
  repo=$1
  git_ref=${2:-master} # default to master
  echo "======================  Getting/updating source for $repo"
  cd $SIRF_SRC_PATH
  if [ -d $repo ]
  then
    cd $repo
    git fetch
    git pull
  else
    git clone --recursive https://github.com/CCPPETMR/$repo
    cd $repo
  fi
  git checkout $git_ref
  git submodule update --init
}

# define a function to build and install
# arguments: name_of_repo [cmake arguments]
build_and_install()
{
  repo=$1
  shift
  echo "======================  Building $repo"
  cd $SIRF_BUILD_PATH
  if [ -d $repo ]
  then
    cd $repo
    cmake .
  else
    mkdir $repo
    cd $repo
    $CMAKE $* $SIRF_SRC_PATH/$repo
  fi
  echo "======================  Installing $repo"
  make install
}

# function to do everything
update()
{
  clone_or_pull $1
  build_and_install $*
}

# Launch the SuperBuild to update
SuperBuild $SB_TAG

# Get extra python tools
clone_or_pull ismrmrd-python-tools
cd $SIRF_SRC_PATH/ismrmrd-python-tools
python setup.py install --user

# check STIR-exercises
cd $SIRF_SRC_PATH
if [ -d STIR-exercises ]; then
  cd STIR-exercises
  git pull
fi

# copy scripts into the path
cp -vp $SIRF_SRC_PATH/CCPPETMR_VM/scripts/update*sh $SIRF_INSTALL_PATH/bin

# install the SIRF-Exercises
cd $SIRF_SRC_PATH
clone_or_pull SIRF-Exercises
python -m pip install --user nbstripout
cd $SIRF_SRC_PATH/SIRF-Exercises
PY_USER_BIN=`python -c 'import site; import os; print ( os.path.join(site.USER_BASE , "bin") )'`
export PATH=${PY_USER_BIN}:${PATH}
nbstripout --install

# copy help file to Desktop
if [ ! -d ~/Desktop ]
then
  if [ -e ~/Desktop ]
    then 
	mv ~/Desktop ~/Desktop.file
  fi
  mkdir ~/Desktop 
fi 
cp -vp $SIRF_SRC_PATH/CCPPETMR_VM/HELP.txt ~/Desktop/

if [ -r ~/.sirfc ]; then
  echo "Moving existing ~/.sirfc to a backup copy"
  mv -v ~/.sirfc ~/.sirfc.old
fi
echo "export SIRF_SRC_PATH=$SIRF_SRC_PATH" > ~/.sirfrc
echo "source ${SIRF_INSTALL_PATH}/bin/env_ccppetmr.sh" >> ~/.sirfrc
echo "export EDITOR=nano" >> ~/.sirfrc
if [ ! -z "$STIR_exercises_PATH" ]; then
    echo "export STIR_exercises_PATH=$SIRF_SRC_PATH/STIR-exercises" >> ~/.sirfrc
fi

# TODO get this from somewhere else
version=`echo -n "export SIRF_VM_VERSION=" | cat - ${SIRF_SRC_PATH}/CCPPETMR_VM/VM_version.txt`
#echo "export SIRF_VM_VERSION=0.9.2" > ~/.sirf_VM_version
echo $version > ~/.sirf_VM_version

echo ""
echo "SIRF update done!"
echo "Contents of your .sirfrc is now as follows"
echo "=================================================="
cat ~/.sirfrc
echo "=================================================="
echo "This file is sourced from your .bashrc."
echo "Close your terminal and re-open a new one to update your environment variables"
