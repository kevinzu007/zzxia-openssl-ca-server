#!/bin/bash
#############################################################################
# Create By: Antigravity (AI)
# License: GNU GPLv3
# Description: zzxia-openssl-ca-server 自动化测试脚本
# Test On: Ubuntu / CentOS
#############################################################################

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 计数器
PASS_COUNT=0
FAIL_COUNT=0
TOTAL_COUNT=0

# 项目路径
PROJECT_DIR=$( cd "$( dirname "$0" )" && pwd )

# 测试工作目录（使用临时目录，不影响原项目数据）
TEST_WORK_DIR=""


#############################################################################
# 工具函数
#############################################################################

F_ASSERT()
{
    local TEST_NAME="$1"
    local CONDITION="$2"   # 0=pass, 非0=fail
    let TOTAL_COUNT++
    if [ "${CONDITION}" -eq 0 ]; then
        let PASS_COUNT++
        echo -e "  ${GREEN}[PASS]${NC} ${TEST_NAME}"
    else
        let FAIL_COUNT++
        echo -e "  ${RED}[FAIL]${NC} ${TEST_NAME}"
    fi
}

F_ASSERT_FILE_EXISTS()
{
    local TEST_NAME="$1"
    local FILE_PATH="$2"
    if [ -f "${FILE_PATH}" ]; then
        F_ASSERT "${TEST_NAME}" 0
    else
        F_ASSERT "${TEST_NAME}" 1
    fi
}

F_ASSERT_DIR_EXISTS()
{
    local TEST_NAME="$1"
    local DIR_PATH="$2"
    if [ -d "${DIR_PATH}" ]; then
        F_ASSERT "${TEST_NAME}" 0
    else
        F_ASSERT "${TEST_NAME}" 1
    fi
}

# 准备测试环境：将项目文件复制到临时目录
F_SETUP()
{
    TEST_WORK_DIR=$(mktemp -d)
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误：无法创建临时目录${NC}"
        exit 1
    fi

    # 复制项目文件（排除 .git 目录和测试脚本自身）
    cp -a "${PROJECT_DIR}/"*.sh "${TEST_WORK_DIR}/"
    cp -a "${PROJECT_DIR}/my_conf" "${TEST_WORK_DIR}/"
    cp -a "${PROJECT_DIR}/function.sh" "${TEST_WORK_DIR}/"
    if [ -f "${PROJECT_DIR}/key_usage.md" ]; then
        cp "${PROJECT_DIR}/key_usage.md" "${TEST_WORK_DIR}/"
    fi
    if [ -f "${PROJECT_DIR}/LICENSE" ]; then
        cp "${PROJECT_DIR}/LICENSE" "${TEST_WORK_DIR}/"
    fi

    # 创建测试用的 CA 配置文件
    cp "${TEST_WORK_DIR}/my_conf/env.sh--CA.sample" "${TEST_WORK_DIR}/my_conf/env.sh--CA"

    # test.lan 配置已由 my_conf 目录复制带入，无需重复复制

    # 为一键测试创建 test2.lan 配置
    if [ -f "${TEST_WORK_DIR}/my_conf/env.sh--test.lan" ]; then
        sed 's/test\.lan/test2.lan/g' "${TEST_WORK_DIR}/my_conf/env.sh--test.lan" > "${TEST_WORK_DIR}/my_conf/env.sh--test2.lan"
    fi

    echo -e "${YELLOW}测试环境：${TEST_WORK_DIR}${NC}"
}

# 清理测试环境
F_CLEANUP()
{
    if [ -n "${TEST_WORK_DIR}" ] && [ -d "${TEST_WORK_DIR}" ]; then
        rm -rf "${TEST_WORK_DIR}"
        echo -e "\n${YELLOW}测试环境已清理${NC}"
    fi
}

# 确保退出时清理
trap F_CLEANUP EXIT


#############################################################################
# 测试用例
#############################################################################

