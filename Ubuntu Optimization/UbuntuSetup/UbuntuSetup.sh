#!/bin/bash

## INSTRUCTIONS: 
#### Run this file first in a terminal from this folder.
#### Terminal can be accessed from
#### the mouse menu in the upper right, by
#### pressing ctrl+alt+t, or by right clicking in this folder 
### and clicking "Open Terminal Here.""
#### Once in terminal, run this file  by using the command
#### bash setup.sh in the terminal.

## DESCRIPTION:
#### In this file we setup all the software
#### Needed to replicate our results
#### Note that in the "Live" version of Ubuntu we
#### do not need a password for sudo commands
#### For your ease and to ensure full replication,
#### we ask you to use the "live" version of Xubuntu 14.04 (Trusty Tahir)
#### Included as a disk image in this replication archive.
#### Detailed instructions on running the live version can be
#### found in the readme file.


## AUTHORS: Casey Crisman-Cox and Michael Gibilisco
##### Created for use on a "Live" version of Xubuntu 14.04.
##### Not guaranteed for any other system or version.

## Basic setup and tools
## This list includes 
#### TeX (required for pyadolc and others)
#### Python and packages
#### basic compilers to build C, C++, and Fotran
#### Git and verion control software
#### other dependencies

REPDIR=`pwd`
cd ~
HOMEDIR=`pwd`
sudo apt update
sudo apt -y upgrade

sudo apt-get -y install build-essential
sudo apt-get -y install python-dev  git 
sudo apt-get -y install texlive-full
sudo apt-get -y install gfortran automake shtool libtool
sudo apt-get -y install python-matplotlib python-scipy python-pandas python-sympy python-nose spyder
sudo apt-get -y install subversion swig
sudo apt-get -y install openmpi-bin openmpi-doc libopenmpi-dev

# Install R
sudo apt-get -y  install r-base-dev
mkdir -p ~/R/x86_64-pc-linux-gnu-library/3.4 

sudo apt -y install libboost-all-dev
sudo apt -y install libboost-python-dev
sudo apt -y install libboost-system-dev

# Additional python packages
sudo pip install numpy --upgrade
sudo pip install rpy2==2.8.6
sudo pip install pandas --upgrade
sudo pip install mpi4py

# ADOLC, Colpack, and IPOPT, use code stored on my bitbucket to help here
git clone https://ccrismancox@bitbucket.org/ccrismancox/pyopterf_windows.git pyopterf
cd pyopterf
bash setup.sh

libdir=${HOMEDIR}/pyopterf/Ipopt-3.12.3/lib
sudo echo $libdir$'\r' | sudo tee -a  /etc/ld.so.conf
sudo ldconfig

sudo apt -y install libgfortran3 #where does this go?


#Additional R work
sudo apt -y install  libcurl4-gnutls-dev libxml2-dev libssl-dev
cd ~
mkdir -p Documents



sudo pip install numpy==1.8.1
sudo pip install pandas==0.13.1
echo "Ubuntu Setup Complete"

