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
GAN_WHAT_FUCK='颁发或更新用户证书'
NEED_PRIVILEGES='ADMIN'



F_HELP()
{
    echo "
    用途：用于颁发或更新用户证书
    特征码：
        ${GAN_WHAT_FUCK:-'未命名'}
    权限要求：
        ${NEED_PRIVILEGES:-'未指定'}
    依赖：
        ./function.sh
        ./my_conf/env.sh--\${NAME}      #--- 此文件须自行基于【./my_conf/env.sh--model】创建，当使用外部证书请求文件时，无须此配置文件
    注意：
    用法：
        $0  -h|--help
        $0  {-n|--name <证书相关名称>}  [{-c|--cert-bits <证书长度>}]  [{-d|--days <证书有效天数>}]  [{-f|--csr-file <证书请求文件>}]  [-q|--quiet]
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
        -h|--help                           此帮助
        -n|--name <证书相关名称>            指定名称，用以确定用户证书相关名称前缀及env、cnf文件名称后缀。
                       即：【私钥、证书请求、证书】的文件名称前缀：test.com.key、test.com.csr、test.com.crt
                           【环境变量、配置】文件名的后缀：env.sh--test.com、openssl.cnf--test.com
        -f|--csr-file <证书请求文件>        指定外部用户证书请求文件。一般只有在用户使用其他工具生成证书请求时使用此项
        -c|--cert-bits <证书长度>           证书长度，默认2048
        -d|--days <证书有效天数>            证书有效期，默认365天
        -q|--quiet                          静默方式运行
    示例:
        $0  -n test.com
        #
        $0  -n test.com  -c 4096
        $0  -n test.com  -d 730
        $0  -n test.com  -c 4096  -d 730
        # 第三方证书请求
        $0  -f /path/to/xxx.csr  -n xxxxx
        $0  -f /path/to/xxx.csr  -n xxxxx  -c 4096  -d 730
    "
}



# 将CSR中的keyUsage英文描述转换为OpenSSL配置格式
F_CONVERT_KEY_USAGE()
{
    local USAGE_DESC="$1"
    local RESULT=""
    OLD_IFS="$IFS"
    IFS=","
    for USAGE in $USAGE_DESC; do
        # 去除前后空格
        USAGE=$(echo "$USAGE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        # 数据来源：【key_usage.md】中的【类别=normal】
        case "$USAGE" in
            "Digital Signature")    RESULT="${RESULT}digitalSignature," ;;
            "Non Repudiation")      RESULT="${RESULT}nonRepudiation," ;;
            "Key Encipherment")     RESULT="${RESULT}keyEncipherment," ;;
            "Data Encipherment")    RESULT="${RESULT}dataEncipherment," ;;
            "Key Agreement")        RESULT="${RESULT}keyAgreement," ;;
            "Key CertSign")        RESULT="${RESULT}keyCertSign," ;;
            "Crl Sign")           RESULT="${RESULT}cRLSign," ;;
            "Encipher Only")       RESULT="${RESULT}encipherOnly," ;;
            "Decipher Only")       RESULT="${RESULT}decipherOnly," ;;
        esac
    done
    IFS="$OLD_IFS"
    # 去除末尾逗号
    echo "$RESULT" | sed 's/,$//'
}


# 将CSR中的extendedKeyUsage英文描述转换为OpenSSL配置格式
F_CONVERT_EXTENDED_KEY_USAGE()
{
    local USAGE_DESC="$1"
    local RESULT=""
    OLD_IFS="$IFS"
    IFS=","
    for USAGE in $USAGE_DESC; do
        # 去除前后空格
        USAGE=$(echo "$USAGE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        # 数据来源：【key_usage.md】中的【类别=extended】
        case "$USAGE" in
            "TLS Web Server Authentication")          RESULT="${RESULT}serverAuth," ;;
            "TLS Web Client Authentication")          RESULT="${RESULT}clientAuth," ;;
            "Code Signing")                         RESULT="${RESULT}codeSigning," ;;
            "E-mail Protection")                    RESULT="${RESULT}emailProtection," ;;
            "Trusted Timestamping")                 RESULT="${RESULT}timeStamping," ;;
            "Microsoft Individual Code Signing")       RESULT="${RESULT}msCodeInd," ;;
            "Microsoft Commercial Code Signing")       RESULT="${RESULT}msCodeCom," ;;
            "Microsoft Trust List Signing")           RESULT="${RESULT}msCTLSign," ;;
            "Microsoft Server Gated Crypto")          RESULT="${RESULT}msSGC," ;;
            "Microsoft Encrypted File System")         RESULT="${RESULT}msEFS," ;;
            "Netscape Server Gated Crypto")          RESULT="${RESULT}nsSGC," ;;
        esac
    done
    IFS="$OLD_IFS"
    # 去除末尾逗号
    echo "$RESULT" | sed 's/,$//'
}


