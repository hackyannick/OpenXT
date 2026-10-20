# RTL8111 Ethernet and RTL8822CE Wi-Fi (the 845 G7 ships with either the
# RTL8822CE or an Intel AX200; iwlwifi firmware is already installed).
IMAGE_INSTALL_append = " \
    linux-firmware-rtl8168 \
    linux-firmware-rtl8822 \
"
