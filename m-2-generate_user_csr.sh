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
GAN_WHAT_FUCK='生成用户证书请求'
NEED_PRIVILEGES='ADMIN'

# 加载公共函数
. "${SH_PATH}/function.sh"


F_HELP()
{
    echo "
    用途：用于生成用户证书请求
    特征码：
        ${GAN_WHAT_FUCK:-'未命名'}
    权限要求：
        ${NEED_PRIVILEGES:-'未指定'}
    依赖：
        ./function.sh
        ./my_conf/env.sh--\${NAME}      #--- 此文件须自行基于【./my_conf/env.sh--model】创建
    注意：
    用法：
        $0  -h|--help
        $0  {-n|--name <证书相关名称>}  [-q|--quiet]
$(F_HELP_PARAM_SPEC)
    参数说明：
        -h|--help                           此帮助
        -n|--name <证书相关名称>            指定名称，用以确定用户证书相关名称前缀及env、cnf文件名称后缀。
                       即：【私钥、证书请求、证书】的文件名称前缀：test.com.key、test.com.csr、test.com.crt
                           【环境变量、配置】文件名的后缀：env.sh--test.com、openssl.cnf--test.com
        -q|--quiet                          静默方式运行
    示例:
        $0  -n test.com
        $0  -n test.com -q
    "
}



F_GEN_CSR()
{
    # csr
    openssl req -new  -key "${CA_DATA_DIR}/from_user_csr/${NAME}.key"  \
        -out "${CA_DATA_DIR}/from_user_csr/${NAME}.csr"  \
        -config  "${SH_PATH}/my_conf/openssl.cnf--${NAME}"  \
        ${QUIET_OPTION} \
        2>&1  | tee "${TEMP_LOG}"
    
    # 检查是否成功
    if [ ! -f "${CA_DATA_DIR}/from_user_csr/${NAME}.csr" ]; then
        echo -e "\n峰哥说：证书请求生成失败，请检查错误信息\n"
        return 1
    fi
    
    # 查看csr信息
    echo -e "\n证书请求信息如下："
    echo '------------------------------------------------------------'
    openssl req  -in "${CA_DATA_DIR}/from_user_csr/${NAME}.csr"  -noout -text
    echo '------------------------------------------------------------'
    echo -e "\n私钥、证书请求文件路径："
    echo "    私钥：【${CA_DATA_DIR}/from_user_csr/${NAME}.key】"
    echo "    证书请求：【${CA_DATA_DIR}/from_user_csr/${NAME}.csr】"
    return 0
}




TEMP=`getopt -o hn:q  -l help,name:,quiet -- "$@"`
if [ $? != 0 ]; then
    echo -e "\n峰哥说：参数不合法，请查看帮助【$0 --help】\n"
    exit 1
fi
#
eval set -- "${TEMP}"



#
while true
do
    case "$1" in
        -h|--help)
            F_HELP
            exit
            ;;
        -n|--name)
            NAME=$2
            shift 2
            ;;
        -q|--quiet)
            QUIET='yes'
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo -e "\n峰哥说：未知参数，请查看帮助【$0 --help】\n"
            exit 1
            ;;
    esac
done



#
if [ "x${NAME}" = 'x' ]; then
    echo -e "\n峰哥说：参数【-n|--name {证书相关名称}】不能为空或缺失！\n"
    exit 1
fi



# env
if [ -f "${SH_PATH}/my_conf/env.sh--${NAME}" ]; then
    . "${SH_PATH}/my_conf/env.sh--${NAME}"
    F_CHECK_OPENSSL
else
    echo -e "\n峰哥说：环境参数文件【${SH_PATH}/my_conf/env.sh--${NAME}】未找到，请基于【${SH_PATH}/my_conf/env.sh--model】创建！\n"
    exit 1
fi
#
TEMP_LOG=$(mktemp) || exit 1
trap 'rm -f "${TEMP_LOG}"' EXIT

# 生成秘钥用法变量
F_CERT_USE_FOR_VAR  "${CERT_USE_FOR}"
if [ $? -ne 0 ]; then
    echo -e "\n峰哥说：配置文件【${SH_PATH}/my_conf/env.sh--${NAME}】中的参数【CERT_USE_FOR】设置错误，请检查\n"
    exit 1
fi
#
QUIET=${QUIET:-'no'}
# 设置静默选项
if [ "${QUIET}" = 'yes' ]; then
    QUIET_OPTION="-batch"
else
    QUIET_OPTION=""
fi


# cnf
F_GENERATE_OPENSSL_CNF "${NAME}"



#echo    "在生成用户证书请求的过程中，会以交互的方式进行，请根据提示操作！"
#read -p "是否键继续(y|n)：" ACK
#if [ "x${ACK}" != 'xy' ]; then
#    echo -e "\nOK，已退出！\n"
#    exit 1
#fi

# key
if [ ! -f "${CA_DATA_DIR}/from_user_csr/${NAME}.key" ]; then
     echo -e "\n峰哥说：私钥文件【${CA_DATA_DIR}/from_user_csr/${NAME}.key】未找到，请检查！\n"
     exit 1
fi


# csr
F_GEN_CSR



