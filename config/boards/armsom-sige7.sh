# shellcheck shell=bash

export BOARD_NAME="ArmSoM Sige7"
export BOARD_MAKER="ArmSoM"
export BOARD_SOC="Rockchip RK3588"
export BOARD_CPU="ARM Cortex A76 / A55"
export UBOOT_PACKAGE="u-boot-radxa-rk3588"
export UBOOT_RULES_TARGET="armsom-sige7-rk3588"
export COMPATIBLE_SUITES=("jammy" "noble")
export COMPATIBLE_FLAVORS=("server" "desktop")

function config_image_hook__armsom-sige7() {
    local rootfs="$1"
    local overlay="$2"
    local suite="$3"

    if [ "${suite}" == "jammy" ] || [ "${suite}" == "noble" ]; then
        # Install panfork
        chroot "${rootfs}" add-apt-repository -y ppa:jjriek/panfork-mesa
        chroot "${rootfs}" apt-get update
        chroot "${rootfs}" apt-get -y install mali-g610-firmware
        chroot "${rootfs}" apt-get -y dist-upgrade

        # Install libmali blobs alongside panfork
        chroot "${rootfs}" apt-get -y install libmali-g610-x11

        # Install the rockchip camera engine
        chroot "${rootfs}" apt-get -y install camera-engine-rkaiq-rk3588

        # Enable bluetooth for AP6275P
        mkdir -p "${rootfs}/usr/lib/scripts"
        cp "${overlay}/usr/lib/systemd/system/ap6275p-bluetooth.service" "${rootfs}/usr/lib/systemd/system/ap6275p-bluetooth.service"
        cp "${overlay}/usr/lib/scripts/ap6275p-bluetooth.sh" "${rootfs}/usr/lib/scripts/ap6275p-bluetooth.sh"
        cp "${overlay}/usr/bin/brcm_patchram_plus" "${rootfs}/usr/bin/brcm_patchram_plus"
        sed -i 's/ttyS9/ttyS6/g' "${rootfs}/usr/lib/scripts/ap6275p-bluetooth.sh"
        chroot "${rootfs}" systemctl enable ap6275p-bluetooth

        # Fix and configure audio device
        mkdir -p "${rootfs}/usr/lib/scripts"
        cp "${overlay}/usr/lib/scripts/alsa-audio-config" "${rootfs}/usr/lib/scripts/alsa-audio-config"
        cp "${overlay}/usr/lib/systemd/system/alsa-audio-config.service" "${rootfs}/usr/lib/systemd/system/alsa-audio-config.service"
        chroot "${rootfs}" systemctl enable alsa-audio-config

        # Install development tools
        chroot "${rootfs}" apt-get install -y dpkg-dev debhelper cpio flex bison bc openssl libssl-dev libelf-dev python3

        # Install Docker
        chroot "${rootfs}" apt update
        chroot "${rootfs}" apt install ca-certificates curl
        chroot "${rootfs}" install -m 0755 -d /etc/apt/keyrings
        chroot "${rootfs}" curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        chroot "${rootfs}" chmod a+r /etc/apt/keyrings/docker.asc

        # Add the repository to Apt sources:
        chroot "${rootfs}" tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

        chroot "${rootfs}" apt update
        chroot "${rootfs}" apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Setup Lockbox Docker Compose
        mkdir -p "${rootfs}/opt/lockbox"
        chroot "${rootfs}" chmod -R 777 "/opt/lockbox"
        cp "${overlay}/opt/lockbox/docker-compose.yaml" "${rootfs}/opt/lockbox/docker-compose.yaml"
        chroot "${rootfs}" chmod -R 777 "/opt/lockbox"

        # Setup Lockbox service
        cp "${overlay}/usr/lib/systemd/system/lockbox.service" "${rootfs}/usr/lib/systemd/system/lockbox.service"
        chroot "${rootfs}" systemctl enable lockbox.service

    fi

    return 0
}
