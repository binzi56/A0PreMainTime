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
SIMULATOR_DIR_A=${build_DIR}/${BUILD_MODE}-iphonesimulator/${TARGET_NAME}.framework/${TARGET_NAME}
echo "SIMULATOR_DIR_A=${SIMULATOR_DIR_A}"

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


#build之前clean一下
xcodebuild -target ${TARGET_NAME} clean
#模拟器build
xcodebuild -target ${TARGET_NAME} -configuration ${BUILD_MODE} -sdk iphonesimulator
#真机build
xcodebuild -target ${TARGET_NAME} -configuration ${BUILD_MODE} -sdk iphoneos

#复制framework到目标文件夹
cp -R "${DEVICE_A}" "${INSTALL_DIR}"

#判断可执行文件是否存在，存在则删除该文件
if [ -f "${INSTALL_DIR_A}" ]
then
rm -rf "${INSTALL_DIR_A}"
fi

#合成模拟器和真机.framework包
lipo -create "${DEVICE_DIR_A}" "${SIMULATOR_DIR_A}" -output "${INSTALL_DIR_A}"
#打开目标文件夹
#open "${INSTALL_DIR}"

echo '**************** AutoTimeBuild End *************'

#判断build文件夹是否存在，存在则删除
if [ -d "${build_DIR}" ]
then
rm -rf "${build_DIR}"
fi
