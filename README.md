# openwrt-r4s
基于OpenWrt官方v21.02.0代码
参考和使用了QiuSimons的代码，https://github.com/QiuSimons/YAOF
除了OpenWrt官方代码外，增加了passwall、kms激活助手等功能
QiuSimons的对R4S进行了超频，这里没有采用，以降低对电源的要求，可以使用低电流的USB插口。

git clone https://github.com/mrzhaohanhua/openwrt-r4s
cd openwrt-r4s
sh run.sh
cp r4s-config openwrt/.config
cd openwrt
make menuconfig
make download -10 V=s
make -jxx V=s
