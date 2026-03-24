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
GAN_WHAT_FUCK='生成用户密钥与证书'
NEED_PRIVILEGES='ADMIN'

# 加载公共函数
. "${SH_PATH}/function.sh"


F_HELP()
{
    echo "
    用途：用于生成用户秘钥与证书
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
        $0  {-n|--name <证书相关名称>}  [{-p|--privatekey-bits <私钥长度>}]  [{-c|--cert-bits <证书长度>}]  [{-d|--days <证书有效天数>}]  [-q|--quiet]
$(F_HELP_PARAM_SPEC)
    参数说明：
        -h|--help                           此帮助
        -n|--name <证书相关名称>            指定名称，用以确定用户证书相关名称前缀及env、cnf文件名称后缀。
                       即：【私钥、证书请求、证书】的文件名称前缀：test.com.key、test.com.csr、test.com.crt
                           【环境变量、配置】文件名的后缀：env.sh--test.com、openssl.cnf--test.com
        -p|--privatekey-bits <私钥长度>     私钥长度，默认2048
        -c|--cert-bits <证书长度>           证书长度，默认2048
        -d|--days <证书有效天数>            证书有效期，默认365天
        -q|--quiet                          静默方式运行
    示例:
        $0  -n test.com
        #
        $0  -n test.com  -d 730
        $0  -n test.com  -p 4096
        $0  -n test.com  -p 4096  -c 2048  -d 730
        $0  -n test.com  -q
    "
}



F_GEN_KEY_AND_CRT()
{
    # key
    if [ -f "${CA_DATA_DIR}/from_user_csr/${NAME}.key" ]; then
        echo -e "\n注意：私钥【${CA_DATA_DIR}/from_user_csr/${NAME}.key】已存在，将使用此私钥\n"
    else
        openssl genrsa -out "${CA_DATA_DIR}/from_user_csr/${NAME}.key"  ${PRIVATEKEY_BITS}
        chmod 600 "${CA_DATA_DIR}/from_user_csr/${NAME}.key"
    fi
    
    # csr
    openssl req -new  -key "${CA_DATA_DIR}/from_user_csr/${NAME}.key"  \
        -out "${CA_DATA_DIR}/from_user_csr/${NAME}.csr"  \
        -config  "${SH_PATH}/my_conf/openssl.cnf--${NAME}"  \
        ${QUIET_OPTION} \
        2>&1  |  tee "${TEMP_CSR_LOG}"
    
    # 检查CSR是否生成成功
    if [ ! -f "${CA_DATA_DIR}/from_user_csr/${NAME}.csr" ]; then
        echo -e "\n峰哥说：证书请求生成失败，请检查错误信息\n"
        return 1
    fi
    
    # 查看csr信息
    echo -e "\n证书请求信息如下："
    echo '------------------------------------------------------------'
    openssl req  -in "${CA_DATA_DIR}/from_user_csr/${NAME}.csr"  -noout -text
    echo '------------------------------------------------------------'
    
    # crt
    openssl ca  -in "${CA_DATA_DIR}/from_user_csr/${NAME}.csr"  \
        -out "${CA_DATA_DIR}/to_user_crt/${NAME}.crt"  \
        -config "${SH_PATH}/my_conf/openssl.cnf--${NAME}"  \
        -extensions ${EXTENSIONS_SECTION}  \
        ${QUIET_OPTION} \
        2>&1  |  tee "${TEMP_CRT_LOG}"
    
    # 检查证书是否生成成功
    if [ ! -f "${CA_DATA_DIR}/to_user_crt/${NAME}.crt" ]; then
        echo -e "\n峰哥说：证书生成失败，请检查错误信息\n"
        return 1
    fi
    
    # 检查日志中是否有成功信息
    if ! grep -q 'Data Base Updated' "${TEMP_CRT_LOG}"; then
        echo -e "\n峰哥说：证书生成可能有问题，请检查日志\n"
    fi
    
    # 查看crt信息
    echo -e "\n证书签名详情如下："
    echo '------------------------------------------------------------'
    openssl x509  -in "${CA_DATA_DIR}/to_user_crt/${NAME}.crt"  -noout -text
    echo '------------------------------------------------------------'
    echo -e "\n秘钥、证书文件路径："
    echo "    私钥：【${CA_DATA_DIR}/from_user_csr/${NAME}.key】"
    echo "    证书：【${CA_DATA_DIR}/to_user_crt/${NAME}.crt】"
    return 0
}




TEMP=`getopt -o hn:p:c:d:q  -l help,name:,privatekey-bits:,cert-bits:,days:,quiet -- "$@"`
if [ $? != 0 ]; then
    echo -e "\n峰哥说：参数不合法，请查看帮助【$0 --help】\n"
    exit 1
fi
#
eval set -- "${TEMP}"



while true
do
    case "$1" in
        -h|--help)
            shift
            F_HELP
            exit
            ;;
        -p|--privatekey-bits)
            PRIVATEKEY_BITS=$2
            shift 2
            #
            if [[ ! ${PRIVATEKEY_BITS} =~ ^[1-9][0-9]*$ ]]; then
                echo -e "\n峰哥说：参数值【-p|--privatekey-bits】必须为正整数！\n"
                exit 1
            fi
            #
            let X=${PRIVATEKEY_BITS}%1024
            if [ $X -ne 0 ]; then
                echo -e "\n峰哥说：私钥长度必须是1024的整数倍！\n"
                exit 1
            fi
            ;;
        -c|--cert-bits)
            CERT_BITS=$2
            shift 2
            #
            if [[ ! ${CERT_BITS} =~ ^[1-9][0-9]*$ ]]; then
                echo -e "\n峰哥说：参数值【-c|--cert-bits】必须为正整数！\n"
                exit 1
            fi
            #
            let X=${CERT_BITS}%1024
            if [ $X -ne 0 ]; then
                echo -e "\n峰哥说：证书长度必须是1024的整数倍！\n"
                exit 1
            fi
            ;;
        -d|--days)
            CERT_DAYS=$2
            shift 2
            if [[ ! ${CERT_DAYS} =~ ^[1-9]+[0-9]*$ ]]; then
                echo -e "\n峰哥说：证书有效天数必须为整数！\n"
                exit 1
            fi
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


# name
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
TEMP_CSR_LOG=$(mktemp) || exit 1
TEMP_CRT_LOG=$(mktemp) || exit 1
trap 'rm -f "${TEMP_CSR_LOG}" "${TEMP_CRT_LOG}"' EXIT
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

# 根据证书类型选择扩展段：CA/sub-CA 使用 v3_ca，其他使用 v3_req
if [ "${CERT_USE_FOR}" = '1' -o "${CERT_USE_FOR}" = 'ca' ]; then
    EXTENSIONS_SECTION='v3_ca'
else
    EXTENSIONS_SECTION='usr_cert'
fi


# cnf
F_GENERATE_OPENSSL_CNF "${NAME}"


## 交互
#echo    "在生成用户证书请求的过程中，会以交互的方式进行，请根据提示操作！"
#read -p "是否键继续(y|n)：" ACK
#if [ "x${ACK}" != 'xy' ]; then
#    echo -e "\nOK，已退出！\n"
#    exit 1
#fi


# gen
F_GEN_KEY_AND_CRT


