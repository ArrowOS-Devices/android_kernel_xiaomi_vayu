#!/bin/bash

kernel_dir="${PWD}"
CCACHE=$(command -v ccache)
objdir="${kernel_dir}/out"
anykernel=$HOME/anykernel
builddir="${kernel_dir}/build"
ZIMAGE=$kernel_dir/out/arch/arm64/boot/Image
kernel_name="Litten-vayu"
zip_name="$kernel_name-$(date +"%d%m%Y-%H%M").zip"
TC_DIR=$HOME/tc/proton-clang
export CONFIG_FILE="vayu_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST=raghavt20
export KBUILD_BUILD_USER=raghav

export PATH="$TC_DIR/bin:$PATH"

if ! [ -d "$TC_DIR" ]; then
echo "Proton Clang not found! Cloning to $TC_DIR..."
if ! git clone -q --depth=1 --single-branch https://github.com/kdrag0n/proton-clang $TC_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

# Colors
NC='\033[0m'
RED='\033[0;31m'
LRD='\033[1;31m'
LGR='\033[1;32m'

make_defconfig()
{
    # Needed to make sure we get dtb built and added to kernel image properly
    START=$(date +"%s")
    echo -e ${LGR} "############### Cleaning ################${NC}"
    rm $anykernel/Image
    rm -rf $ZIMAGE

    echo -e ${LGR} "########### Generating Defconfig ############${NC}"
    make -s ARCH=${ARCH} O=${objdir} ${CONFIG_FILE} -j$(nproc --all)
}
compile()
{
    cd ${kernel_dir}
    echo -e ${LGR} "######### Compiling kernel #########${NC}"
    make -j$(nproc --all) O=out \
                      ARCH=${ARCH}\
                      CC="ccache clang" \
                      CLANG_TRIPLE="aarch64-linux-gnu-" \
                      CROSS_COMPILE="aarch64-linux-gnu-" \
                      CROSS_COMPILE_ARM32="arm-linux-gnueabi-" \
                      -j$(nproc --all)
}

completion()
{
    cd ${objdir}
    COMPILED_IMAGE=arch/arm64/boot/Image
    COMPILED_DTBO=arch/arm64/boot/dtbo.img
    if [[ -f ${COMPILED_IMAGE} && ${COMPILED_DTBO} ]]; then

        git clone -q https://github.com/raghavt20/AnyKernel3 -b vayu $anykernel

        mv -f $ZIMAGE ${COMPILED_DTBO} $anykernel

        cd $anykernel
        find . -name "*.zip" -type f
        find . -name "*.zip" -type f -delete
        zip -r AnyKernel.zip *
        mv AnyKernel.zip $zip_name
        mv $anykernel/$zip_name $HOME/$zip_name
        rm -rf $anykernel
        END=$(date +"%s")
        DIFF=$(($END - $START))
        curl -T $HOME/$zip_name https://oshi.at; echo
        echo -e ${LGR} "############################################"
        echo -e ${LGR} "############# OkThisIsEpic!  ##############"
        echo -e ${LGR} "############################################${NC}"
    else
        echo -e ${RED} "############################################"
        echo -e ${RED} "##         This Is Not Epic :'(           ##"
        echo -e ${RED} "############################################${NC}"
    fi
}
make_defconfig
compile
completion
cd ${kernel_dir}
