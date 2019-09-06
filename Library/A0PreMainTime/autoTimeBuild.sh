echo '**************** AutoTimeBuild Start *************' 
#脚本运行当前目录 
CUR_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
echo '***** AutoTimeBuild 当前目录 ---- '$CUR_DIR' *****' 

echo '===== AutoTimeBuild currentProject='$1' ======='

#要build的target名
TARGET_NAME="A0PreMainTime"
echo "target_Name=${TARGET_NAME}"

BUILD_MODE=$1    #release/debug

#工程目录
TARGET_DIR=${CUR_DIR}

#build之后的文件夹路径
build_DIR=${TARGET_DIR}/build
echo "build_DIR=${build_DIR}"

#真机framework
DEVICE_A=${build_DIR}/${BUILD_MODE}-iphoneos/${TARGET_NAME}.framework

#真机build生成的文件路径
DEVICE_DIR_A=${DEVICE_A}/${TARGET_NAME}
echo "DEVICE_DIR_A=${DEVICE_DIR_A}"

#模拟器build生成的.framework文件路径
SIMULATOR_DIR=${build_DIR}/${BUILD_MODE}-iphonesimulator/${TARGET_NAME}.framework
echo "SIMULATOR_DIR=${SIMULATOR_DIR}"

#目标文件夹路径
INSTALL_DIR=${TARGET_DIR}/../../A0PreMainTime/Framework
echo "INSTALL_DIR=${INSTALL_DIR}"

#目标.framework路径
INSTALL_A=${TARGET_DIR}/../../A0PreMainTime/Framework/${TARGET_NAME}.framework
echo "INSTALL_A=${INSTALL_A}"

#可执行文件路径
INSTALL_DIR_A=${INSTALL_A}/${TARGET_NAME}


#判断build文件夹是否存在，存在则删除
if [ -d "${build_DIR}" ]
then
rm -rf "${build_DIR}"
fi

#判断framework是否存在，存在则删除该文件夹
if [ -d "${INSTALL_A}" ]
then
rm -rf "${INSTALL_A}"
fi

#目标文件夹不存在创建目标文件夹
mkdir -p "${INSTALL_DIR}"


if [ -d "${INSTALL_DIR}" ]
then
echo "创建文件夹成功"	
else
echo "创建文件夹失败"	
fi


######################
# Build Frameworks
######################
#build之前clean一下
xcrun xcodebuild -target ${TARGET_NAME} clean
#模拟器build
xcrun xcodebuild BITCODE_GENERATION_MODE=bitcode OTHER_CFLAGS="-fembed-bitcode" -target ${TARGET_NAME} -sdk iphonesimulator -configuration ${BUILD_MODE} ARCHS="i386 x86_64" ONLY_ACTIVE_ARCH=NO build CONFIGURATION_BUILD_DIR=${build_DIR}/${BUILD_MODE}-iphonesimulator
#真机build
xcrun xcodebuild BITCODE_GENERATION_MODE=bitcode OTHER_CFLAGS="-fembed-bitcode" -target ${TARGET_NAME} -sdk iphoneos -configuration ${BUILD_MODE} ARCHS="armv7 armv7s arm64" ONLY_ACTIVE_ARCH=NO build CONFIGURATION_BUILD_DIR=${build_DIR}/${BUILD_MODE}-iphoneos


######################
# Create directory for universal
######################
#复制framework到目标文件夹
cp -R "${DEVICE_A}" "${INSTALL_DIR}"

#判断可执行文件是否存在，存在则删除该文件
if [ -f "${INSTALL_DIR_A}" ]
then
rm -rf "${INSTALL_DIR_A}"
fi

#合成模拟器和真机.framework包
lipo "${DEVICE_DIR_A}" "${SIMULATOR_DIR}/${TARGET_NAME}" -create -output "${INSTALL_DIR_A}" | echo

#For Swift framework, Swiftmodule needs to be copied in the universal framework
if [ -d "${SIMULATOR_DIR}/Modules/${TARGET_NAME}.swiftmodule/" ]; then
cp -f ${SIMULATOR_LIBRARY_PATH}/Modules/${TARGET_NAME}.swiftmodule/* "${INSTALL_A}/Modules/${TARGET_NAME}.swiftmodule/" | echo
fi

if [ -d "${DEVICE_A}/Modules/${TARGET_NAME}.swiftmodule/" ]; then
cp -f ${DEVICE_A}/Modules/${TARGET_NAME}.swiftmodule/* "${INSTALL_A}/Modules/${TARGET_NAME}.swiftmodule/" | echo
fi


#打开目标文件夹
#open "${INSTALL_DIR}"

echo '**************** AutoTimeBuild End *************'

#判断build文件夹是否存在，存在则删除
if [ -d "${build_DIR}" ]
then
rm -rf "${build_DIR}"
fi