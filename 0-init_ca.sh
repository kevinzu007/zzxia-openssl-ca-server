#!/bin/bash


read -p "你正在进行初始化CA证书颁发程序，这将会删除所有CA秘钥及用户证书信息！ 是否键继续(y|n)：" ACK
if [ "x${ACK}" != 'xy' ]; then
    echo -e "\nOK，已退出！\n"
    exit 1
fi


rm -f  ca*pem
rm -f  index.txt*
rm -f  serial*
rm -f  crlnumber*

> index.txt
echo "01"  > serial
echo "01"  > crlnumber


rm -rf  certs/*
rm -rf  crl/*
rm -rf  from_user_csr/*
rm -rf  newcerts/*
rm -rf  private/*
rm -rf  to_user_crt/*


find  my_conf/*  ! -iname  openssl.cnf.env* -exec rm -f {} \;
echo "OK，初始化已完成！"


