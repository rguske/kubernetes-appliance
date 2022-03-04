#!/bin/bash
# Copyright 2019 VMware, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-2

set -euo pipefail

K8S_BOM_FILE=k8s-app-bom.json

if [ ! -e ${K8S_BOM_FILE} ]; then
    echo "Unable to locate k8s-app-bom.json in current directory which is required"
    exit 1
fi

if ! hash jq 2>/dev/null; then
    echo "jq utility is not installed on this system"
    exit 1
fi

rm -f output-iso/*.ova

K8S_APP_VERSION_FROM_BOM=$(jq -r < ${K8S_BOM_FILE} '.appliance.version')

echo "Building K8s Appliance OVA from ${K8S_APP_VERSION_FROM_BOM} ..."
PACKER_LOG=1 packer build -var "K8S_APP_VERSION=${K8S_APP_VERSION_FROM_BOM}" -var-file=photon-builder.json -var-file=photon-version.json photon.json
