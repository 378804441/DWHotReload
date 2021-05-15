#!/usr/bin/env bash

filePath=$1
fileName=$2
simulator=$3
baseFilePath="/Users/dingwei/Desktop/热重载"
tempFilePath=${baseFilePath}"/archiveFile"
dylibFilePath=${baseFilePath}"/dylibs"

# 将改动后的.m文件编译成 .o文件
linkTarget="x86_64-apple-ios10.0-simulator"
linkIsysroot="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator14.0.sdk"

##判断是否是真机
if [ ${simulator} == "phone" ];then
linkTarget="arm64-apple-ios12.0"
linkIsysroot="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS14.0.sdk "
fi

## 将 .m 编译成 .o文件
clang -x objective-c -target ${linkTarget} -fobjc-arc -fmodules  -isysroot ${linkIsysroot} -iquote  /Users/dingwei/Library/Developer/Xcode/DerivedData/DWDebugHR-fahgfhvqgkwjbgdxifevhwtdnpmp/Build/Intermediates.noindex/DWDebugHR.build/Debug-iphonesimulator/DWDebugHR.build/DWDebugHR-project-headers.hmap -c ${filePath} -o ${tempFilePath}/${fileName}.o


# 创建linkFileList文件
dirAndName="$baseFilePath/DWHR.LinkFileList"
if [ ! -d "$baseFilePath" ];then
echo "父级文件夹路径错误"
else
cd $baseFilePath
    # 文件不存在
if [ ! -f "$dirAndName" ];then
echo "文件不存在";
cat>$dirAndName<<EOF
${tempFilePath}/${fileName}.o
EOF
# 文件存在 先删除
else
echo "文件存在";
rm -f $dirAndName
cat>$dirAndName<<EOF
${tempFilePath}/${fileName}.o
EOF
fi
fi

# 链接成一个动态库
ctime=$(date "+%Y%m%d%H%M%S")
clang -x objective-c -target ${linkTarget} -dynamiclib -isysroot ${linkIsysroot} -filelist $dirAndName   -Xlinker -objc_abi_version -Xlinker 2 -fobjc-link-runtime -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __entitlements  -Xlinker ${tempFilePath}/${fileName}.o -o ${dylibFilePath}/dw${ctime}.dylib


# 真机动态库需要进行签名，否则无法dlopen加载成功
if [ ${simulator} == "phone" ];then
codesign -f -s "iPhone Developer: yongwen bai (QZ6P5FP5MA)" ${dylibFilePath}/dw${ctime}.dylib
fi

# 将dylib上传给开启的app

## 如果是模拟器默认获取本机ip
ip=$(/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")

## 真机的话ip需要获取外部指定的手机ip地址
if [ ${simulator} == "phone" ];then
ip=$4
fi

dylibPath='/'${dylibFilePath}'/dw'${ctime}'.dylib'
curl -H "Expect:" -F "file=@"${dylibPath} http://${ip}:8080/upload
#curl -H "Expect:" -F "file=@"${dylibPath} http://192.168.3.145:8080/upload

#上传成功后将dylib 删除掉
rm -r ${dylibPath}
