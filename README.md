# Kubernetes Appliance - VMware OVA

[![Twitter Follow](https://img.shields.io/twitter/follow/vmw_rguske?style=social)](https://twitter.com/vmw_rguske)

:pencil: [My Personal Blog](https://rguske.github.io)

⬇️ [Download Kubernetes-Appliance](https://drive.google.com/file/d/1_TfOYd2_LR6fj6fo_zc511f3WbGurrQs/view?usp=sharing)

## :book: Table of Content

- [Kubernetes Appliance - VMware OVA](#kubernetes-appliance---vmware-ova)
  - [:book: Table of Content](#book-table-of-content)
  - [:raised\_hands: Credits](#raised_hands-credits)
  - [:eyeglasses: Overview](#eyeglasses-overview)
  - [:clipboard: Requirements](#clipboard-requirements)
  - [:man\_cook: Building the Appliance](#man_cook-building-the-appliance)
    - [Debugging](#debugging)
    - [Output directoy](#output-directoy)
  - [:computer: `zsh` installed](#computer-zsh-installed)
  - [Deployment Options Appliance](#deployment-options-appliance)
  - [Join an existing Kubernetes-Appliance](#join-an-existing-kubernetes-appliance)
  - [📋 Change Log](#-change-log)

## :raised_hands: Credits

Credits goes out to [William Lam](https://twitter.com/lamw). The code basis for this project is based on the awesome VMware open-source project [VMware Event Broker Appliance](https://www.vmweventbroker.io). I reused the code and stripped it down to the necessary pieces and adjusted it for my needs.

[![Twitter Follow](https://img.shields.io/twitter/follow/lamw?style=social)](https://twitter.com/lamw)

## :eyeglasses: Overview

This repository contains the necessary code to build a [![Photon OS 4.0](https://img.shields.io/badge/Photon%20OS-4.0-orange)](https://vmware.github.io/photon/) based Kubernetes Appliance.

The Appliance can be quickly deployed on vSphere for testing, development or learning purposes. Perhaps, it serves as the foundation for your project(s) 😉

## :clipboard: Requirements

**CLI Tools:**

- [VMware ovftool](https://www.vmware.com/support/developer/ovf/)
- [Packer](https://learn.hashicorp.com/tutorials/packer/get-started-install-cli)
  - Run `packer init .` to download the [Packer plugin binaries](https://developer.hashicorp.com/packer/docs/commands/init) for vSphere.
- [jq](https://github.com/stedolan/jq/wiki/Installation)
- [PowerShell](https://github.com/PowerShell/PowerShell) - more optional

**Network:**

- DHCP enabled
- SSH enabled (port 22)
- No network restrictions between the build system (were `packer` is running on) and the VMware ESXi host
- Packer will create an http server serving `http_directory`
  - Random port used within the range of 8000 and 9000

**vSphere**

- ESXi 6.7 or greater
- Enable GuestIPHack on the ESXi host before building the appliance: `esxcli system settings advanced set -o /Net/GuestIPHack -i 1`

## :man_cook: Building the Appliance

1. Clone the repository: `git clone git@github.com:rguske/kubernetes-appliance.git`
2. Change into the directoy: `cd kubernetes-appliance`
3. Adjust the `photon-builder.json` file with the appropriate ESXi (build host) data (IP or FQDN, user, password, datastore, network)
4. Execute the `build.sh` script: `./build.sh`

Optional: If you like to change the versions for e.g. Kubernetes or Antrea, modify those in the `k8s-app-bom.json`

### Debugging

The SSH session initiated will be visible in the detail provided when `PACKER_LOG=1` environment variable is set within the `build.sh` script.

Example: `PACKER_LOG=1 packer build -var "K8S_APP_VERSION=${K8S_APP_VERSION_FROM_BOM}" -var-file=photon-builder.json -var-file=photon-version.json photon.json`.

### Output directoy

The finished `ova` file will be exported to the `output-vmware-iso` directory.

## :computer: `zsh` installed

I'm a happy user of [zsh](https://www.zsh.org/) and [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh) and therefore, when connecting to the appliance via `ssh`, you will use a "pimped" shell environment.

<img width="1210" alt="rguske-zsh" src="https://user-images.githubusercontent.com/31652019/156823928-731e50db-b31a-4ce5-ab08-4146438b65fb.png">

## Deployment Options Appliance

![rguske-k8s-app-ova-1](https://user-images.githubusercontent.com/31652019/156720139-afd35002-2156-4f56-8bec-87ad2492fea5.png)

![rguske-k8s-app-ova-2](https://user-images.githubusercontent.com/31652019/156720147-79fe6870-a4a5-4b08-a38c-63361980c982.png)

![rguske-k8s-app-ova-3](https://user-images.githubusercontent.com/31652019/156720148-f4fb1dd0-1543-4322-a4f7-a807254b75bf.png)

## Join an existing Kubernetes-Appliance

In version v0.3.0, the possibility was added to join an existing Kubernetes-Appliance as an additional node.

<img width="1071" alt="screenshot_change_name 2" src="https://user-images.githubusercontent.com/31652019/158141155-5ea9c215-4b0c-496a-8b75-65b90b49a7db.png">

<img width="1496" alt="screenshot_change_name 7" src="https://user-images.githubusercontent.com/31652019/158141194-4578682e-5317-4206-a018-eb46566165a0.png">


## 📋 Change Log

- [2024-06-06] Updated versions to Kubernetes 1.29.2, Antrea to 1.15, etc.
- [2022-03-14] Added option to join an existing K8s Appliance Node (v0.3.0)
- [2022-03-10] Added `local-path-provisioner` (v0.2.1)
- [2022-03-10] Updated to VMware PhotonOS v4 Rev.2 (v0.2.0)
