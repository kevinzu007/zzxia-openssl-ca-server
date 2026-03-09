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
GAN_WHAT_FUCK='生成CRL吊销列表'
NEED_PRIVILEGES='ADMIN'

# 加载公共函数
. "${SH_PATH}/function.sh"

F_HELP()
{
    echo "
    用途：生成或更新CA吊销列表(CRL)
    特征码：
        ${GAN_WHAT_FUCK:-'未命名'}
    权限要求：
        ${NEED_PRIVILEGES:-'未指定'}
    依赖：
        ./function.sh
        ./my_conf/env.sh--CA
    注意：
    用法：
        $0  -h|--help
        $0  -y|--yes
$(F_HELP_PARAM_SPEC)
    参数说明：
        -h|--help                    此帮助
        -y|--yes                     确认生成CRL
    示例:
        $0 -y
    "
}

case $1 in
    -h|--help)
        F_HELP
        exit
        ;;
    -y|--yes)
        # GO
        ;;
    *)
        echo -e "参数错误，请查看帮助【$0 -h】"
        exit 1
        ;;
esac


# env
NAME='CA'
if [ -f "${SH_PATH}/my_conf/env.sh--${NAME}" ]; then
    . "${SH_PATH}/my_conf/env.sh--${NAME}"
    F_CHECK_OPENSSL
else
    echo -e "\n峰哥说：环境参数文件【${SH_PATH}/my_conf/env.sh--${NAME}】未找到！\n"
    exit 1
fi

# check crlnumber
if [ ! -f "${SH_PATH}/crlnumber" ]; then
     echo -e "\n峰哥说：文件【${SH_PATH}/crlnumber】未找到，请先运行【./0-init_ca.sh】进行初始化！\n"
     exit 1
fi

# cnf
# 生成CA秘钥用法变量
F_CERT_USE_FOR_VAR  "${CERT_USE_FOR}"
if [ $? -ne 0 ]; then
    echo -e "\n峰哥说：配置文件【${SH_PATH}/my_conf/env.sh--${NAME}】中的参数【CERT_USE_FOR】设置错误，请检查\n"
    exit 1
fi
F_GENERATE_OPENSSL_CNF "${NAME}"

# CRL
echo -e "\n正在生成CRL吊销列表..."
openssl ca -gencrl -out "${SH_PATH}/crl/ca.crl.pem" -config "${SH_PATH}/my_conf/openssl.cnf--${NAME}"

if [ $? -eq 0 ]; then
    # DER format
    openssl crl -inform PEM -outform DER -in "${SH_PATH}/crl/ca.crl.pem" -out "${SH_PATH}/crl/ca.crl.der"
    
    echo -e "\n成功：CRL吊销列表已更新！"
    echo "    PEM格式：【${SH_PATH}/crl/ca.crl.pem】"
    echo "    DER格式：【${SH_PATH}/crl/ca.crl.der】"
    
    # Show info
    echo -e "\nCRL详情："
    openssl crl -in "${SH_PATH}/crl/ca.crl.pem" -noout -text
else
    echo -e "\n失败：CRL生成失败，请检查错误信息。"
    exit 1
fi