# 将-f|--csr-file指定的外来CSR文件转换为openssl.cnf
# （默认使用本系统自动生成的）
F_CSR_TO_CNF()
{
    F_CSR_FILE=$1
    openssl req  -in "${F_CSR_FILE}"  -noout -text  >  "${TEMP_TEXT}"
    #
    # 证书
    export CERT_BITS=${CERT_BITS:-2048}          #--- 证书长度
    export CERT_DAYS=${CERT_DAYS:-365}           #--- 证书有效期
    #
    # 获取主要信息
    CSR_SUBJECT=$( cat "${TEMP_TEXT}"  \
        | grep  'Subject: C' | sed 's/^ *//'  \
        | awk -F ':' '{print $2}'  \
        | sed 's/ = /=\"/g' | sed 's/,/\",/g' | sed 's/$/\"/' )
    # env
    # 将分隔符换成‘,’，然后完了再换回去
    OLD_IFS="$IFS"
    IFS=","
    #
    for LINE in $( echo ${CSR_SUBJECT} );
    do
        eval $( echo ${LINE} )
    done
    IFS="$OLD_IFS"
    #
    countryName_default="$C"
    stateOrProvinceName_default="$ST"
    localityName_default="$L"
    organizationName_default0="$O"
    organizationalUnitName_default="$OU"
    emailAddress_default=$(echo "$CN" | cut -d '/' -f 2 | cut -d '=' -f 2)
    commonName_default="`echo $CN | cut -d '/' -f 1`"
    #
    # 获取备用名称信息
    CSR_SUBJECT_A=$( cat "${TEMP_TEXT}"  \
        | awk '/X509v3 Subject Alternative Name:/{getline; print}'  \
        | sed 's/^ *//'  \
        | sed 's/,//g' )
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
    # 用获取的信息生成openssl.cnf
    F_ECHO_OPENSSL_CNF > "${SH_PATH}/my_conf/openssl.cnf--${NAME}"
    #
    # 获取书类型（是否为CA证书），并修改openssl.cnf
    # 基本约束：是否为CA证书请求
    CSR_BASIC=$( cat "${TEMP_TEXT}"  \
        | awk '/X509v3 Basic Constraints:/{getline; print}'  \
        | sed 's/^ *//'  \
        | sed 's/,//g' )
    if [ "${CSR_BASIC}" = 'CA:TRUE' ]; then
        sed -i 's/CA:FALSE/CA:TRUE/'  "${SH_PATH}/my_conf/openssl.cnf--${NAME}"
    fi
    #
    # 获取秘钥用法，并修改openssl.cnf
    CSR_KEY_USAGES=$( cat "${TEMP_TEXT}"  \
        | awk '/X509v3 Key Usage:/{getline; print}'  \
        | sed 's/^ *//' )
    if [ -n "${CSR_KEY_USAGES}" ]; then
        # 转换为OpenSSL配置格式
        MY_KEY_USAGE_S=$(F_CONVERT_KEY_USAGE "${CSR_KEY_USAGES}")
        if [ -n "${MY_KEY_USAGE_S}" ]; then
            sed -i "/^# keyUsage = 用逗号分隔/a\keyUsage = ${MY_KEY_USAGE_S}"  "${SH_PATH}/my_conf/openssl.cnf--${NAME}"
        fi
    fi
    #
    # 获取增强秘钥用法，并修改openssl.cnf
    CSR_EXTENDED_KEY_USAGES=$( cat "${TEMP_TEXT}"  \
        | awk '/X509v3 Extended Key Usage:/{getline; print}'  \
        | sed 's/^ *//' )
    if [ -n "${CSR_EXTENDED_KEY_USAGES}" ]; then
        # 转换为OpenSSL配置格式
        MY_EXTENDED_KEY_USAGE_S=$(F_CONVERT_EXTENDED_KEY_USAGE "${CSR_EXTENDED_KEY_USAGES}")
        if [ -n "${MY_EXTENDED_KEY_USAGE_S}" ]; then
            sed -i "/^# extendedKeyUsage = 用逗号分隔/a\extendedKeyUsage = ${MY_EXTENDED_KEY_USAGE_S}"  "${SH_PATH}/my_conf/openssl.cnf--${NAME}"
        fi
    fi
    #
    echo
    echo "证书请求信息如下："
    echo '------------------------------------------------------------'
    echo 主题：${CSR_SUBJECT}
    echo 备用主题：${CSR_SUBJECT_A}
    echo 基本约束：${CSR_BASIC}
    echo 秘钥用法：${CSR_KEY_USAGES}
    echo 增强秘钥用法：${CSR_EXTENDED_KEY_USAGES}
    echo '------------------------------------------------------------'
    echo
}



