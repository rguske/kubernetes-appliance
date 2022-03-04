#!/bin/bash -eux
# Copyright 2019 VMware, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-2

echo '> Pre-Downloading Kubeadm Docker Containers'

K8S_BOM_FILE=/root/config/k8s-app-bom.json

for component_name in $(jq '. | keys | .[]' ${K8S_BOM_FILE});
do
    HAS_CONTAINERS=$(jq ".$component_name | select(.containers != null)" ${K8S_BOM_FILE})
    if [ "${HAS_CONTAINERS}" != "" ]; then
        for i in $(jq ".$component_name.containers | keys | .[]" ${K8S_BOM_FILE}); do
            value=$(jq -r ".$component_name.containers[$i]" ${K8S_BOM_FILE});
            container_name=$(jq -r '.name' <<< "$value");
            container_version=$(jq -r '.version' <<< "$value");
            docker pull "$container_name:$container_version"
        done
    fi
done

mkdir -p /root/download && cd /root/download
cd ..

echo '> Downloading Antrea...'
ANTREA_VERSION=$(jq -r < ${K8S_BOM_FILE} '.["antrea"].gitRepoTag')
ANTREA_CONTAINER_VERSION=$(jq -r < ${K8S_BOM_FILE} '.["antrea"].containers | .[] | select(.name | contains("antrea/antrea-ubuntu")).version')
wget https://github.com/vmware-tanzu/antrea/releases/download/${ANTREA_VERSION}/antrea.yml -O /root/download/antrea.yml
sed -i "s/image: antrea\/antrea-ubuntu:.*/image: antrea\/antrea-ubuntu:${ANTREA_CONTAINER_VERSION}/g" /root/download/antrea.yml
sed -i '/image:.*/i \        imagePullPolicy: IfNotPresent' /root/download/antrea.yml