#!/bin/sh

echo "~~~~~~~~~~~~~~~~开始执行脚本~~~~~~~~~~~~~~~~"


####################################################################
#工程名
PROJECTNAME="xxxxxxx"
#需要编译的 targetName
TARGET_NAME="xxxxxxx"
# ADHOC
#证书名#描述文件
DEVCODE_SIGN_IDENTITY="iPhone Developer: xxxxxxx"
DEVPROVISIONING_PROFILE_NAME="xxxxxxx"

ADHOCCODE_SIGN_IDENTITY="iPhone Distribution: xxxxxxx"
ADHOCPROVISIONING_PROFILE_NAME="xxxxxxx"

#是否是工作空间
ISWORKSPACE=false
####################################################################

#证书名
CODE_SIGN_IDENTITY=${DEV_CODE_SIGN_IDENTITY}
#描述文件
PROVISIONING_PROFILE_NAME=${DEV_PROVISIONING_PROFILE_NAME}

Deployment="development"

echo "~~~~~~~~~~~~~~~~选择打包方式~~~~~~~~~~~~~~~~"
echo "		1 Development (默认)"
echo "		2 Ad Hoc (需要iPhone Distribution证书)"

# 读取用户输入并存到变量里
read parameter
sleep 0.5
method="$parameter"

# 判读用户是否有输入
if [ -n "$method" ]
then
if [ "$method" = "1" ]
then
CODE_SIGN_IDENTITY=${DEVCODE_SIGN_IDENTITY}
PROVISIONING_PROFILE_NAME=${DEVPROVISIONING_PROFILE_NAME}
Deployment="development"
elif [ "$method" = "2" ]
then
CODE_SIGN_IDENTITY=${ADHOCCODE_SIGN_IDENTITY}
PROVISIONING_PROFILE_NAME=${ADHOCPROVISIONING_PROFILE_NAME}
Deployment="ad-hoc"
else
echo "参数无效...."
exit 1
fi
else
Deployment="development"
fi


# 开始时间
beginTime=`date +%s`
DATE=`date '+%Y-%m-%d-%T'`

#编译模式 工程默认有 Debug Release 
CONFIGURATION_TARGET=Release
#编译路径
BUILDPATH=~/Desktop/${TARGET_NAME}_${DATE}
#archivePath
ARCHIVEPATH=${BUILDPATH}/${TARGET_NAME}.xcarchive
#输出的ipa目录
IPAPATH=${BUILDPATH}


echo "~~~~~~~~~~~~~~~~开始编译~~~~~~~~~~~~~~~~~~~"


if [ $ISWORKSPACE = true ]
then
# 清理 避免出现一些莫名的错误
xcodebuild clean -workspace ${PROJECTNAME}.xcworkspace \
-configuration \
${CONFIGURATION} -alltargets

#开始构建
xcodebuild -verbose archive -workspace ${PROJECTNAME}.xcworkspace \
-scheme ${TARGET_NAME} \
-archivePath ${ARCHIVEPATH} \
-configuration ${CONFIGURATION_TARGET} \
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
PROVISIONING_PROFILE="${PROVISIONING_PROFILE_NAME}" || exit
else
# 清理 避免出现一些莫名的错误
xcodebuild clean -project ${PROJECTNAME}.xcodeproj \
-configuration \
${CONFIGURATION} -alltargets

#开始构建
xcodebuild -verbose archive -project ${PROJECTNAME}.xcodeproj \
-scheme ${TARGET_NAME} \
-archivePath ${ARCHIVEPATH} \
-configuration ${CONFIGURATION_TARGET} \
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
PROVISIONING_PROFILE="${PROVISIONING_PROFILE_NAME}" || exit
fi

echo "~~~~~~~~~~~~~~~~检查是否构建成功~~~~~~~~~~~~~~~~~~~"
# xcarchive 实际是一个文件夹不是一个文件所以使用 -d 判断
if [ -d "$ARCHIVEPATH" ]
then
echo "构建成功......"
else
echo "构建失败......"
rm -rf $BUILDPATH
exit 1
fi
endTime=`date +%s`
ArchiveTime="构建时间$[ endTime - beginTime ]秒"


echo "~~~~~~~~~~~~~~~~导出ipa~~~~~~~~~~~~~~~~~~~"

beginTime=`date +%s`

exportOptionsPlist=`mktemp`
cat > $exportOptionsPlist <<EOD
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>method</key>
<string>$Deployment</string>
<key>compileBitcode</key>
<false/>
</dict>
</plist>
EOD

xcodebuild -verbose -exportArchive \
-archivePath ${ARCHIVEPATH} \
-exportOptionsPlist ${exportOptionsPlist} \
-exportPath ${IPAPATH} || exit

rm "$exportOptionsPlist"

echo "~~~~~~~~~~~~~~~~检查是否成功导出ipa~~~~~~~~~~~~~~~~~~~"
IPAPATH=${IPAPATH}/${TARGET_NAME}.ipa
if [ -f "$IPAPATH" ]
then
echo "导出ipa成功......"
open $BUILDPATH
else
echo "导出ipa失败......"
# 结束时间
endTime=`date +%s`
echo "$ArchiveTime"
echo "导出ipa时间$[ endTime - beginTime ]秒"
exit 1
fi

endTime=`date +%s`
ExportTime="导出ipa时间$[ endTime - beginTime ]秒"


echo "~~~~~~~~~~~~~~~~配置信息~~~~~~~~~~~~~~~~~~~"
echo "开始执行脚本时间: ${DATE}"
echo "编译模式: ${CONFIGURATION_TARGET}"
echo "打包文件路径: ${ARCHIVEPATH}"
echo "打包类别: ${Deployment}"
echo "导出ipa路径: ${IPAPATH}"

echo "$ArchiveTime"
echo "$ExportTime"

exit 0

