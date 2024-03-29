#!/bin/bash
# Copyright 2019 VMware, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-2

# OS Specific Settings where ordering does not matter

set -euo pipefail

# Enable SSH
systemctl enable sshd
systemctl start sshd


# Ensure docker is stopped to allow config of network/proxies
systemctl stop docker

echo -e "\e[92mConfiguring OS Root password ..." > /dev/console
echo "root:${ROOT_PASSWORD}" | /usr/sbin/chpasswd

if [ "${DOCKER_NETWORK_CIDR}" != "172.17.0.1/16" ]; then
    echo -e "\e[92mConfiguring Docker Bridge Network ..." > /dev/console
    cat > /etc/docker/daemon.json << EOF
{
    "bip": "${DOCKER_NETWORK_CIDR}",
    "log-opts": {
       "max-size": "10m",
       "max-file": "5"
    }
}
EOF
fi

echo -e "\e[92mConfiguring IP Tables for Antrea ..." > /dev/console
iptables -A INPUT -i gw0 -j ACCEPT
iptables-save > /etc/systemd/scripts/ip4save