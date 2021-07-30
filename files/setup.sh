#!/bin/bash
# Copyright 2019 VMware, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-2

set -euo pipefail

# Extract all OVF Properties
APPLIANCE_DEBUG=$(/root/setup/getOvfProperty.py "guestinfo.debug")
HOSTNAME=$(/root/setup/getOvfProperty.py "guestinfo.hostname")
IP_ADDRESS=$(/root/setup/getOvfProperty.py "guestinfo.ipaddress")
NETMASK=$(/root/setup/getOvfProperty.py "guestinfo.netmask" | awk -F ' ' '{print $1}')
GATEWAY=$(/root/setup/getOvfProperty.py "guestinfo.gateway")
DNS_SERVER=$(/root/setup/getOvfProperty.py "guestinfo.dns")
DNS_DOMAIN=$(/root/setup/getOvfProperty.py "guestinfo.domain")
NTP_SERVER=$(/root/setup/getOvfProperty.py "guestinfo.ntp")
HTTP_PROXY=$(/root/setup/getOvfProperty.py "guestinfo.http_proxy")
HTTPS_PROXY=$(/root/setup/getOvfProperty.py "guestinfo.https_proxy")
PROXY_USERNAME=$(/root/setup/getOvfProperty.py "guestinfo.proxy_username")
PROXY_PASSWORD=$(/root/setup/getOvfProperty.py "guestinfo.proxy_password")
NO_PROXY=$(/root/setup/getOvfProperty.py "guestinfo.no_proxy")
ROOT_PASSWORD=$(/root/setup/getOvfProperty.py "guestinfo.root_password")
ENABLE_SSH=$(/root/setup/getOvfProperty.py "guestinfo.enable_ssh" | tr '[:upper:]' '[:lower:]')
DOCKER_NETWORK_CIDR=$(/root/setup/getOvfProperty.py "guestinfo.docker_network_cidr")
POD_NETWORK_CIDR=$(/root/setup/getOvfProperty.py "guestinfo.pod_network_cidr")
ENABLE_MONITORING=$(/root/setup/getOvfProperty.py "guestinfo.monitoring" | tr '[:upper:]' '[:lower:]')
SYSLOG_SERVER_HOSTNAME=$(/root/setup/getOvfProperty.py "guestinfo.syslog_server_hostname")
SYSLOG_SERVER_PORT=$(/root/setup/getOvfProperty.py "guestinfo.syslog_server_port")
SYSLOG_SERVER_PROTOCOL=$(/root/setup/getOvfProperty.py "guestinfo.syslog_server_protocol")
SYSLOG_SERVER_FORMAT=$(/root/setup/getOvfProperty.py "guestinfo.syslog_server_format")
LOCAL_STORAGE_DISK="/dev/sdb"
LOCAL_STOARGE_VOLUME_PATH="/data"
export KUBECONFIG="/root/.kube/config"

if [ -e /root/ran_customization ]; then
    exit
else
	APPLIANCE_LOG_FILE=/var/log/bootstrap.log
	if [ ${APPLIANCE_DEBUG} == "True" ]; then
		APPLIANCE_LOG_FILE=/var/log/bootstrap-debug.log
		set -x
		exec 2>> ${APPLIANCE_LOG_FILE}
		echo
        echo "### WARNING -- DEBUG LOG CONTAINS ALL EXECUTED COMMANDS WHICH INCLUDES CREDENTIALS -- WARNING ###"
        echo "### WARNING --             PLEASE REMOVE CREDENTIALS BEFORE SHARING LOG            -- WARNING ###"
        echo
	fi

	echo -e "\e[92mStarting Customization ..." > /dev/console

	echo -e "\e[92mStarting OS Configuration ..." > /dev/console
	. /root/setup/setup-01-os.sh

	echo -e "\e[92mStarting Network Proxy Configuration ..." > /dev/console
	. /root/setup/setup-02-proxy.sh

	echo -e "\e[92mStarting Network Configuration ..." > /dev/console
	. /root/setup/setup-03-network.sh

	echo -e "\e[92mStarting Kubernetes Configuration ..." > /dev/console
	. /root/setup/setup-04-kubernetes.sh

	echo -e "\e[92mStarting cAdvisor Configuration ..." > /dev/console
	. /root/setup/setup-05-cadvisor.sh

	echo -e "\e[92mStarting TinyWWW Configuration ..." > /dev/console
	. /root/setup/setup-06-tinywww.sh

	if [ -n "${SYSLOG_SERVER_HOSTNAME}" ]; then
	echo -e "\e[92mStarting FluentBit Configuration ..." > /dev/console
	. /root/setup/setup-07-fluentbit.sh
	fi

	echo -e "\e[92mCustomization Completed ..." > /dev/console

	# Clear guestinfo.ovfEnv
	vmtoolsd --cmd "info-set guestinfo.ovfEnv NULL"

	# Ensure we don't run customization again
	touch /root/ran_customization
fi