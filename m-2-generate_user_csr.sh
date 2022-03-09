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
    用途：用于生成用户证书请求
    依赖：
        ./env_and_function.sh
        ./my_conf/env.sh---\${NAME}      #--- 此文件须自行基于【./my_conf/env.sh---model】创建
    注意：
    用法:
        $0  [-h|--help]
        $0  [-n|--name {证书相关名称}]  <-q|--quiet>
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
                           【环境变量、配置】文件名的后缀：env.sh---test.com、openssl.cnf---test.com
        -q|--quiet     静默方式运行
    示例:
        $0  -n test.com
        $0  -n test.com -q
    "
}



F_GEN_CSR()
{
    # csr
    if [ "${QUIET}" = 'yes' ]; then
        expect << EOF
            set timeout 10
            spawn  bash -c  "openssl req -new  -key ${SH_PATH}/from_user_csr/${NAME}.key  \
                -out ${SH_PATH}/from_user_csr/${NAME}.csr  \
                -config  ${SH_PATH}/my_conf/openssl.cnf---${NAME}  2>&1  \
                | tee /tmp/${SH_NAME}-${NAME}-csr.log"
            expect {
                "Country Name" { send "\n"; exp_continue }
                "State or Province Name*" { send "\n"; exp_continue }
                "Locality Name*" { send "\r"; exp_continue }
                "Organization Name" { send "\r"; exp_continue }
                "Organizational Unit Name*" { send "\r"; exp_continue }
                "Common Name*" { send "\r"; exp_continue }
                "Email Address*" { send "\r"; exp_continue }
                "A challenge password*" { send "\r"; exp_continue }
                "An optional company name*" { send "xxxxxxxxx\n" }
            }
            expect eof
EOF
    else
        openssl req -new  -key ${SH_PATH}/from_user_csr/${NAME}.key  \
            -out ${SH_PATH}/from_user_csr/${NAME}.csr  \
            -config  ${SH_PATH}/my_conf/openssl.cnf---${NAME}  2>&1  \
            | tee /tmp/${SH_NAME}-${NAME}-csr.log
    fi
    # 成功？
    #
    # 查看csr信息
    echo -e "\n证书请求信息如下："
    echo '------------------------------------------------------------'
    openssl req  -in ${SH_PATH}/from_user_csr/${NAME}.csr  -noout -text
    echo '------------------------------------------------------------'
    echo -e "\n私钥、证书请求文件路径："
    echo "    私钥：【${SH_PATH}/from_user_csr/${NAME}.key】"
    echo "    证书请求：【${SH_PATH}/from_user_csr/${NAME}.csr】"
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
if [ -f "${SH_PATH}/my_conf/env.sh---${NAME}" ]; then
    . ${SH_PATH}/my_conf/env.sh---${NAME}
    . ./function.sh
else
    echo -e "\n峰哥说：环境参数文件【${SH_PATH}/my_conf/env.sh---${NAME}】未找到，请基于【${SH_PATH}/my_conf/env.sh---model】创建！\n"
    exit 1
fi
#
QUIET=${QUIET:-'no'}


# cnf
F_ECHO_OPENSSL_CNF > ${SH_PATH}/my_conf/openssl.cnf---${NAME}



#echo    "在生成用户证书请求的过程中，会以交互的方式进行，请根据提示操作！"
#read -p "是否键继续(y|n)：" ACK
#if [ "x${ACK}" != 'xy' ]; then
#    echo -e "\nOK，已退出！\n"
#    exit 1
#fi

# key
if [ ! -f "${SH_PATH}/from_user_csr/${NAME}.key" ]; then
     echo -e "\n峰哥说：私钥文件【${SH_PATH}/from_user_csr/${NAME}.key】未找到，请检查！\n"
     exit 1
fi


# csr
F_GEN_CSR



