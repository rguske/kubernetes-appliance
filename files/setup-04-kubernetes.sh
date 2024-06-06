#!/bin/bash
# Copyright 2019 VMware, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-2

# Setup Containerd and Kubernetes

set -euo pipefail

K8S_BOM_FILE=/root/config/k8s-app-bom.json

echo -e "\e[92mStarting Containerd ..." > /dev/console
systemctl daemon-reload
systemctl enable containerd
systemctl start containerd

echo -e "\e[92mDisabling/Stopping IP Tables  ..." > /dev/console
systemctl stop iptables
systemctl disable iptables

# Customize the POD CIDR Network if provided or else default to 172.16.0.0/16
if [ -z "${POD_NETWORK_CIDR}" ]; then
    POD_NETWORK_CIDR="172.16.0.0/16"
fi

# Start kubelet.service
systemctl enable kubelet.service

# Setup k8s
echo -e "\e[92mSetting up k8s ..." > /dev/console
K8S_VERSION=$(jq -r < ${K8S_BOM_FILE} '.["kubernetes"].gitRepoTag')
cat > /root/config/kubeconfig.yml << __EOF__
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: ${K8S_VERSION}
networking:
  podSubnet: ${POD_NETWORK_CIDR}
__EOF__

echo -e "\e[92mDeloying kubeadm ..." > /dev/console
HOME=/root
kubeadm init --ignore-preflight-errors SystemVerification --skip-token-print --config /root/config/kubeconfig.yml

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

echo -e "\e[92mDeloying Antrea ..." > /dev/console
kubectl --kubeconfig /root/.kube/config apply -f /root/download/antrea.yml

echo -e "\e[92mStarting k8s ..." > /dev/console
systemctl enable kubelet.service

while [[ $(systemctl is-active kubelet.service) == "inactive" ]]
do
    echo -e "\e[92mk8s service is still inactive, sleeping for 10secs" > /dev/console
    sleep 10
done

echo -e "\e[92mInstalling Local-Path-Storage ..." > /dev/console

CSI_VERSION=$(jq -r < ${K8S_BOM_FILE} '.["csi"].gitRepoTag')

# Download local-path-provisioner config file
cd /root/config
curl -L https://raw.githubusercontent.com/rancher/local-path-provisioner/${CSI_VERSION}/deploy/local-path-storage.yaml -o local-path-storage.yaml

# Apply local-path-provisioner file to k8s
kubectl apply -f local-path-storage.yaml

# Set default K8s Storageclass
kubectl patch sc local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Join as a new Node
if [ -n "${NODE_FQDN}" ]; then
    echo -e "\e[92mJoining an existing Control Plane Node ..." > /dev/console

# Create token on Master Node
NODE_TOKEN=$(sshpass -p ${NODE_PASSWORD} ssh -o 'StrictHostKeyChecking no' root@${NODE_FQDN} kubeadm token create)
DISCOVERY_TOKEN=$(sshpass -p ${NODE_PASSWORD} ssh -o 'StrictHostKeyChecking no' root@${NODE_FQDN} openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')

# Reset kubeadm config on the node
kubeadm reset --force

# Join Node
kubeadm join ${NODE_FQDN}:6443 --token ${NODE_TOKEN} --discovery-token-ca-cert-hash sha256:${DISCOVERY_TOKEN} --ignore-preflight-errors=All
fi

# End of Script
