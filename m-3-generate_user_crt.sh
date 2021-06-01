#!/bin/bash


# sh
SH_NAME=${0##*/}
SH_PATH=$( cd "$( dirname "$0" )" && pwd )
cd ${SH_PATH}


# env
.  ./env_and_function.sh
CERT_BITS=${CERT_BITS:-2048}          #--- 证书长度
CERT_DAYS=${CERT_DAYS:-365}           #--- 证书有效期
#
QUIET='no'



F_HELP()
{
    echo "
    用途：用于颁发用户证书
    依赖：
        ./env_and_function.sh
        ./my_conf/openssl.cnf.env---\${NAME}      #--- 此文件须自行基于【./my_conf/openssl.cnf.env---model】创建
    注意：
    用法:
        $0  [-h|--help]
        $0  [-n|--name {证书相关名称}]  <-c|--cert-bits {证书长度}>  <-d|--days {证书有效天数}>  <-f|--csr-file {证书请求文件}>  <-q|--quiet>
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
                           【环境变量、配置】文件名的后缀：openssl.cnf.env---test.com、openssl.cnf---test.com
        -f|--csr-file  指定外部用户证书请求文件。一般只有在用户使用其他工具生成证书请求时使用此项
        -c|--cert-bits 证书长度，默认2048
        -d|--days      证书有效期，默认365天
        -q|--quiet     静默方式运行
    示例:
        $0  -n test.com
        #
        $0  -c 4096  -n test.com
        $0  -d 730   -n test.com
        $0  -c 4096  -d 730  -n test.com
        # 第三方证书请求
        $0  -f /path/to/xxx.csr  -n xxxxx
        $0  -c 4096  -d 730  -f /path/to/xxx.csr  -n xxxxx
    "
}



F_CSR_TO_CNF()
{
    F_CSR_FILE=$1
    openssl req  -in ${F_CSR_FILE}  -noout -text  >  /tmp/${SH_NAME}-${NAME}.csr.text
    #
    # 主要信息
    CSR_SUBJECT=$( cat /tmp/${SH_NAME}-${NAME}.csr.text  \
        | grep  'Subject: C' | sed 's/^ *//'  \
        | awk -F ':' '{print $2}'  \
        | sed 's/,//g' )
    # env
    for LINE in $( echo ${CSR_SUBJECT} );
    do
        eval $( echo ${LINE} )
    done
    #
    countryName_default="$C"
    stateOrProvinceName_default="$ST"
    localityName_default="$L"
    organizationName_default0="$O"
    organizationalUnitName_default="$OU"
    emailAddress_default="echo $CN | cut -d '/' -f 2 | cut -d '=' -f 2"
    commonName_default="`echo $CN | cut -d '/' -f 1`"
    #
    # 备用名称信息
    CSR_SUBJECT_A=$( cat /tmp/${SH_NAME}-${NAME}.csr.text  \
        | awk '/X509v3 Subject Alternative Name/{getline; print}'  \
        | sed 's/^ *//'  \
        | sed  's/,//g' )
    # env
    alt_names=''
    i=1
    for LINE in $( echo ${CSR_SUBJECT_A} );
    do
        V=$( echo $LINE | cut -d ':' -f 2 )
        alt_names="${alt_names}DNS.$i = $V\n"
        let i=$i+1
    done
    #
    echo
    echo "证书请求信息如下："
    echo '------------------------------------------------------------'
    echo ${CSR_SUBJECT}
    echo ${CSR_SUBJECT_A}
    echo '------------------------------------------------------------'
    echo
    #
    F_ECHO_OPENSSL_CNF > "${SH_PATH}/my_conf/openssl.cnf---${NAME}"
}



F_GEN_CRT()
{
    F_CSR_FILE=$1
    # crt
    # 注意：签名主要信息从csr文件获取，而备用名称需要从openssl.cnf文件里的[alt_name]中获取
    #       CA信息从从openssl.cnf文件中获取，【-extensions v3_req】是必须项
    if [ "${QUIET}" = 'yes' ]; then
        expect << EOF
            set timeout 10
            spawn  bash -c  "openssl ca  -in ${F_CSR_FILE}  \
                -out ${SH_PATH}/to_user_crt/${NAME}.crt  \
                -extensions v3_req  \
                -config ${SH_PATH}/my_conf/openssl.cnf---${NAME}  2>&1  \
                | tee /tmp/${SH_NAME}-${NAME}-crt.log"
            expect {
                "Sign the certificate?" { send "y\r"; exp_continue }
                "1 out of 1 certificate requests certified, commit?" { send "y\r" }
            }
            expect eof
EOF
    else
        openssl ca  -in ${F_CSR_FILE}  \
            -out ${SH_PATH}/to_user_crt/${NAME}.crt  \
            -extensions v3_req  \
            -config ${SH_PATH}/my_conf/openssl.cnf---${NAME}  2>&1  \
            | tee /tmp/${SH_NAME}-${NAME}-crt.log
    fi
    # 成功？
    if [ `grep -q 'Data Base Updated' /tmp/${SH_NAME}-${NAME}-crt.log; echo $?` -ne 0 ]; then
        echo -e "\n峰哥说：证书生成失败\n"
        return 1
    fi
    #
    echo -e "\n证书签名详情如下："
    echo '------------------------------------------------------------'
    openssl x509  -in ${SH_PATH}/to_user_crt/${NAME}.crt  -noout -text
    echo '------------------------------------------------------------'
    echo -e "\n用户证书文件路径："
    echo "    证书：【${SH_PATH}/to_user_crt/${NAME}.crt】"
    return 0
}




TEMP=`getopt -o hc:d:n:f:q  -l help,cert-bits:,days:,name:,csr-file:,quiet -- "$@"`
if [ $? != 0 ]; then
    echo "参数不合法！【请查看帮助：\$0 --help】"
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
        -c|--cert-bits)
            CERT_BITS=$2
            shift 2
            if [[ ! ${CERT_BITS} =~ ^[1-9]+[0-9]*$ ]]; then
                echo -e "\n峰哥说：参数值【-b|--bits】必须为正整数！\n"
                exit 1
            fi
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
        -f|--csr-file)
            CSR_FILE=$2
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
            echo "参数不合法！【请查看帮助：\$0 --help】"
            exit 1
            ;;
    esac
