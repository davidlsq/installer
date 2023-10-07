#!/bin/bash -e

source files/config

if [ "$_NETWORK_MANUAL" == "true" ]; then
cat > "${STAGE_WORK_DIR}/interfaces" <<EOF
auto lo
iface lo inet loopback

auto $_NETWORK_INTERFACE
allow-hotplug $_NETWORK_INTERFACE
iface $_NETWORK_INTERFACE inet static
  address $_NETWORK_MANUAL_ADDRESS
  netmask $_NETWORK_MANUAL_NETMASK
  gateway $_NETWORK_MANUAL_GATEWAY
EOF
echo "$_NETWORK_MANUAL_DNS" | tr ' ' '\n' | awk '{print "nameserver "$1}' \
  > "${STAGE_WORK_DIR}/resolv.conf"
install -m 644 "${STAGE_WORK_DIR}/interfaces" "${ROOTFS_DIR}/etc/network/interfaces"
install -m 644 "${STAGE_WORK_DIR}/resolv.conf" "${ROOTFS_DIR}/etc/resolv.conf"
else
cat > "${STAGE_WORK_DIR}/interfaces" <<EOF
auto lo
iface lo inet loopback

auto $_NETWORK_INTERFACE
allow-hotplug $_NETWORK_INTERFACE
iface $_NETWORK_INTERFACE inet dhcp
EOF
install -m 644 "${STAGE_WORK_DIR}/interfaces" "${ROOTFS_DIR}/etc/network/interfaces"
fi
