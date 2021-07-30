#!/bin/bash
# Copyright 2019 VMware, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-2

# Deploy TinyWWW Pod

set -euo pipefail

kubectl apply -f /root/config/tinywww-debug.yml