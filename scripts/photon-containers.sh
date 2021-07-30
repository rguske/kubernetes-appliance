#!/bin/bash -eux
# Copyright 2019 VMware, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-2

echo '> Pre-Downloading Kubeadm Docker Containers'

BOM_FILE=/root/config/bom.json

for component_name in $(jq '. | keys | .[]' ${BOM_FILE});
do
    HAS_CONTAINERS=$(jq ".$component_name | select(.containers != null)" ${BOM_FILE})
    if [ "${HAS_CONTAINERS}" != "" ]; then
        for i in $(jq ".$component_name.containers | keys | .[]" ${BOM_FILE}); do
            value=$(jq -r ".$component_name.containers[$i]" ${BOM_FILE});
            container_name=$(jq -r '.name' <<< "$value");
            container_version=$(jq -r '.version' <<< "$value");
            docker pull "$container_name:$container_version"
        done
    fi
done

mkdir -p /root/download && cd /root/download

echo '> Downloading Antrea...'
ANTREA_VERSION=$(jq -r < ${BOM_FILE} '.["antrea"].gitRepoTag')
ANTREA_CONTAINER_VERSION=$(jq -r < ${BOM_FILE} '.["antrea"].containers | .[] | select(.name | contains("antrea/antrea-ubuntu")).version')
wget https://github.com/vmware-tanzu/antrea/releases/download/${ANTREA_VERSION}/antrea.yml -O /root/download/antrea.yml
sed -i "s/image: antrea\/antrea-ubuntu:.*/image: antrea\/antrea-ubuntu:${ANTREA_CONTAINER_VERSION}/g" /root/download/antrea.yml
sed -i '/image:.*/i \        imagePullPolicy: IfNotPresent' /root/download/antrea.yml

echo '> Downloading Local Path Provisioner...'
LOCAL_PROVISIONER_VERSION=$(jq -r < ${BOM_FILE} '.["csi"].gitRepoTag')
LOCAL_STOARGE_VOLUME_PATH="/data/local-path-provisioner"
curl -L https://raw.githubusercontent.com/rancher/local-path-provisioner/${LOCAL_PROVISIONER_VERSION}/deploy/local-path-storage.yaml -o /root/download/local-path-storage.yaml
sed -i "s#/opt/local-path-provisioner#${LOCAL_STOARGE_VOLUME_PATH}#g" /root/download/local-path-storage.yaml
sed -i 's/busybox/busybox:latest/g' /root/download/local-path-storage.yaml
sed -i '/image: busybox.*/i \            imagePullPolicy: IfNotPresent' /root/download/local-path-storage.yaml