#!/bin/bash
#############################################################################
# Create By: zhf_sy
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################



# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}


# env
PRIVATEKEY_BITS=4096
CERT_DAYS=3650


F_HELP()
{
    echo "
    用途：生成CA服务器私钥与证书
    依赖：
    注意：如果证书已存在，将会跳过
    用法：
        $0  <-h|--help>
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help      此帮助
    示例:
        # 初始化
        $0
    "
}


case $1 in
    -h|--help)
        F_HELP
        shift
        exit
        ;;
    *)
        echo -e "参数错误，请查看帮助【$0 -h】"
        exit 1
        ;;
esac


#
echo    "在自签名证书的生成过程中，会以交互的方式进行，请根据提示填写你的CA相关信息"
read -p "是否键继续(y|n)：" ACK
if [ "x${ACK}" != 'xy' ]; then
    echo -e "\nOK，已退出！\n"
    exit 1
fi


# 私钥
if [ -f private/ca.key.pem ]; then
    echo "CA私钥已存在，跳过！"
    echo "    【${SH_PATH}/private/ca.key.pem】"
else
    openssl genrsa -out private/ca.key.pem ${PRIVATEKEY_BITS}
fi


# csr
openssl req -new  -key private/ca.key.pem  -out ca.csr.pem


# 证书
if [ -f ca.csr.pem ]; then
    echo "CA证书已存在，跳过！"
    echo "    【${SH_PATH}/ca.csr.pem】"
else
    openssl x509 -days ${CERT_DAYS} -req  -in ca.csr.pem  -signkey private/ca.key.pem  -out ca.crt.pem
    echo "OK，CA私钥与证书已经生成："
    echo "    私钥：【${SH_PATH}/private/ca.key.pem】"
    echo "    证书：【${SH_PATH}/ca.csr.pem】"
fi



