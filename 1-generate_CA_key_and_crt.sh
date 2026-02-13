#!/bin/bash
#############################################################################
# Create By: zhf_sy
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################



# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd "${SH_PATH}"

# 本地env
GAN_WHAT_FUCK='生成CA密钥和证书'
NEED_PRIVILEGES='ADMIN'



F_HELP()
{
    echo "
    用途：生成CA服务器私钥与证书
    特征码：
        ${GAN_WHAT_FUCK:-'未命名'}
    权限要求：
        ${NEED_PRIVILEGES:-'未指定'}
    依赖：
        ./function.sh
        ./my_conf/env.sh--CA     #--- 此文件须自行基于【./my_conf/env.sh--CA.sample】创建
    注意：如果证书已存在，将会跳过
    用法：
        $0  -h|--help
        $0  -y|--yes
    参数规范：
        无包围符号 ：-a                : 必选【选项】
                   ：val               : 必选【参数值】
                   ：val1 val2 -a -b   : 必选【选项或参数值】，且不分先后顺序
        []         ：[-a]              : 可选【选项】
                   ：[val]             : 可选【参数值】
        <>         ：<val>             : 需替换的具体值（用户必须提供）
        %%         ：%val%             : 通配符（包含匹配，如%error%匹配error_code）
        |          ：val1|val2|<valn>  : 多选一
        {}         ：{-a <val>}        : 必须成组出现【选项+参数值】，且保持顺序
                   ：{val1 val2}       : 必须成组的【参数值组合】，且必须按顺序提供
    参数说明：
        -h|--help      此帮助
        -y|--yes       生成CA及证书
    示例:
        # 生成CA及证书
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
        # GO
        ;;
    *)
        echo -e "参数错误，请查看帮助【$0 -h】"
        exit 1
        ;;
esac


# env
NAME='CA'
#
if [ -f "${SH_PATH}/my_conf/env.sh--${NAME}" ]; then
    . "${SH_PATH}/my_conf/env.sh--${NAME}"
    . ./function.sh
    F_CHECK_OPENSSL
else
    echo -e "\n峰哥说：环境参数文件【${SH_PATH}/my_conf/env.sh--${NAME}】未找到，请基于【${SH_PATH}/my_conf/env.sh--model】创建！\n"
    exit 1
fi
# 生成秘钥用法变量
F_CERT_USE_FOR_VAR
if [ $? -ne 0 ]; then
    echo -e "\n峰哥说：配置文件【${SH_PATH}/my_conf/env.sh--${NAME}】中的参数【CERT_USE_FOR】设置错误，请检查\n"
    exit 1
fi


# cnf
F_ECHO_OPENSSL_CNF > "${SH_PATH}/my_conf/openssl.cnf--${NAME}"
# keyUsage
sed -i "/^# keyUsage = 用逗号分隔/a\keyUsage = ${MY_KEY_USAGE_S}"  "${SH_PATH}/my_conf/openssl.cnf--${NAME}"
# extendedKeyUsage
if [ -n "${MY_EXTENDED_KEY_USAGE_S}" ]; then
    sed -i "/^# extendedKeyUsage = 用逗号分隔/a\extendedKeyUsage = ${MY_EXTENDED_KEY_USAGE_S}"  "${SH_PATH}/my_conf/openssl.cnf--${NAME}"
fi
# CA:TRUE
if [ "${CERT_USE_FOR}" = '1' -o "${CERT_USE_FOR}" = 'ca' ]; then
    sed -i 's/CA:FALSE/CA:TRUE/'  "${SH_PATH}/my_conf/openssl.cnf--${NAME}"
fi


#
echo    "在自签名证书的生成过程中，会以交互的方式进行，请根据提示填写你的CA相关信息"
read -p "是否键继续(y|n)：" ACK
if [ "x${ACK}" != 'xy' ]; then
    echo -e "\nOK，已退出！\n"
    exit 1
fi


# 私钥
if [ -f private/ca.pem.key ]; then
    echo "CA私钥已存在，跳过！"
    echo "    【${SH_PATH}/private/ca.pem.key】"
else
    openssl genrsa -out private/ca.pem.key ${PRIVATEKEY_BITS}
    chmod 600 private/ca.pem.key
fi


# csr
openssl req -new  \
    -key private/ca.pem.key  \
    -out ca.pem.csr  \
    -config  "${SH_PATH}/my_conf/openssl.cnf--${NAME}"

if [ ! -f ca.pem.csr ]; then
    echo -e "\n峰哥说：CA证书请求文件生成失败，请检查错误信息\n"
    exit 1
fi


# 证书
if [ -f ca.pem.crt ]; then
    echo "CA证书已存在，跳过！"
    echo "    【${SH_PATH}/ca.pem.crt】"
else
    openssl x509 -days ${CERT_DAYS}  \
        -req  -in ca.pem.csr  \
        -signkey private/ca.pem.key  \
        -out ca.pem.crt  \
        -extfile "${SH_PATH}/my_conf/openssl.cnf--${NAME}"  \
        -extensions v3_req
    echo "OK，CA私钥与证书已经生成："
    echo "    私钥：【${SH_PATH}/private/ca.pem.key】"
    echo "    证书：【${SH_PATH}/ca.pem.crt】"
    openssl x509  -outform der  -in ca.pem.crt  -out ca.der.crt
    echo "    二进制证书：【${SH_PATH}/ca.der.crt】"
fi