# 测试1：F_CERT_USE_FOR_VAR 单元测试
T_UNIT_CERT_USE_FOR_VAR()
{
    echo -e "\n${YELLOW}=== 测试1：F_CERT_USE_FOR_VAR 单元测试 ===${NC}"

    # 加载函数
    source "${TEST_WORK_DIR}/function.sh"

    # 测试所有 10 种数字形式
    local TYPES_NUM=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10")
    local TYPES_STR=("ca" "code" "computer" "webserver" "client" "trustlist" "timestamp" "ipsec" "email" "smartcard")

    for i in "${!TYPES_NUM[@]}"; do
        NUM="${TYPES_NUM[$i]}"
        STR="${TYPES_STR[$i]}"

        # 数字形式
        MY_KEY_USAGE_S=""
        MY_EXTENDED_KEY_USAGE_S=""
        F_CERT_USE_FOR_VAR "${NUM}"
        F_ASSERT "CERT_USE_FOR=${NUM} (${STR}): 返回值正确" $?

        F_ASSERT "CERT_USE_FOR=${NUM}: MY_KEY_USAGE_S 非空" $([ -n "${MY_KEY_USAGE_S}" ] && echo 0 || echo 1)

        # 字符串形式
        MY_KEY_USAGE_S=""
        MY_EXTENDED_KEY_USAGE_S=""
        F_CERT_USE_FOR_VAR "${STR}"
        F_ASSERT "CERT_USE_FOR=${STR}: 返回值正确" $?
    done

    # 测试无效参数
    F_CERT_USE_FOR_VAR "invalid" 2>/dev/null
    F_ASSERT "CERT_USE_FOR=invalid: 返回错误" $([ $? -ne 0 ] && echo 0 || echo 1)

    F_CERT_USE_FOR_VAR "" 2>/dev/null
    F_ASSERT "CERT_USE_FOR=空: 返回错误" $([ $? -ne 0 ] && echo 0 || echo 1)
}


# 测试2：CA 初始化
T_INIT_CA()
{
    echo -e "\n${YELLOW}=== 测试2：CA 初始化 ===${NC}"

    cd "${TEST_WORK_DIR}"
    bash ./0-init_ca.sh -y <<< "y" > /dev/null 2>&1

    F_ASSERT_FILE_EXISTS "index.txt 已创建" "${TEST_WORK_DIR}/index.txt"
    F_ASSERT_FILE_EXISTS "serial 已创建" "${TEST_WORK_DIR}/serial"
    F_ASSERT_FILE_EXISTS "crlnumber 已创建" "${TEST_WORK_DIR}/crlnumber"
    F_ASSERT_DIR_EXISTS  "private/ 目录已创建" "${TEST_WORK_DIR}/private"
    F_ASSERT_DIR_EXISTS  "newcerts/ 目录已创建" "${TEST_WORK_DIR}/newcerts"
    F_ASSERT_DIR_EXISTS  "certs/ 目录已创建" "${TEST_WORK_DIR}/certs"
    F_ASSERT_DIR_EXISTS  "crl/ 目录已创建" "${TEST_WORK_DIR}/crl"
    F_ASSERT_DIR_EXISTS  "from_user_csr/ 目录已创建" "${TEST_WORK_DIR}/from_user_csr"
    F_ASSERT_DIR_EXISTS  "to_user_crt/ 目录已创建" "${TEST_WORK_DIR}/to_user_crt"

    # 检查 serial 初始值
    local SERIAL_VAL=$(cat "${TEST_WORK_DIR}/serial" 2>/dev/null)
    F_ASSERT "serial 初始值为 01" $([ "${SERIAL_VAL}" = "01" ] && echo 0 || echo 1)
}


