#!/bin/bash
#############################################################################
# Create By: zhf_sy
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################

# sh
#SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd "${SH_PATH}"

# 本地env
GAN_WHAT_FUCK='CA服务器初始化'
NEED_PRIVILEGES='ADMIN'

# 加载公共函数
. "${SH_PATH}/function.sh"


F_HELP()
{
    echo "
    用途：初始化CA服务器环境
    特征码：
        ${GAN_WHAT_FUCK:-'未命名'}
    权限要求：
        ${NEED_PRIVILEGES:-'未指定'}
    依赖：
    注意：清空CA相关数据及颁发的证书及配置文件
    用法：
        $0  -h|--help
        $0  -y|--yes
$(F_HELP_PARAM_SPEC)
    参数说明：
        -h|--help                    此帮助
        -y|--yes                     初始化CA
    示例:
        # 初始化
        $0 -y
    "
}


case $1 in
    -h|--help)
        F_HELP
        shift
        exit
        ;;
    -y|--yes)
        shift
        # OK
        read -p "你正在进行初始化CA证书颁发程序，这将会删除所有CA秘钥及用户证书信息！ 是否键继续(y|n)：" ACK
        if [ "x${ACK}" != 'xy' ]; then
            echo -e "\nOK，已退出！\n"
            exit 1
        fi
        ;;
    *)
        echo -e "参数错误，请查看帮助【$0 -h】"
        exit 1
        ;;
esac


# rm
rm -f  "${CA_DATA_DIR}"/index.txt*
rm -f  "${CA_DATA_DIR}"/serial*
rm -f  "${CA_DATA_DIR}"/crlnumber*

rm -f  "${CA_DATA_DIR}"/ca.pem.*
rm -f  "${CA_DATA_DIR}"/ca.der.*
rm -rf  "${CA_DATA_DIR}"/private/*

rm -rf  "${CA_DATA_DIR}"/newcerts/*
rm -rf  "${CA_DATA_DIR}"/certs/*
rm -rf  "${CA_DATA_DIR}"/crl/*

rm -rf  "${CA_DATA_DIR}"/from_user_csr/*
rm -rf  "${CA_DATA_DIR}"/to_user_crt/*

find  my_conf/*  ! -iname  env.sh* -exec rm -f {} \;


# create dir
mkdir -p "${CA_DATA_DIR}"

mkdir -p "${CA_DATA_DIR}"/private
chmod 700 "${CA_DATA_DIR}"/private

mkdir -p "${CA_DATA_DIR}"/from_user_csr
chmod 700 "${CA_DATA_DIR}"/from_user_csr

mkdir -p "${CA_DATA_DIR}"/newcerts "${CA_DATA_DIR}"/certs "${CA_DATA_DIR}"/crl "${CA_DATA_DIR}"/to_user_crt
chmod 755 "${CA_DATA_DIR}"/newcerts "${CA_DATA_DIR}"/certs "${CA_DATA_DIR}"/crl "${CA_DATA_DIR}"/to_user_crt


# create file
> "${CA_DATA_DIR}"/index.txt
echo "01"  > "${CA_DATA_DIR}"/serial
echo "01"  > "${CA_DATA_DIR}"/crlnumber


echo "OK，初始化已完成！"


