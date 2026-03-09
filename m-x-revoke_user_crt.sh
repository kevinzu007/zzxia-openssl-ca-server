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
GAN_WHAT_FUCK='吊销用户证书'
NEED_PRIVILEGES='ADMIN'

# 加载公共函数
. "${SH_PATH}/function.sh"


F_HELP()
{
    echo "
    用途：吊销已颁发的用户证书
    特征码：
        ${GAN_WHAT_FUCK:-'未命名'}
    权限要求：
        ${NEED_PRIVILEGES:-'未指定'}
    依赖：
        ./function.sh
        ./my_conf/env.sh--CA
    注意：
        吊销后请记得更新CRL吊销列表（m-x-generate_CA_crl.sh）
    用法：
        $0  -h|--help
        $0  {-n|--name <证书名称>}
$(F_HELP_PARAM_SPEC)
    参数说明：
        -h|--help                    此帮助
        -n|--name <证书名称>         指定要吊销的证书名称（不含路径和后缀）
                       例如：test.com (将在这个路径寻找：to_user_crt/test.com.crt)
    示例:
        $0 -n test.com
    "
}



TEMP=`getopt -o hn:  -l help,name: -- "$@"`
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
            F_HELP
            exit
            ;;
        -n|--name)
            NAME=$2
            shift 2
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


# check
if [ -z "${NAME}" ]; then
    echo -e "\n峰哥说：参数【-n|--name】不能为空！\n"
    exit 1
fi


# env (使用CA的配置，因为是CA在操作)
CA_NAME='CA'
if [ -f "${SH_PATH}/my_conf/env.sh--${CA_NAME}" ]; then
    . "${SH_PATH}/my_conf/env.sh--${CA_NAME}"
    F_CHECK_OPENSSL
else
    echo -e "\n峰哥说：环境参数文件【${SH_PATH}/my_conf/env.sh--${CA_NAME}】未找到！\n"
    exit 1
fi


# cnf (重新生成CA的配置文件，确保一致性)
# 生成CA秘钥用法变量
F_CERT_USE_FOR_VAR  "${CERT_USE_FOR}"
if [ $? -ne 0 ]; then
    echo -e "\n峰哥说：配置文件【${SH_PATH}/my_conf/env.sh--${CA_NAME}】中的参数【CERT_USE_FOR】设置错误，请检查\n"
    exit 1
fi
F_GENERATE_OPENSSL_CNF "${CA_NAME}"


# check cert file
CRT_FILE="${SH_PATH}/to_user_crt/${NAME}.crt"
if [ ! -f "${CRT_FILE}" ]; then
    echo -e "\n峰哥说：找不到证书文件：\n    【${CRT_FILE}】\n"
    exit 1
fi


# revoke
echo -e "\n正在吊销证书：【${NAME}】..."
openssl ca -revoke "${CRT_FILE}" -config "${SH_PATH}/my_conf/openssl.cnf--${CA_NAME}"

if [ $? -eq 0 ]; then
    echo -e "\n成功：证书已吊销！"
    echo "注意：请务必运行 CRL 生成脚本以更新吊销列表！"
    echo "      ./m-x-generate_CA_crl.sh -y"
else
    echo -e "\n失败：证书吊销失败，请检查错误信息。"
    exit 1
fi
