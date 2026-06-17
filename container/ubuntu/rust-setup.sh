#!/usr/bin/env bash

#
# Quick setup script for Rust development in an Apple container machine.
#
# See also: 
# - https://github.com/apple/container
# - https://rkiselenko.dev/blog/development-on-mac-with-acm/
#

set -e

# Install rust toolchain.
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Configure and start SSH.
mkdir -p $HOME/.ssh
echo $(cat /etc/ssh/pub-key.pub) >> $HOME/.ssh/authorized_keys
sudo systemctl start sshd.service
