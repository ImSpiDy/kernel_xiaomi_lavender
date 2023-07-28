#!/usr/bin/env bash

 #
 # Script For Building Android Kernel
 #

##----------------------------------------------------------##
# Specify Kernel Directory
KERNEL_DIR="$(pwd)"

# DevUpload
RELEASE=0

# KSU
KSU=1

##----------------------------------------------------------##
# Device Name and Model
MODEL=Xiaomi
DEVICE=Lavender

# Kernel Name and Version
ZIPNAME=S0NiX-CLO
VERSION=v3.0
CLO_TAG=LA.UM.11.2.1.r1-04200

# Kernel Defconfig
DEFCONFIG=lavender_defconfig

if [ "$1" = "--DynEroFs" ]; then
TYPE=-Retro-Erofs
echo "CONFIG_EROFS_FS=y" >> arch/arm64/configs/${DEFCONFIG}
curl https://github.com/ImSpiDy/kernel_xiaomi_lavender-4.19/commit/f75ba0f935858d0d49d91460694ddbcb3cc51e7e.patch | git am
elif [ "$1" = "--DynExt4" ]; then
TYPE=-Retro
MSG=1
elif [ "$1" = "--EroFs" ]; then
TYPE=-EroFs
echo "CONFIG_EROFS_FS=y" >> arch/arm64/configs/${DEFCONFIG}
curl https://github.com/ImSpiDy/kernel_xiaomi_lavender-4.19/commit/b543a58ca9a48b633e84316c661e4751d2d1e307.patch | git am
else
TYPE=""
curl https://github.com/ImSpiDy/kernel_xiaomi_lavender-4.19/commit/b543a58ca9a48b633e84316c661e4751d2d1e307.patch | git am
fi

# Files
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb

# Verbose Build
VERBOSE=0

# Kernel Version
KERVER=$(make kernelversion)

COMMIT_HEAD=$(git log --oneline -1)

# Date and Time
DATE=$(TZ=Asia/Kolkata date +"%Y%m%d-%T")
TANGGAL=$(date +"%F%S")

# Final Zip Name
if [ "$KSU" == 0 ]; then
FINAL_ZIP=${ZIPNAME}-${VERSION}${TYPE}-${DEVICE}-${TANGGAL}.zip
LOCAL_VER=${ZIPNAME}-${VERSION}${TYPE}-${CLO_TAG}
else
FINAL_ZIP=${ZIPNAME}-${VERSION}-KSU${TYPE}-${DEVICE}-${TANGGAL}.zip
LOCAL_VER=${ZIPNAME}-${VERSION}-KSU${TYPE}-${CLO_TAG}
fi

# Update Local Version
echo "CONFIG_LOCALVERSION="-$LOCAL_VER"" >> arch/arm64/configs/${DEFCONFIG}

##----------------------------------------------------------##
# Specify compiler - nexus, proton, azure, aosp
COMPILER=aosp


