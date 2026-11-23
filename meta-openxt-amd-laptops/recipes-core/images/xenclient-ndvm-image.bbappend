# 845 G7: RTL8111 Ethernet and RTL8822CE Wi-Fi (it ships with either the
# RTL8822CE or an Intel AX200; iwlwifi firmware is already installed).
# Z13 Gen1: Qualcomm WCN6855 Wi-Fi (ath11k).
IMAGE_INSTALL_append = " \
    linux-firmware-rtl8168 \
    linux-firmware-rtl8822 \
    linux-firmware-ath11k \
"
