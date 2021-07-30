#!/bin/bash
# Copyright 2019 VMware, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-2

set -euo pipefail

BOM_FILE=bom.json

if [ ! -e ${BOM_FILE} ]; then
    echo "Unable to locate bom.json in current directory which is required"
    exit 1
fi

if ! hash jq 2>/dev/null; then
    echo "jq utility is not installed on this system"
    exit 1
fi

rm -f output-vmware-iso/*.ova

APPLIANCE_VERSION_FROM_BOM=$(jq -r < ${BOM_FILE} '.appliance.version')

echo "Building Kubernetes Appliance OVA from ${APPLIANCE_VERSION_FROM_BOM} ..."
PACKER_LOG=1 packer build -var "APPLIANCE_VERSION=${APPLIANCE_VERSION_FROM_BOM}" -var-file=photon-builder.json -var-file=photon-version.json photon.json

