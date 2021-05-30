#!/bin/bash


# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}


# env
PRIVATEKEY_BITS=4096
CERT_DAYS=3650



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



