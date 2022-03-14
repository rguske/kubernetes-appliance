#!/bin/bash -eux
# Copyright 2019 VMware, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-2

##
## Misc configuration
##

echo '> Kubernetes Appliance Settings...'

K8S_BOM_FILE=/root/config/k8s-app-bom.json

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
  sshpass

echo '> Adding K8s Repo'
curl -L https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg -o /etc/pki/rpm-gpg/GOOGLE-RPM-GPG-KEY
rpm --import /etc/pki/rpm-gpg/GOOGLE-RPM-GPG-KEY
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/GOOGLE-RPM-GPG-KEY
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
