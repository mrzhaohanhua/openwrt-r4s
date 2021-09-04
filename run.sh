#!/bin/bash
clear

#获取openwrt
git clone --depth 1 -b v21.02.0 https://github.com/openwrt/openwrt openwrt
#切换到openwrt目录
cd openwrt 

#以下代码参考QiuSimons的script

# 使用 O3 级别的优化
sed -i 's/Os/O3/g' include/target.mk
# 更新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 默认开启 Irqbalance
sed -i "s/enabled '0'/enabled '1'/g" feeds/packages/utils/irqbalance/files/irqbalance.config

# 移除 SNAPSHOT 标签
sed -i 's,-SNAPSHOT,,g' include/version.mk
sed -i 's,-SNAPSHOT,,g' package/base-files/image-config.in

# R8168驱动
#svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/kernel/r8168 package/new/r8168
git clone -b master --depth 1 https://github.com/BROBIRD/openwrt-r8168.git package/extra/r8168
#patch -p1 < ../PATCH/r8168/r8168-fix_LAN_led-for_r4s-from_TL.patch

# UPX 可执行软件压缩
sed -i '/patchelf pkgconf/i\tools-y += ucl upx' ./tools/Makefile
sed -i '\/autoconf\/compile :=/i\$(curdir)/upx/compile := $(curdir)/ucl/compile' ./tools/Makefile
svn co https://github.com/immortalwrt/immortalwrt/branches/master/tools/upx tools/upx
svn co https://github.com/immortalwrt/immortalwrt/branches/master/tools/ucl tools/ucl

# 更换为 ImmortalWrt Uboot 以及 Target
rm -rf ./target/linux/rockchip
svn co https://github.com/immortalwrt/immortalwrt/branches/master/target/linux/rockchip target/linux/rockchip
rm -rf ./package/boot/uboot-rockchip
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/boot/uboot-rockchip package/boot/uboot-rockchip
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/boot/arm-trusted-firmware-rockchip-vendor package/boot/arm-trusted-firmware-rockchip-vendor

# IRQ 调优
sed -i '/set_interface_core 20 "eth1"/a\set_interface_core 8 "ff3c0000" "ff3c0000.i2c"' target/linux/rockchip/armv8/base-files/etc/hotplug.d/net/40-net-smp-affinity
sed -i '/set_interface_core 20 "eth1"/a\ethtool -C eth0 rx-usecs 1000 rx-frames 25 tx-usecs 100 tx-frames 25' target/linux/rockchip/armv8/base-files/etc/hotplug.d/net/40-net-smp-affinity

# 添加 R4S GPU 驱动
rm -rf ./package/kernel/linux/modules/video.mk
wget -P package/kernel/linux/modules/ https://github.com/immortalwrt/immortalwrt/raw/master/package/kernel/linux/modules/video.mk

# 内核加解密模块
echo '
CONFIG_ARM64_CRYPTO=y
CONFIG_CRYPTO_SHA256_ARM64=y
CONFIG_CRYPTO_SHA512_ARM64=y
CONFIG_CRYPTO_SHA1_ARM64_CE=y
CONFIG_CRYPTO_SHA2_ARM64_CE=y
# CONFIG_CRYPTO_SHA512_ARM64_CE is not set
CONFIG_CRYPTO_SHA3_ARM64=y
CONFIG_CRYPTO_SM3_ARM64_CE=y
CONFIG_CRYPTO_SM4_ARM64_CE=y
CONFIG_CRYPTO_GHASH_ARM64_CE=y
# CONFIG_CRYPTO_CRCT10DIF_ARM64_CE is not set
CONFIG_CRYPTO_AES_ARM64=y
CONFIG_CRYPTO_AES_ARM64_CE=y
CONFIG_CRYPTO_AES_ARM64_CE_CCM=y
CONFIG_CRYPTO_AES_ARM64_CE_BLK=y
CONFIG_CRYPTO_AES_ARM64_NEON_BLK=y
CONFIG_CRYPTO_CHACHA20_NEON=y
CONFIG_CRYPTO_POLY1305_NEON=y
CONFIG_CRYPTO_NHPOLY1305_NEON=y
CONFIG_CRYPTO_AES_ARM64_BS=y
' >> ./target/linux/rockchip/armv8/config-5.4

#Vermagic
latest_version="$(curl -s https://github.com/openwrt/openwrt/releases |grep -Eo "v[0-9\.]+\-*r*c*[0-9]*.tar.gz" |sed -n '/21/p' |sed -n 1p |sed 's/v//g' |sed 's/.tar.gz//g')"
wget https://downloads.openwrt.org/releases/${latest_version}/targets/rockchip/armv8/packages/Packages.gz
zgrep -m 1 "Depends: kernel (=.*)$" Packages.gz | sed -e 's/.*-\(.*\))/\1/' > .vermagic
sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk

### 获取额外的 LuCI 应用、主题和依赖 ###