F_GEN_CRT()
{
    F_CSR_FILE=$1
    # crt
    # 注意：签名主要信息从csr文件获取，而备用名称需要从openssl.cnf文件里的[alt_name]中获取
    #       CA信息从从openssl.cnf文件中获取，【-extensions v3_req】是必须项
    openssl ca  -in "${F_CSR_FILE}"  \
        -out "${SH_PATH}/to_user_crt/${NAME}.crt"  \
        -extensions v3_req  \
        -config "${SH_PATH}/my_conf/openssl.cnf--${NAME}"  \
        ${QUIET_OPTION} \
        2>&1  |  tee "${TEMP_LOG}"
    
    # 成功？
    if [ ! -f "${SH_PATH}/to_user_crt/${NAME}.crt" ]; then
        echo -e "\n峰哥说：证书生成失败，请检查错误信息\n"
        return 1
    fi
    
    # 检查日志中是否有成功信息
    if ! grep -q 'Data Base Updated' "${TEMP_LOG}"; then
        echo -e "\n峰哥说：证书生成可能有问题，请检查日志\n"
    fi
    
    echo -e "\n证书签名详情如下："
    echo '------------------------------------------------------------'
    openssl x509  -in "${SH_PATH}/to_user_crt/${NAME}.crt"  -noout -text
    echo '------------------------------------------------------------'
    echo -e "\n用户证书文件路径："
    echo "    证书：【${SH_PATH}/to_user_crt/${NAME}.crt】"
    return 0
}




TEMP=`getopt -o hc:d:n:f:q  -l help,cert-bits:,days:,name:,csr-file:,quiet -- "$@"`
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
        -c|--cert-bits)
            CERT_BITS=$2
            shift 2
            if [[ ! ${CERT_BITS} =~ ^[1-9]+[0-9]*$ ]]; then
                echo -e "\n峰哥说：参数值【-c|--cert-bits】必须为正整数！\n"
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
            echo -e "\n峰哥说：未知参数，请查看帮助【$0 --help】\n"
            exit 1
            ;;
    esac
done


# NAME
if [[ -z "${NAME}" ]]; then
    echo -e "\n峰哥说：参数【-n|--name {证书相关名称}】不能为空！\n"
    exit 1
fi


# env
if [ -f "${SH_PATH}/my_conf/env.sh--${NAME}" ]; then
    . "${SH_PATH}/my_conf/env.sh--${NAME}"     #--- 仅使用 $CERT_BITS、$CERT_DAYS 变量，其他变量会被csr中的值覆盖
    . ./function.sh
    F_CHECK_OPENSSL
else
    echo -e "\n峰哥说：环境参数文件【${SH_PATH}/my_conf/env.sh--${NAME}】未找到，请基于【${SH_PATH}/my_conf/env.sh--model】创建！\n"
    exit 1
fi
#
TEMP_TEXT=$(mktemp) || exit 1
TEMP_LOG=$(mktemp) || exit 1
trap 'rm -f "${TEMP_TEXT}" "${TEMP_LOG}"' EXIT
#
QUIET=${QUIET:-'no'}
# 设置静默选项
if [ "${QUIET}" = 'yes' ]; then
    QUIET_OPTION="-batch"
else
    QUIET_OPTION=""
fi



#
if [[ -z "${CSR_FILE}" ]]; then
    ## 默认：使用先前本程序为用户生成的csr（未提供--csr-file参数时）
    # 所有所有证书信息直接从本地cnf文件中获取，用cnf文件生成证书
    # csr
    if [ ! -f "${SH_PATH}/from_user_csr/${NAME}.csr" ]; then
        echo -e "\n峰哥说：证书请求文件【${SH_PATH}/from_user_csr/${NAME}.csr】未找到！\n"
        exit 1
    fi
    # cnf
    # 现有的
    # crt
    F_GEN_CRT  "${SH_PATH}/from_user_csr/${NAME}.csr"
else
    ## 使用用其他工具生成的csr
    # 所有证书信息直接从用户csr中获取，并生成cnf文件，用cnf文件生成证书
    # csr
    if [ ! -f "${CSR_FILE}" ]; then
        echo -e "\n峰哥说：证书请求文件【${CSR_FILE}】未找到！\n"
        exit 1
    fi
    # 生成cnf
    F_CSR_TO_CNF  "${CSR_FILE}"
    # 生成crt
    F_GEN_CRT  "${CSR_FILE}"
fi