done


# NAME
if [[ -z "${NAME}" ]]; then
    echo -e "\n峰哥说：参数【-n|--name {证书相关名称}】不能为空！\n"
    exit 1
fi



#
if [[ -z "${CSR_FILE}" ]]; then
    # 用本程序为用户生成csr的方式时
    # 所有所有证书信息直接从本地cnf文件中获取，用cnf文件生成证书
    # cnf
    if [ -f "${SH_PATH}/from_user_csr/${NAME}.csr"  -a  -f "${SH_PATH}/my_conf/openssl.cnf---${NAME}" ]; then
        # crt
        F_GEN_CRT  "${SH_PATH}/from_user_csr/${NAME}.csr"
    else
        echo -e "\n峰哥说：证书请求文件【${SH_PATH}/from_user_csr/${NAME}.csr】未找到，或者证书cnf文件【${SH_PATH}/my_conf/openssl.cnf---${NAME}】未找到！\n"
        exit 1
    fi
else
    # 用户用其他工具生成csr时
    # 所有证书信息直接从用户csr中获取，并生成cnf文件，用cnf文件生成证书
    # csr
    if [ ! -f ${CSR_FILE} ]; then
        echo -e "\n峰哥说：证书请求文件【${CSR_FILE}】未找到！\n"
        exit 1
    fi
    # 检测重名
    if [ -f "${SH_PATH}/my_conf/openssl.cnf---${NAME}"  -a  ${QUIET} != 'yes' ]; then
        echo "cnf文件【${SH_PATH}/my_conf/openssl.cnf---${NAME}】已存在，请确定是否可以覆盖现有文件，如果不能确定，可以通过修改【-d|--name {证书相关名称}】参数值以规避cnf文件已存在问题"
        read -p "覆盖现有cnf文件吗？(y|n):" ACK
        if [ "x${ACK}" = 'xy' ]; then
            # 生成cnf
            F_CSR_TO_CNF  "${CSR_FILE}"
        else
            echo -e "\nOK，已退出！\n请为【-d|--name {证书相关名称}】参数换个参数值\n"
            exit 1
        fi
    else
        # 生成cnf
        F_CSR_TO_CNF  "${CSR_FILE}"
    fi
    # 生成crt
    F_GEN_CRT  "${CSR_FILE}"
fi


