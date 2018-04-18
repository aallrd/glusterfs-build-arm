#!/bin/bash

__log="/build/build.log"

function _echo {
    echo "${1}" | tee "${__log}"
}

_echo "Gluster: ${GLUSTERFS_VERSION}"
_echo "Installing script dependencies..."
yum update \
    && yum install -y wget unzip git make rpm-build mock \
    && yum clean all

_echo "Downloading gluster-release-${GLUSTERFS_VERSION}..."
wget "https://github.com/gluster/glusterfs/archive/release-${GLUSTERFS_VERSION}.zip" -qO glusterfs-source.zip
if [[ $? -ne 0 ]] ; then
    _echo "Failed to download glusterfs release ${GLUSTERFS_VERSION}."
    exit 1
fi
unzip -qq glusterfs-source.zip && rm $_
cd glusterfs-release-${GLUSTERFS_VERSION} || \
    { _echo "Failed to change directory to glusterfs-release-${GLUSTERFS_VERSION}"; exit 1;}

_echo "Installing glusterfs dependencies..."
yum update \
    && yum install -y automake autoconf libtool flex bison openssl-devel libxml2-devel python-devel libaio-devel libibverbs-devel librdmacm-devel readline-devel lvm2-devel glib2-devel userspace-rcu-devel libcmocka-devel libacl-devel sqlite-devel fuse-devel redhat-rpm-config firewalld \
    && yum clean all

_echo "Starting build..."
./autogen.sh | tee "${__log}"
if [[ $? -ne 0 ]] ; then
    _echo "Failed to autogen."
    exit 1
fi
./configure | tee "${__log}"
if [[ $? -ne 0 ]] ; then
    _echo "Failed to configure."
    exit 1
fi
make -j4 | tee "${__log}"
if [[ $? -ne 0 ]] ; then
    _echo "Failed to make."
    exit 1
fi
make install | tee "${__log}"
if [[ $? -ne 0 ]] ; then
    _echo "Failed to install."
    exit 1
fi

_echo "Starting packaging..."
cd extras/LinuxRPM || \
    { _echo "Failed to change directory to extras/LinuxRPM"; exit 1;}
make glusterrpms | tee "${__log}"
if [[ $? -ne 0 ]] ; then
    _echo "Failed to package."
    exit 1
fi

ls -ltr

exit 0
