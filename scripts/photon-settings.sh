#!/bin/bash -eux
# Copyright 2019 VMware, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-2

##
## Misc configuration
##

echo '> Kubernetes Appliance Settings...'

K8S_BOM_FILE=/root/config/k8s-app-bom.json

mkdir -p /root/download && cd /root/download

echo '> Disable IPv6'
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf

echo '> Applying latest Updates...'
cd /etc/yum.repos.d/
sed -i 's/dl.bintray.com\/vmware/packages.vmware.com\/photon\/$releasever/g' photon.repo photon-updates.repo photon-extras.repo photon-debuginfo.repo
tdnf -y update photon-repos
tdnf clean all
tdnf makecache
tdnf -y update

echo '> Installing Additional Packages...'
tdnf install -y \
  less \
  logrotate \
  curl \
  wget \
  git \
  unzip \
  awk \
  tar \
  jq \
  parted \
  apparmor-parser \
  sshpass

echo '> Downloading Containerd'
CONTAINERD_VERSION=$(jq -r < ${K8S_BOM_FILE} '.["containerd"].version')
curl -L https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz -o /root/download/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz
tar -zxvf /root/download/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz -C /usr
rm -f /root/download/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz
containerd config default > /etc/containerd/config.toml

# Update default version of the pause container to the one from VEBA BOM
PAUSE_CONTAINER_NAME="registry.k8s.io/pause"
PAUSE_CONTAINER_VERSION=$(jq -r --arg PAUSE_CONTAINER_NAME ${PAUSE_CONTAINER_NAME} '.kubernetes.containers[] | select(.name == $PAUSE_CONTAINER_NAME) | .version' ${K8S_BOM_FILE})
sed -i "s#sandbox_image.*#sandbox_image = \"${PAUSE_CONTAINER_NAME}:${PAUSE_CONTAINER_VERSION}\"#g" /etc/containerd/config.toml

cat > /usr/lib/systemd/system/containerd.service <<EOF
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target
[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/bin/containerd
Restart=always
RestartSec=5
KillMode=process
Delegate=yes
OOMScoreAdjust=-999
LimitNOFILE=1048576
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
[Install]
WantedBy=multi-user.target
EOF
systemctl enable containerd
systemctl start containerd

echo '> Adding K8s Repo'
K8S_PACKAGE_REPO_VERSION_FULL=$(jq -r < "${K8S_BOM_FILE}" '.["kubernetes"].gitRepoTag')
K8S_PACKAGE_REPO_VERSION=${K8S_PACKAGE_REPO_VERSION_FULL%.*}
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/${K8S_PACKAGE_REPO_VERSION}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/${K8S_PACKAGE_REPO_VERSION}/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

K8S_VERSION=$(jq -r < ${K8S_BOM_FILE} '.["kubernetes"].gitRepoTag' | sed 's/v//g')

# Ensure kubelet is updated to the latest desired K8s version
tdnf install -y kubelet-${K8S_VERSION} kubectl-${K8S_VERSION} kubeadm-${K8S_VERSION}

echo '> Creating directory for setup scripts and configuration files'
mkdir -p /root/setup

echo '> Creating tools.conf to prioritize eth0 interface...'
cat > /etc/vmware-tools/tools.conf << EOF
[guestinfo]
primary-nics=eth0
low-priority-nics=weave,docker0

[guestinfo]
exclude-nics=veth*,vxlan*,datapath
EOF

cat > /etc/k8s-app-release << EOF
Version: ${K8S_APP_VERSION}
EOF

echo '> Enable contrackd log rotation...'
cat > /etc/logrotate.d/contrackd << EOF
/var/log/conntrackd*.log {
	missingok
	size 5M
	rotate 3
        maxage 7
	compress
	copytruncate
}
EOF

echo '> Done'
