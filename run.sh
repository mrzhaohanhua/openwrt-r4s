#!/bin/bash
clear
# 获取openwrt
git clone --depth 1 -b v21.02.2 https://github.com/openwrt/openwrt openwrt
#切换到openwrt目录
cd openwrt 

# 更新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a
./scripts/feeds install -a

# 更换为 ImmortalWrt的target
rm -rf target/linux/rockchip
svn export https://github.com/immortalwrt/immortalwrt/branches/openwrt-21.02/target/linux/rockchip target/linux/rockchip
## 更换target后kmod会有问题
rm -rf package/kernel/linux/modules/video.mk
wget -P package/kernel/linux/modules/ https://github.com/immortalwrt/immortalwrt/raw/openwrt-21.02/package/kernel/linux/modules/video.mk

# 更换为 ImmortalWrt的uboot
# rm -rf package/boot/uboot-rockchip
# svn export https://github.com/immortalwrt/immortalwrt/branches/openwrt-21.02/package/boot/uboot-rockchip package/boot/uboot-rockchip
# svn export https://github.com/immortalwrt/immortalwrt/branches/openwrt-21.02/package/boot/arm-trusted-firmware-rockchip-vendor package/boot/arm-trusted-firmware-rockchip-vendor


