#!/bin/bash
#############################################################################
# Create By: zhf_sy
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


F_HELP()
{
    echo "
    用途：初始化CA服务器环境
    特征码：
        CA证书
    权限要求：
        admin
    依赖：
    注意：清空CA相关数据及颁发的证书及配置文件
    用法：
        $0  -h|--help
        $0  -y|--yes
    参数规范：
        无包围符号 ：-h                : 必选【选项】
                   ：-y                : 必选【选项】
                   ：--help            : 必选【选项】
                   ：--yes             : 必选【选项】
        []         ：[-a]              : 可选【选项】
                   ：[val]             : 可选【参数值】
        <>         ：<val>             : 需替换的具体值（用户必须提供）
        %%         ：%val%             : 通配符（包含匹配，如%error%匹配error_code）
        |          ：val1|val2|<valn>  : 多选一
        {}         ：{-a <val>}        : 必须成组出现【选项+参数值】
                   ：{val1 val2}       : 必须成组的【参数值组合】，且必须按顺序提供
    参数说明：
        -h|--help      此帮助
        -y|--yes       初始化CA
    示例:
        # 初始化
        $0 -y
    "
}


case $1 in
    -h|--help)
        F_HELP
        shift
        exit
        ;;
    -y|--yes)
        shift
        # OK
        read -p "你正在进行初始化CA证书颁发程序，这将会删除所有CA秘钥及用户证书信息！ 是否键继续(y|n)：" ACK
        if [ "x${ACK}" != 'xy' ]; then
            echo -e "\nOK，已退出！\n"
            exit 1
        fi
        ;;
    *)
        echo -e "参数错误，请查看帮助【$0 -h】"
        exit 1
        ;;
esac


# rm
rm -f  index.txt*
rm -f  serial*
rm -f  crlnumber*

rm -f  ca.pem.*
rm -f  ca.der.*
rm -rf  private/*

rm -rf  newcerts/*
rm -rf  certs/*
rm -rf  crl/*

rm -rf  from_user_csr/*
rm -rf  to_user_crt/*

find  my_conf/*  ! -iname  env.sh* -exec rm -f {} \;


# create
> index.txt
echo "01"  > serial
echo "01"  > crlnumber


echo "OK，初始化已完成！"


