#!/bin/bash
# Copyright 2019 VMware, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-2

set -euo pipefail

# Deploy TinyWWW Pod

if [ ${K8S_APP_DEBUG} == "True" ]; then
    kubectl apply -f /root/config/tinywww-debug.yml
else
    kubectl apply -f /root/config/tinywww.yml
fi