# 测试3：生成 CA 密钥和证书
T_GENERATE_CA()
{
    echo -e "\n${YELLOW}=== 测试3：生成 CA 密钥和证书 ===${NC}"

    cd "${TEST_WORK_DIR}"
    local CA_LOG=$(mktemp)
    # 提供交互输入：
    #   "y" 给 read -p 确认提示
    #   yes "" 生成无限空行给 openssl req 以接受所有默认值
    (echo 'y'; yes '') | bash ./1-generate_CA_key_and_crt.sh -y > "${CA_LOG}" 2>&1

    F_ASSERT_FILE_EXISTS "CA 私钥已生成" "${TEST_WORK_DIR}/private/ca.pem.key"
    F_ASSERT_FILE_EXISTS "CA PEM 证书已生成" "${TEST_WORK_DIR}/ca.pem.crt"
    F_ASSERT_FILE_EXISTS "CA DER 证书已生成" "${TEST_WORK_DIR}/ca.der.crt"

    # 如果证书生成失败，输出错误日志帮助定位问题
    if [ ! -f "${TEST_WORK_DIR}/ca.pem.crt" ]; then
        echo -e "  ${RED}[DEBUG] CA 证书生成日志：${NC}"
        tail -20 "${CA_LOG}" | sed 's/^/    /'
    fi
    rm -f "${CA_LOG}"

    # 验证证书是否有效
    if [ -f "${TEST_WORK_DIR}/ca.pem.crt" ]; then
        openssl x509 -in "${TEST_WORK_DIR}/ca.pem.crt" -noout -text > /dev/null 2>&1
        F_ASSERT "CA 证书格式有效" $?

        # 验证是 CA 证书
        local IS_CA=$(openssl x509 -in "${TEST_WORK_DIR}/ca.pem.crt" -noout -text 2>/dev/null | grep "CA:TRUE")
        F_ASSERT "CA 证书含 CA:TRUE 标识" $([ -n "${IS_CA}" ] && echo 0 || echo 1)
    fi

    # 验证私钥权限
    if [ -f "${TEST_WORK_DIR}/private/ca.pem.key" ]; then
        local KEY_PERM=$(stat -c "%a" "${TEST_WORK_DIR}/private/ca.pem.key" 2>/dev/null)
        F_ASSERT "CA 私钥权限为 600" $([ "${KEY_PERM}" = "600" ] && echo 0 || echo 1)
    fi
}


# 测试4：分步生成用户密钥
T_GENERATE_USER_KEY()
{
    echo -e "\n${YELLOW}=== 测试4：生成用户密钥 ===${NC}"

    cd "${TEST_WORK_DIR}"
    bash ./m-1-generate_user_key.sh -n test.lan -q > /dev/null 2>&1

    F_ASSERT_FILE_EXISTS "用户私钥已生成" "${TEST_WORK_DIR}/from_user_csr/test.lan.key"

    # 验证私钥权限
    if [ -f "${TEST_WORK_DIR}/from_user_csr/test.lan.key" ]; then
        local KEY_PERM=$(stat -c "%a" "${TEST_WORK_DIR}/from_user_csr/test.lan.key" 2>/dev/null)
        F_ASSERT "用户私钥权限为 600" $([ "${KEY_PERM}" = "600" ] && echo 0 || echo 1)

        # 验证是有效的 RSA 私钥
        openssl rsa -in "${TEST_WORK_DIR}/from_user_csr/test.lan.key" -check -noout > /dev/null 2>&1
        F_ASSERT "用户私钥格式有效" $?
    fi
}


# 测试5：生成用户 CSR
T_GENERATE_USER_CSR()
{
    echo -e "\n${YELLOW}=== 测试5：生成用户证书请求 ===${NC}"

    cd "${TEST_WORK_DIR}"
    bash ./m-2-generate_user_csr.sh -n test.lan -q > /dev/null 2>&1

    F_ASSERT_FILE_EXISTS "用户 CSR 已生成" "${TEST_WORK_DIR}/from_user_csr/test.lan.csr"

    # 验证 CSR 格式
    if [ -f "${TEST_WORK_DIR}/from_user_csr/test.lan.csr" ]; then
        openssl req -in "${TEST_WORK_DIR}/from_user_csr/test.lan.csr" -noout -verify > /dev/null 2>&1
        F_ASSERT "用户 CSR 格式有效" $?

        # 验证 CN
        local CSR_CN=$(openssl req -in "${TEST_WORK_DIR}/from_user_csr/test.lan.csr" -noout -subject 2>/dev/null | grep "test.lan")
        F_ASSERT "CSR 包含正确的 CN (test.lan)" $([ -n "${CSR_CN}" ] && echo 0 || echo 1)
    fi
}


