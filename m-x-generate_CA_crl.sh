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
GAN_WHAT_FUCK='生成CRL吊销列表'
NEED_PRIVILEGES='ADMIN'

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
    . ./function.sh
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
F_ECHO_OPENSSL_CNF > "${SH_PATH}/my_conf/openssl.cnf--${NAME}"
sed -i 's/CA:FALSE/CA:TRUE/'  "${SH_PATH}/my_conf/openssl.cnf--${NAME}"

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
