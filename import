#!/bin/bash
#
# Modified AkiraSuper's Script
#
# Import or update qcacld-3.0, qca-wifi-host-cmn, fw-api , audio-kernel and data-kernel
#

read -p "Please input the tag name: " tag

read -p "Import qcacld-3.0, qca-wifi-host-cmn, fw-api? ( y or n ): "  ans
if [ $ans = "y" ]; then
git subtree add --prefix=drivers/staging/qcacld-3.0 https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/qcacld-3.0 $tag

git subtree add --prefix=drivers/staging/qca-wifi-host-cmn https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/qca-wifi-host-cmn $tag

git subtree add --prefix=drivers/staging/fw-api https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/fw-api $tag
else
echo " Skipped qcacld-3.0, qca-wifi-host-cmn, fw-api"
fi

read -p " Wanna import audio-kernel? ( y or n ): " ans1
if [ $ans1 = "y" ]; then
git subtree add --prefix=techpack/audio https://git.codelinaro.org/clo/la/platform/vendor/opensource/audio-kernel/ $tag
else
echo " Skipped audio-kernel"
fi

read -p " Wanna import data-kernel? ( y or n ): " ans2
if [ $ans2 = "y" ]; then
git subtree add --prefix=techpack/data https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/data-kernel $tag
else
echo " Skipped data-kernel"
fi

read -p " Wanna import Exfat? ( y or n ): " ans3
if [ $ans3 = "y" ]; then
read -p " Linux Version is 4.4 or Below 4.4 ? ( y or n ): " ans4
if [ $ans4 = "y" ]; then
git subtree add --prefix=fs/exfat https://github.com/arter97/exfat-linux old
else
git subtree add --prefix=fs/exfat https://github.com/arter97/exfat-linux master
fi
else
echo " Skipped Exfat Driver"
fi

echo "Done."