# 测试6：颁发用户证书
T_GENERATE_USER_CRT()
{
    echo -e "\n${YELLOW}=== 测试6：颁发用户证书 ===${NC}"

    cd "${TEST_WORK_DIR}"
    bash ./m-3-generate_user_crt.sh -n test.lan -q > /dev/null 2>&1

    F_ASSERT_FILE_EXISTS "用户证书已生成" "${TEST_WORK_DIR}/to_user_crt/test.lan.crt"

    # 验证证书
    if [ -f "${TEST_WORK_DIR}/to_user_crt/test.lan.crt" ]; then
        openssl x509 -in "${TEST_WORK_DIR}/to_user_crt/test.lan.crt" -noout -text > /dev/null 2>&1
        F_ASSERT "用户证书格式有效" $?

        # 验证证书是由 CA 签名的
        openssl verify -CAfile "${TEST_WORK_DIR}/ca.pem.crt" "${TEST_WORK_DIR}/to_user_crt/test.lan.crt" > /dev/null 2>&1
        F_ASSERT "用户证书通过 CA 验证" $?

        # 验证不是 CA 证书
        local NOT_CA=$(openssl x509 -in "${TEST_WORK_DIR}/to_user_crt/test.lan.crt" -noout -text 2>/dev/null | grep "CA:FALSE")
        F_ASSERT "用户证书含 CA:FALSE 标识" $([ -n "${NOT_CA}" ] && echo 0 || echo 1)
    fi
}


# 测试7：一键生成用户密钥+CSR+证书
T_3IN1_GENERATE()
{
    echo -e "\n${YELLOW}=== 测试7：一键生成用户密钥+CSR+证书 ===${NC}"

    cd "${TEST_WORK_DIR}"
    bash ./m-3in1-generate_user_key-csr-crt.sh -n test2.lan -q > /dev/null 2>&1

    F_ASSERT_FILE_EXISTS "一键：用户私钥已生成" "${TEST_WORK_DIR}/from_user_csr/test2.lan.key"
    F_ASSERT_FILE_EXISTS "一键：用户 CSR 已生成" "${TEST_WORK_DIR}/from_user_csr/test2.lan.csr"
    F_ASSERT_FILE_EXISTS "一键：用户证书已生成" "${TEST_WORK_DIR}/to_user_crt/test2.lan.crt"

    # 验证证书链
    if [ -f "${TEST_WORK_DIR}/to_user_crt/test2.lan.crt" ]; then
        openssl verify -CAfile "${TEST_WORK_DIR}/ca.pem.crt" "${TEST_WORK_DIR}/to_user_crt/test2.lan.crt" > /dev/null 2>&1
        F_ASSERT "一键：证书通过 CA 验证" $?
    fi
}


# 测试8：续签用户证书
T_RENEW_USER_CRT()
{
    echo -e "\n${YELLOW}=== 测试8：续签用户证书 ===${NC}"

    cd "${TEST_WORK_DIR}"

    # 记录旧证书的序列号用于对比
    local OLD_SERIAL=""
    if [ -f "${TEST_WORK_DIR}/to_user_crt/test.lan.crt" ]; then
        OLD_SERIAL=$(openssl x509 -in "${TEST_WORK_DIR}/to_user_crt/test.lan.crt" -noout -serial 2>/dev/null)
    fi
    F_ASSERT "续签前旧证书存在" $([ -n "${OLD_SERIAL}" ] && echo 0 || echo 1)

    # 使用 --no-revoke 续签（免交互）
    bash ./m-x-renew_user_crt.sh -n test.lan -q --no-revoke > /dev/null 2>&1
    F_ASSERT "续签执行成功" $?

    F_ASSERT_FILE_EXISTS "续签：新证书已生成" "${TEST_WORK_DIR}/to_user_crt/test.lan.crt"

    # 验证旧证书备份文件存在
    local BAK_COUNT=$(ls "${TEST_WORK_DIR}/to_user_crt/test.lan.crt."* 2>/dev/null | wc -l)
    F_ASSERT "续签：旧证书备份文件存在" $([ "${BAK_COUNT}" -ge 1 ] && echo 0 || echo 1)

    # 验证新证书序列号与旧证书不同
    if [ -f "${TEST_WORK_DIR}/to_user_crt/test.lan.crt" ]; then
        local NEW_SERIAL=$(openssl x509 -in "${TEST_WORK_DIR}/to_user_crt/test.lan.crt" -noout -serial 2>/dev/null)
        F_ASSERT "续签：新证书序列号不同" $([ "${NEW_SERIAL}" != "${OLD_SERIAL}" ] && echo 0 || echo 1)

        # 验证新证书通过 CA 验证
        openssl verify -CAfile "${TEST_WORK_DIR}/ca.pem.crt" "${TEST_WORK_DIR}/to_user_crt/test.lan.crt" > /dev/null 2>&1
        F_ASSERT "续签：新证书通过 CA 验证" $?
    fi
}


