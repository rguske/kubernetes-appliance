# Kubernetes Appliance - VMware OVA

[![Twitter Follow](https://img.shields.io/twitter/follow/vmw_rguske?style=social)](https://twitter.com/vmw_rguske)

:pencil: [My Personal Blog](https://rguske.github.io)

## :book: Table of Content

- [Kubernetes Appliance - VMware OVA](#kubernetes-appliance---vmware-ova)
  - [:book: Table of Content](#book-table-of-content)
  - [:raised_hands: Credits](#raised_hands-credits)
  - [Overview](#overview)
  - [:computer: Requirements](#computer-requirements)
  - [Building the Appliance](#building-the-appliance)
    - [Debugging](#debugging)
    - [Output directoy](#output-directoy)

## :raised_hands: Credits

Credits goes out to [William Lam](https://twitter.com/lamw). He developed this great way to build an VMware Photon OS based appliance in an automated fashion from scratch for project [VMware Event Broker Appliance](https://www.vmweventbroker.io). I reused the code and stripped it down to the necessary pieces and extended it for my needs.

[![Twitter Follow](https://img.shields.io/twitter/follow/lamw?style=social)](https://twitter.com/lamw)

## Overview

This repository contains the necessary code to build a [![Photon OS 3.0](https://img.shields.io/badge/Photon%20OS-3.0-orange)](https://vmware.github.io/photon/) based Kubernetes Appliance by using [Packer](https://learn.hashicorp.com/tutorials/packer/get-started-install-cli). The Kubernetes Appliance can easily be deployed on VMware's Desktop Hypervisor solutions Fusion (Mac/Linux) and Workstaion (Windows) as well as on vSphere.

## :computer: Requirements

**CLI Tools:**

- [VMware ovftool](https://www.vmware.com/support/developer/ovf/)
- [Packer](https://learn.hashicorp.com/tutorials/packer/get-started-install-cli)
- [jq](https://github.com/stedolan/jq/wiki/Installation)
- [PowerShell](https://github.com/PowerShell/PowerShell) - more optional

**Network:**

- DHCP enabled
- SSH enabled
- No network restrictions between the build system (were `packer` is running on) and the VMware ESXi host.
- Packer will create an http server serving `http_directory`
  - Random port used within the range of 8000 and 9000

**ESXi Version**

- ESXi 6.7 or greater
- ! All my tests failed with latest vSphere ESXi 7.0U2a !

## Building the Appliance

1. Clone the repository
`git clone https://github.com/rguske/kubernetes-appliance.git`

2. Change directoy
`cd kubernetes-appliance`
3. Adjust the `photon-builder.json` file with the appropriate ESXi (Build host) data (IP, user, password, datastore, network)
4. If you like to change the versions for e.g. Kubernetes, just modify those via the `k8s-app-bom.json`.
5. Run the `build.sh` script

### Debugging

By putting `PACKER_LOG=1` in front of the `packer build` command in the `build.sh` script, it gives you a very detailed output during the build. Example: `PACKER_LOG=1 packer build -var "APPLIANCE_VERSION=${APPLIANCE_VERSION_FROM_BOM}" [...]` ).

### Output directoy

The finished build `ova` file will be exported to the `output-vmware-iso` directory.