#AdGuardHome
#cp -rf ../openwrt-lienol/package/diy/luci-app-adguardhome ./package/new/luci-app-adguardhome
svn co https://github.com/Lienol/openwrt/trunk/package/diy/luci-app-adguardhome ./package/extra/luci-app-adguardhome
#删除原feed中的adguardhome
rm -rf ./feeds/packages/net/adguardhome
svn co https://github.com/openwrt/packages/trunk/net/adguardhome feeds/packages/net/adguardhome
sed -i '/\t)/a\\t$(STAGING_DIR_HOST)/bin/upx --lzma --best $(GO_PKG_BUILD_BIN_DIR)/AdGuardHome' ./feeds/packages/net/adguardhome/Makefile
sed -i '/init/d' feeds/packages/net/adguardhome/Makefile

# ChinaDNS
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/chinadns-ng/ package/extra/chinadns-ng

# Passwall
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/luci-app-passwall package/extra/luci-app-passwall
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/ipt2socks package/extra/ipt2socks
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/microsocks package/extra/microsocks
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/dns2socks package/extra/dns2socks
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/naiveproxy package/extra/naiveproxy
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/pdnsd-alt package/extra/pdnsd-alt
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/shadowsocks-rust package/extra/shadowsocks-rust
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/shadowsocksr-libev package/extra/shadowsocksr-libev
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/simple-obfs package/extra/simple-obfs
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/tcping package/extra/tcping
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/trojan-go package/extra/trojan-go
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/brook package/extra/brook
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/trojan-plus package/extra/trojan-plus
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/ssocks package/extra/ssocks
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/xray-core package/extra/xray-core
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/v2ray-plugin package/extra/v2ray-plugin
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/xray-plugin package/extra/xray-plugin
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/hysteria package/extra/hysteria
svn co https://github.com/fw876/helloworld/trunk/v2ray-core package/extra/v2ray-core

# KMS 激活助手
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-vlmcsd package/extra/luci-app-vlmcsd
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/vlmcsd package/extra/vlmcsd

# 最大连接数
sed -i 's/16384/65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf

#convert_translation
po_file="$({ find |grep -E "[a-z0-9]+\.zh\-cn.+po"; } 2>"/dev/null")"
for a in ${po_file}
do
	[ -n "$(grep "Language: zh_CN" "$a")" ] && sed -i "s/Language: zh_CN/Language: zh_Hans/g" "$a"
	po_new_file="$(echo -e "$a"|sed "s/zh-cn/zh_Hans/g")"
	mv "$a" "${po_new_file}" 2>"/dev/null"
done

po_file2="$({ find |grep "/zh-cn/" |grep "\.po"; } 2>"/dev/null")"
for b in ${po_file2}
do
	[ -n "$(grep "Language: zh_CN" "$b")" ] && sed -i "s/Language: zh_CN/Language: zh_Hans/g" "$b"
	po_new_file2="$(echo -e "$b"|sed "s/zh-cn/zh_Hans/g")"
	mv "$b" "${po_new_file2}" 2>"/dev/null"
done

lmo_file="$({ find |grep -E "[a-z0-9]+\.zh_Hans.+lmo"; } 2>"/dev/null")"
for c in ${lmo_file}
do
	lmo_new_file="$(echo -e "$c"|sed "s/zh_Hans/zh-cn/g")"
	mv "$c" "${lmo_new_file}" 2>"/dev/null"
done

lmo_file2="$({ find |grep "/zh_Hans/" |grep "\.lmo"; } 2>"/dev/null")"
for d in ${lmo_file2}
do
	lmo_new_file2="$(echo -e "$d"|sed "s/zh_Hans/zh-cn/g")"
	mv "$d" "${lmo_new_file2}" 2>"/dev/null"
done

po_dir="$({ find |grep "/zh-cn" |sed "/\.po/d" |sed "/\.lmo/d"; } 2>"/dev/null")"
for e in ${po_dir}
do
	po_new_dir="$(echo -e "$e"|sed "s/zh-cn/zh_Hans/g")"
	mv "$e" "${po_new_dir}" 2>"/dev/null"
done

makefile_file="$({ find|grep Makefile |sed "/Makefile./d"; } 2>"/dev/null")"
for f in ${makefile_file}
do
	[ -n "$(grep "zh-cn" "$f")" ] && sed -i "s/zh-cn/zh_Hans/g" "$f"
	[ -n "$(grep "zh_Hans.lmo" "$f")" ] && sed -i "s/zh_Hans.lmo/zh-cn.lmo/g" "$f"
done


# Remove upx commands

makefile_file="$({ find package|grep Makefile |sed "/Makefile./d"; } 2>"/dev/null")"
for a in ${makefile_file}
do
	[ -n "$(grep "upx" "$a")" ] && sed -i "/upx/d" "$a"
done

# Script for creating ACL file for each LuCI APP
bash ../create_acl_for_luci.sh -a
