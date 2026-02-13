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
GAN_WHAT_FUCK='吊销用户证书'
NEED_PRIVILEGES='ADMIN'



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
        -n|--name      指定要吊销的证书名称（不含路径和后缀）
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
    . ./function.sh
    F_CHECK_OPENSSL
else
    echo -e "\n峰哥说：环境参数文件【${SH_PATH}/my_conf/env.sh--${CA_NAME}】未找到！\n"
    exit 1
fi


# cnf (重新生成CA的配置文件，确保一致性)
F_ECHO_OPENSSL_CNF > "${SH_PATH}/my_conf/openssl.cnf--${CA_NAME}"
# CA配置通常需要开启CA:TRUE等，虽然revoke可能只需要基本配置，但保持完整性更好
# 这里简单处理，因为function.sh中的F_ECHO_OPENSSL_CNF生成的默认配置对CA操作通常够用了
# 只要[ ca ] 和 [ CA_default ] 段落正确指向了 index.txt 等文件即可。
# 根据 function.sh，F_ECHO_OPENSSL_CNF 使用 ${SH_PATH} 变量，这是正确的。
# 且 default_ca = CA_default，CA_default 中指向了 dir = ${SH_PATH}。
# 所以直接使用生成的默认配置即可。

# CA特有配置修正 (参考 1-generate_CA_key_and_crt.sh)
# 主要是为了保险起见，将CA:TRUE等设置好，虽然revoke命令可能不检查这些约束
sed -i 's/CA:FALSE/CA:TRUE/'  "${SH_PATH}/my_conf/openssl.cnf--${CA_NAME}"


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
