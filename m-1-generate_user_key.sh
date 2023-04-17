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



F_HELP()
{
    echo "
    用途：用于生成用户秘钥
    依赖：
        ./function.sh
    注意：
    用法:
        $0  [-h|--help]
        $0  [-n|--name {证书相关名称}]  <-p|--privatekey-bits {私钥长度}>  <-q|--quiet>
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
        -h|--help      此帮助
        -n|--name      指定名称，用以确定用户证书相关名称前缀及env、cnf文件名称后缀。
                       即：【私钥、证书请求、证书】的文件名称前缀：test.com.key、test.com.csr、test.com.crt
                           【环境变量、配置】文件名的后缀：env.sh--test.com、openssl.cnf--test.com
        -p|--privatekey-bits  私钥长度，默认2048
        -q|--quiet     静默方式运行
    示例:
        $0  -n test.com
        $0  -p 4096  -n test.com
        $0  -q  -n test.com
    "
}




F_GEN_KEY()
{
    # key
    openssl genrsa -out ${SH_PATH}/from_user_csr/${NAME}.key  ${PRIVATEKEY_BITS}
    echo -e "\n私钥文件路径："
    echo "    私钥：【${SH_PATH}/from_user_csr/${NAME}.key】"
}




TEMP=`getopt -o hp:n:q  -l help,privatekey-bits:,name:,quiet -- "$@"`
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
            shift
            F_HELP
            exit
            ;;
        -p|--privatekey-bits)
            PRIVATEKEY_BITS=$2
            shift 2
            if [[ ! ${PRIVATEKEY_BITS} =~ ^[1-9]+[0-9]*$ ]]; then
                echo -e "\n峰哥说：参数值【-b|--bits】必须为正整数！\n"
                exit 1
            fi
            let X=${PRIVATEKEY_BITS}%1024
            if [ $X -ne 0 ]; then
                echo -e "\n峰哥说：私钥长度必须是1024的整数倍！\n"
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
    . ${SH_PATH}/my_conf/env.sh--${NAME}
    #. ./function.sh
else
    echo -e "\n峰哥说：环境参数文件【${SH_PATH}/my_conf/env.sh--${NAME}】未找到，请基于【${SH_PATH}/my_conf/env.sh--model】创建！\n"
    exit 1
fi
#
QUIET=${QUIET:-'no'}



#
if [ -f "${SH_PATH}/from_user_csr/${NAME}.key"  -a  "${QUIET}" != 'yes' ]; then
    echo "私钥文件【${SH_PATH}/from_user_csr/${NAME}.key】已存在，请确认是否需要重建"
    read -p "需要重建吗？(Y|N)" ACK
    if [ "x${ACK}" = "xY" ]; then
        F_GEN_KEY
    else
        echo -e "\nOK，使用现有私钥【${SH_PATH}/from_user_csr/${NAME}.key】！\n"
    fi
else
    F_GEN_KEY
fi