# 测试9：吊销证书
T_REVOKE_CRT()
{
    echo -e "\n${YELLOW}=== 测试9：吊销用户证书 ===${NC}"

    cd "${TEST_WORK_DIR}"
    bash ./m-x-revoke_user_crt.sh -n test.lan > /dev/null 2>&1
    F_ASSERT "证书吊销执行成功" $?

    # 验证 index.txt 中有吊销记录 (R 开头的行)
    if [ -f "${TEST_WORK_DIR}/index.txt" ]; then
        local REVOKED=$(grep "^R" "${TEST_WORK_DIR}/index.txt" | grep "test.lan")
        F_ASSERT "index.txt 中有吊销记录" $([ -n "${REVOKED}" ] && echo 0 || echo 1)
    fi
}


# 测试10：生成 CRL
T_GENERATE_CRL()
{
    echo -e "\n${YELLOW}=== 测试10：生成 CRL 吊销列表 ===${NC}"

    cd "${TEST_WORK_DIR}"
    bash ./m-x-generate_CA_crl.sh -y > /dev/null 2>&1
    F_ASSERT "CRL 生成执行成功" $?

    F_ASSERT_FILE_EXISTS "CRL PEM 文件已生成" "${TEST_WORK_DIR}/crl/ca.crl.pem"
    F_ASSERT_FILE_EXISTS "CRL DER 文件已生成" "${TEST_WORK_DIR}/crl/ca.crl.der"

    # 验证 CRL 格式
    if [ -f "${TEST_WORK_DIR}/crl/ca.crl.pem" ]; then
        openssl crl -in "${TEST_WORK_DIR}/crl/ca.crl.pem" -noout -text > /dev/null 2>&1
        F_ASSERT "CRL 文件格式有效" $?
    fi
}


#############################################################################
# 主流程
#############################################################################

echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}  zzxia-openssl-ca-server 自动化测试${NC}"
echo -e "${YELLOW}========================================${NC}"

# 检查 openssl
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}错误：openssl 未安装${NC}"
    exit 1
fi

# 准备测试环境
F_SETUP

# 运行测试
T_UNIT_CERT_USE_FOR_VAR
T_INIT_CA
T_GENERATE_CA
T_GENERATE_USER_KEY
T_GENERATE_USER_CSR
T_GENERATE_USER_CRT
T_3IN1_GENERATE
T_RENEW_USER_CRT
T_REVOKE_CRT
T_GENERATE_CRL

# 输出结果
echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}  测试结果${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "  总计: ${TOTAL_COUNT}"
echo -e "  ${GREEN}通过: ${PASS_COUNT}${NC}"
echo -e "  ${RED}失败: ${FAIL_COUNT}${NC}"
echo ""

if [ ${FAIL_COUNT} -eq 0 ]; then
    echo -e "${GREEN}所有测试通过！${NC}\n"
    exit 0
else
    echo -e "${RED}有 ${FAIL_COUNT} 个测试失败！${NC}\n"
    exit 1
fi
