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
    依赖：
    注意：清空CA相关数据及颁发的证书及配置文件
    用法：
        $0  <-h|--help>
        $0  <-y|--yes>
    参数说明：
        \$0   : 代表脚本本身
        []   : 代表是必选项
        <>   : 代表是可选项
        |    : 代表左右选其一
        {}   : 代表参数值，请替换为具体参数值
        %    : 代表通配符，非精确值，可以被包含
        #
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


