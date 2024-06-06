#!/bin/bash
# Copyright 2019 VMware, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-2

# OS Specific Settings where ordering does not matter

set -euo pipefail

systemctl enable sshd
systemctl start sshd

echo -e "\e[92mConfiguring OS Root password ..." > /dev/console
echo "root:${ROOT_PASSWORD}" | /usr/sbin/chpasswd

echo -e "\e[92mConfiguring IP Tables for Antrea ..." > /dev/console
iptables -A INPUT -i gw0 -j ACCEPT
iptables-save > /etc/systemd/scripts/ip4save