##----------------------------------------------------------##
# Implement Kernel SU
if [ "$KSU" == 1 ]; then
# Move KSU files to Kernel Dir
cd ..
git clone https://github.com/tiann/KernelSU -b main ksu
mkdir -p project/drivers/KernelSU
cp -r ksu/kernel/* project/drivers/KernelSU
# move KSU Version to Kernel Dir
echo "$(cd ksu && git rev-list --count HEAD)" > ksu_version.txt
KSUV="ccflags-y += -DKSU_VERSION=$(($(cat ksu_version.txt) + 10200))"
echo "$KSUV" >> project/drivers/KernelSU/Makefile
# Apply KernelSU Patches
cd project
git apply patch/KERNELSU.p
echo "CONFIG_KSU=y" >> arch/arm64/configs/${DEFCONFIG}
fi

##----------------------------------------------------------##
# Clone ToolChain
function cloneTC() {
	if [ "$MSG" == "1" ]; then
	post_msg " Cloning $COMPILER Clang ToolChain "
	fi
	if [ $COMPILER = "nexus" ];
	then
	git clone --depth=1 https://gitlab.com/Project-Nexus/nexus-clang.git clang
	PATH="${KERNEL_DIR}/clang/bin:$PATH"
	elif [ $COMPILER = "proton" ];
	then
	git clone --depth=1 https://github.com/kdrag0n/proton-clang.git clang
	PATH="${KERNEL_DIR}/clang/bin:$PATH"
	elif [ $COMPILER = "azure" ];
	then
	git clone --depth=1 https://gitlab.com/Panchajanya1999/azure-clang.git clang
	PATH="${KERNEL_DIR}/clang/bin:$PATH"
	elif [ $COMPILER = "aosp" ];
	then
        mkdir aosp-clang
        cd aosp-clang || exit
	wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/clang-r498229.tar.gz
        tar -xf clang*
        cd .. || exit
	git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git --depth=1 gcc
	git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git  --depth=1 gcc32
	PATH="${KERNEL_DIR}/aosp-clang/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
	fi
        # Clone AnyKernel
        git clone --depth=1 https://github.com/ImSpiDy/AnyKernel3

	}

##------------------------------------------------------##
# Export Variables
function exports() {

        # Export KBUILD_COMPILER_STRING
        if [ -d ${KERNEL_DIR}/clang ];
           then
               export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
        elif [ -d ${KERNEL_DIR}/aosp-clang ];
            then
               export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/aosp-clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
        fi

        # Export ARCH and SUBARCH
        export ARCH=arm64
        export SUBARCH=arm64

        # KBUILD HOST and USER
        export KBUILD_BUILD_HOST=NubXD
        export KBUILD_BUILD_USER="ImSpiDy"

        # CI
        if [ "$CI" ]
           then
           if [ "$CIRCLECI" ]
              then
                  export KBUILD_BUILD_VERSION=${CIRCLE_BUILD_NUM}
                  export CI_BRANCH=${CIRCLE_BRANCH}
           elif [ "$DRONE" ]
	      then
		  export KBUILD_BUILD_VERSION=${DRONE_BUILD_NUMBER}
		  export CI_BRANCH=${DRONE_BRANCH}
           fi
        fi
	export PROCS=$(nproc --all)
	export DISTRO=$(source /etc/os-release && echo "${NAME}")
	}

##----------------------------------------------------------------##
# Telegram Bot Integration

function post_msg() {
	curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
	-d chat_id="$chat_id" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"
	}

function push() {
	curl -F document=@$1 "https://api.telegram.org/bot$token/sendDocument" \
	-F chat_id="$chat_id" \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2"
	}
##----------------------------------------------------------##
# Compilation
function compile() {
START=$(date +"%s")
	# Push Notification
	if [ "$MSG" == "1" ]; then
		post_msg "<b>$KBUILD_BUILD_VERSION CI Build Triggered</b>%0A<b>Docker OS: </b><code>$DISTRO</code>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Asia/Kolkata date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Pipeline Host : </b><code>$KBUILD_BUILD_HOST</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0A<b>Branch : </b><code>$CI_BRANCH</code>%0A<b>Top Commit : </b><a href='$DRONE_COMMIT_LINK'>$COMMIT_HEAD</a>"
	fi

	# Compile
	make O=out CC=clang ARCH=arm64 ${DEFCONFIG}
	if [ -d ${KERNEL_DIR}/clang ];
	   then
	       make -kj$(nproc --all) O=out \
	       ARCH=arm64 \
		   CC=clang \
	       CROSS_COMPILE=aarch64-linux-gnu- \
	       CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
	       V=$VERBOSE 2>&1 | tee error.log
        elif [ -d ${KERNEL_DIR}/aosp-clang ];
           then
               make -kj$(nproc --all) O=out \
	       ARCH=arm64 \
	       LLVM=1 \
	       LLVM_IAS=1 \
	       CLANG_TRIPLE=aarch64-linux-gnu- \
	       CROSS_COMPILE=aarch64-linux-android- \
	       CROSS_COMPILE_COMPAT=arm-linux-androideabi- \
	       V=$VERBOSE 2>&1 | tee error.log
	fi
	
	# Verify Files
	if ! [ -a "$IMAGE" ];
	   then
	       push "error.log" "Build Throws Errors"
	       exit 1
	   else
	       post_msg " ${TYPE} Kernel Compilation Finished. Started Zipping "
	fi
	}

##----------------------------------------------------------------##
function zipping() {
	# Copy Files To AnyKernel3 Zip
	cp $IMAGE AnyKernel3
	
	# Zipping and Push Kernel
	cd AnyKernel3 || exit 1
        zip -r9 ${FINAL_ZIP} *
        MD5CHECK=$(md5sum "$FINAL_ZIP" | cut -d' ' -f1)
        push "$FINAL_ZIP" "Build took : $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) | For <b>$MODEL ($DEVICE)</b> | <b>${KBUILD_COMPILER_STRING}</b> | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
	if [ "$RELEASE" == "1" ]; then
	bash <(curl -s https://devuploads.com/upload.sh) -f "$FINAL_ZIP" -k $du_key
	fi
        cd ..
        }
    
##----------------------------------------------------------##

cloneTC
exports
compile
END=$(date +"%s")
DIFF=$(($END - $START))
zipping

##----------------*****-----------------------------##
