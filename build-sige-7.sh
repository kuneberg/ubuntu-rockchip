#!/bin/bash

# sudo apt-get update
apt-get update

# sudo apt-get install -y dpkg-dev debhelper cpio flex bison bc openssl libssl-dev libelf-dev python3
apt-get install -y dpkg-dev debhelper cpio flex bison bc openssl libssl-dev libelf-dev python3

# sudo ./build.sh --board=armsom-sige7 --suite=noble --flavor=server
./build.sh --board=armsom-sige7 --suite=noble --flavor=server
