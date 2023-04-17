#!/bin/bash
#############################################################################
# Create By: zhf_sy
# License: GNU GPLv3
# Test On: CentOS 7
#############################################################################


# 生成openssl.cnf文件
# 使用前需要一些变量
F_ECHO_OPENSSL_CNF()
{
    echo "
# OpenSSL example configuration file.
# This is mostly being used for generation of certificate requests.
#

# This definition stops the following lines choking if HOME isn't
# defined.
HOME            = .
RANDFILE        = \$ENV::HOME/.rnd

# 额外的对象标识符信息
# Extra OBJECT IDENTIFIER info:
#oid_file       = \$ENV::HOME/.oid
oid_section     = new_oids

# 当【openssl x509】实用程序和【-extfile】选项一起用时，在此处命名要使用的 X.509v3 扩展section名称。（也可以直接在命令行带上参数选项【-extensions section名称】吧）
# To use this configuration file with the "-extfile" option of the
# "openssl x509" utility, name here the section containing the
# X.509v3 extensions to use:
#extensions =
# 或者使用【在主要[= default]section中仅包含 X.509v3 扩展】的配置文件
# (Alternatively, use a configuration file that has only
# X.509v3 extensions in its main [= default] section.)



####################################################################
[ new_oids ]
# 我们可以在这里添加新的OID供"ca"，"req"和"ts"使用
# We can add new OIDs in here for use by 'ca', 'req' and 'ts'.
# Add a simple OID like this:
#testoid1 = 1.2.3.4
# Or use config file substitution like this:
#testoid2 = \${testoid1}.5.6

# TSA策略示例
# Policies used by the TSA examples.
tsa_policy1 = 1.2.3.4.1
tsa_policy2 = 1.2.3.4.5.6
tsa_policy3 = 1.2.3.4.5.7



####################################################################
[ ca ]
# 调用CA服务器信息段：CA_default
default_ca = CA_default        # The default ca section



####################################################################
[ CA_default ]
dir     = $PWD      # Where everything is kept

# 颁发的证书路径
new_certs_dir   = \$dir/newcerts    # default place for new certs.
certs           = \$dir/certs       # Where the issued certs are kept
crl             = \$dir/ca.crl.pem  # The current CRL
crl_dir         = \$dir/crl         # Where the issued crl are kept
unique_subject  = no        # Set to 'no' to allow creation of
                            # several ctificates with same subject.

# ca数据库
database    = \$dir/index.txt   # database index file.
serial      = \$dir/serial      # The current serial number，手动设置初始值01
crlnumber   = \$dir/crlnumber   # the current crl number，手动设置初始值01
                                # must be commented out to leave a V1 CRL(当保持crl为V1版本时，需要注释掉此项)

# ca证书等
certificate = \$dir/ca.pem.crt          # The CA certificate
private_key = \$dir/private/ca.pem.key  # The private key
RANDFILE    = \$dir/private/.rand       # private random number file

# 调用证书扩展段：usr_cert
x509_extensions = usr_cert      # The extentions to add to the cert

# 传统格式需要注释掉以下两行
# Comment out the following two lines for the "traditional"
# (and highly broken) format.
name_opt = ca_default        # Subject Name options
cert_opt = ca_default        # Certificate field options

# 拷贝扩展信息（小心使用）
# Extension copying option: use with caution.
#copy_extensions = copy

# 调用吊销列表扩展：crl_ext
# 当保持crl为V1版本时，需要注释掉此项，同时crlnumber也要注释掉 (Netscape 浏览器不支持V2 crl)
# Extensions to add to a CRL. Note: Netscape communicator chokes on V2 CRLs
# so this is commented out by default to leave a V1 CRL.
# crlnumber must also be commented out to leave a V1 CRL.
crl_extensions = crl_ext

#
default_days     = ${CERT_DAYS}          # how long to certify for
default_crl_days = 30            # how long before next CRL
default_md       = sha256        # use SHA-256 by default
preserve         = no            # keep passed DN ordering

# 指定相似请求的不同方法
# 对于CA类型，列出的属性必须相同，可选字段和必须提供的字段
# A few difference way of specifying how similar the request should look
# For type CA, the listed attributes must be the same, and the optional
# and supplied fields are just that :-)
policy = policy_match     # 调用CA策略段：policy_match



####################################################################
# CA策略
# For the CA policy
[ policy_match ]
# 如果值为"match"，则客户端证书请求时，相应信息必须和CA证书保持一致；反之如果为"optional"，则不用
#countryName         = match
countryName         = optional
stateOrProvinceName = optional
organizationName    = optional
organizationalUnitName = optional
commonName          = supplied
emailAddress        = optional



####################################################################
# 列出所有策略对象类型
# For the 'anything' policy
# At this point in time, you must list all acceptable 'object'
# types.
[ policy_anything ]
countryName         = optional
stateOrProvinceName = optional
localityName        = optional
organizationName    = optional
organizationalUnitName = optional
commonName          = supplied
emailAddress        = optional



####################################################################
[ req ]
default_bits        = ${CERT_BITS}
default_md          = sha256
default_keyfile     = privkey.pem
distinguished_name  = req_distinguished_name    # 调用用户信息段[req_distinguished_name]
attributes          = req_attributes            # 调用密码属性段[req_attributes]

# 调用证书请求扩展段：v3_req
req_extensions = v3_req        # The extensions to add to a certificate request

# 调用自签名证书扩展段：v3_ca
x509_extensions = v3_ca        # The extentions to add to the self signed cert

# 私钥密码。如果没有设置私钥密码，则提示输入
# Passwords for private keys if not present they will be prompted for
#input_password = secret
#output_password = secret

# 设置允许的字符串类型
# This sets a mask for permitted string types. There are several options.
# default: PrintableString, T61String, BMPString.
# pkix   : PrintableString, BMPString (PKIX recommendation before 2004)
# utf8only: only UTF8Strings (PKIX recommendation after 2004).
# nombstr : PrintableString, T61String (no BMPStrings or UTF8Strings).
# MASK:XXXX a literal mask value.
# WARNING: ancient versions of Netscape crash on BMPStrings or UTF8Strings.
string_mask = utf8only


####################################################################
# 用户信息
[ req_distinguished_name ]
countryName             = Country Name (2 letter code)
countryName_default     = $countryName_default
countryName_min         = 2
countryName_max         = 2

stateOrProvinceName     = State or Province Name (full name)
stateOrProvinceName_default = $stateOrProvinceName_default

localityName            = Locality Name (eg, city)
localityName_default    = $localityName_default

0.organizationName         = Organization Name (eg, company)
0.organizationName_default = $organizationName_default0

# we can do this but it is not needed normally :-)
#1.organizationName         = Second Organization Name (eg, company)
#1.organizationName_default = World Wide Web Pty Ltd

organizationalUnitName         = Organizational Unit Name (eg, section)
organizationalUnitName_default = $organizationalUnitName_default

commonName              = Common Name (eg, your name or your server\'s hostname)
commonName_default      = $commonName_default
commonName_max          = 64

emailAddress            = Email Address
emailAddress_max        = 64
emailAddress_default    = $emailAddress_default

# SET-ex3           = SET extension number 3



####################################################################
# 密码属性
[ req_attributes ]
challengePassword       = A challenge password
challengePassword_min   = 4
challengePassword_max   = 20

unstructuredName        = An optional company name



####################################################################
# 证书扩展
[ usr_cert ]
# 作为CA，在签名证书请求时添加的扩展
# These extensions are added when 'ca' signs a request.


# 虽然这违反了PKIX指南，但是为了避免误解，添加此项，显式标明是CA，还是非CA
#     为非CA证书签名时设置为：         CA:FALSE
#     为CA证书签名时（包含CA自签名）： CA:TRUE
# This goes against PKIX guidelines but some CAs do it and some software
# requires this to avoid interpreting an end user certificate as a CA.
#basicConstraints = CA:FALSE     #--- 我不想启用它


# 颁发典型客户端证书的秘钥用法：
#     - nonRepudiation    不可抵赖
#     - digitalSignature  数字签名 
#     - keyEncipherment   秘钥加密
# This is typical in keyUsage for a client certificate.
#keyUsage = nonRepudiation,digitalSignature,keyEncipherment    #--- 这个在证书请求时已经设置，这里不需要再设置了吧？ 验证后，真的可以


# 秘钥增强用法：
#
# TSA证书所必需
# This is required for TSA certificates.
#extendedKeyUsage = critical,timeStamping


## Netscape证书类型，现在已经被【basicConstraints、keyUsage、extendedKeyUsage】替代
## 参考：https://www.openssl.org/docs/manmaster/man5/x509v3_config.html
## nsCertType证书类型的示例
## 类型包含：
##     - server   : 服务器SSL
##     - client   : 客户端
##     - email    : email
##     - objsign  : 对象签名
## 默认：如果省略，则证书可以是除【对象签名】之外的任何类型，即：server、client、email
##
## Here are some examples of the usage of nsCertType. If it is omitted
## the certificate can be used for anything *except* object signing.
#
## 服务器SSL签名
## This is OK for an SSL server.
##nsCertType = server
#
## 对象签名
## For an object signing certificate this would be used.
##nsCertType = objsign
#
## 客户端典型签名：client,email
## For normal client use this is typical
##nsCertType = client,email
#
## 客户端所有类型签名（包含对象签名）：client,email,objsign
## and for everything including object signing:
##nsCertType = client,email,objsign


# 显示在Netscape浏览器上的
# This will be displayed in Netscape's comment listbox.
nsComment = "OpenSSL Generated Certificate"


# 如果无害，则建议包含在所有证书中
# PKIX recommendations harmless if included in all certificates.
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer


# 这些是为【主题备用名称】和【发行人备用名称】用的
# This stuff is for subjectAltName and issuerAltname.
#
# 导入email地址到主题备用名称
# Import the email address
#subjectAltName = email:copy
# 从主题备用名称中移除email
# 生成不被弃用的符合PKIX标准的证书（根据 PKIX标准 生成不被弃用的证书的替代方法）
# An alternative to produce certificates that aren't
# deprecated according to PKIX.
#subjectAltName = email:move
#
# 复制主题详细信息
# Copy subject details
#issuerAltName = issuer:copy


# CA相关Url
#nsCaRevocationUrl = http://www.domain.dom/ca.crl.pem
#nsBaseUrl         =
#nsRevocationUrl   =
#nsRenewalUrl      =
#nsCaPolicyUrl     =
#nsSslServerName   =



####################################################################
# 证书请求扩展
[ v3_req ]
# Extensions to add to a certificate request


# 为非CA证书签名时设置为：         CA:FALSE
# 为CA证书签名时（包含CA自签名）： CA:TRUE
basicConstraints = CA:FALSE


# 秘钥用法：
#     - digitalSignature    数字签名
#     - nonRepudiation      认可签名
#     - keyEncipherment     密钥加密
#     - dataEncipherment    数据加密
#     - keyAgreement        密钥协商
#     - keyCertSign         证书签名
#     - cRLSign             CRL 签名
#     - encipherOnly        仅仅加密
#     - decipherOnly        仅仅解密
#keyUsage = nonRepudiation,digitalSignature,keyEncipherment
# keyUsage = 用逗号分隔


# 增强密钥用法：
#    - serverAuth         SSL/TLS Web服务器身份验证
#    - clientAuth         SSL/TLS Web客户端身份验证
#    - codeSigning        代码签名
#    - emailProtection    安全电子邮件 (S/MIME).
#    - timeStamping       时间戳
#    - msCodeInd          Microsoft 个人代码签名 (authenticode)
#    - msCodeCom          Microsoft 商业代码签名 (authenticode)
#    - msCTLSign          Microsoft 信任列表签名
#    - msSGC              Microsoft Server Gated Crypto
#    - msEFS              Microsoft 加密文件系统
#    - nsSGC              Netscape Server Gated Crypto
#extendedKeyUsage = serverAuth,clientAuth
# extendedKeyUsage = 用逗号分隔


# zhf_sy --- 添加备用名
# 方法1：（参考：http://blog.chinaunix.net/uid-451-id-5075683.html）
#subjectAltName = email:copy,email:aa@bb.cc,DNS:test.com,DNS:demo.com,DNS:,IP:192.168.7.1
# 方法2：
subjectAltName = @alt_names



####################################################################
# zhf_sy
[ alt_names ]
# 新增 alt_names,注意等号前后的空格，DNS.x 的数量可以自己加（x可以是任意字符，只要不重复即可），common name的值也必须添加到这里，其他IP、email同DNS一样设置
# 至少要有一行，不能为空，上面的通用名commonName_default的值也要填写在这里
#
# 例如：
#   DNS.1 = test.lan
#   DNS.2 = *.test.lan
#   DNS.3 = docker-repo
#   IP.1 = 192.168.7.1
#   IP.2 = 192.168.7.2
#   email.1 = copy         #--- 代表从用户信息复制
#   email.2 = xx@yy.zz
#
`echo "$alt_names"`



####################################################################
[ v3_ca ]
# 典型CA扩展
# Extensions for a typical CA


# PKIX推荐
# PKIX recommendation.
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer


# 这是PKIX建议，但一些损坏的软件会被关键的扩展阻塞，所以我们将[critical,CA:true]替换为[CA:true]
# This is what PKIX recommends but some broken software chokes on critical
# extensions.
#basicConstraints = critical,CA:true
# So we do this instead.
basicConstraints = CA:true
# pathlen代表CA路径层数，CA最多有2层:CA->subCA1-Subca2->End User Certificate
#basicConstraints = critical,CA:TRUE,pathlen:2


# 密钥用法：这是一个典型的CA证书，然而，由于它将阻止它被用作测试自签名证书，因此在默认情况下最好不要使用它
# (zhf_sy)但如果把它当做CA来用，这个就必须被启用，因为它将作为CA自签名证书，或者作为CA给别人签名证书
# Key usage: this is typical for a CA certificate. However since it will
# prevent it being used as an test self-signed certificate it is best
# left out by default.
#keyUsage = cRLSign,keyCertSign
keyUsage = nonRepudiation,keyCertSign,cRLSign


## Netscape证书类型，现在已经被【basicConstraints、keyUsage、extendedKeyUsage】替代
## 参考：https://www.openssl.org/docs/manmaster/man5/x509v3_config.html
## Some might want this also
##nsCertType = sslCA,emailCA


# PKIX另一个建议：在主题备用名称中包含电子邮件地址
# Include email address in subject alt name: another PKIX recommendation
#subjectAltName = email:copy
# 拷贝发行人信息
# Copy issuer details
#issuerAltName = issuer:copy


# DER 十六进制编码扩展（供高手小心使用）
# DER hex encoding of an extension: beware experts only!
#obj = DER:02:03
# 当“obj”是标准或添加的对象，您甚至可以覆盖受支持的扩展
# Where 'obj' is a standard or added object
# You can even override a supported extension:
#basicConstraints = critical,DER:30:03:01:01:FF



####################################################################
# 证书吊销列表扩展
[ crl_ext ]
# CRL extensions.

# 仅issuerAltName 和 authorityKeyIdentifier 在crl中有意义
# Only issuerAltName and authorityKeyIdentifier make any sense in a CRL.
#issuerAltName = issuer:copy
authorityKeyIdentifier = keyid:always



####################################################################
# 代理证书扩展
# 内容与证书扩展[usr_cert]相同
[ proxy_cert_ext ]
# These extensions should be added when creating a proxy certificate


# 虽然这违反了PKIX指南，但是为了避免误解，添加此项，显式标明是CA，还是非CA
#     为非CA证书签名时设置为：         CA:FALSE
#     为CA证书签名时（包含CA自签名）： CA:TRUE
# This goes against PKIX guidelines but some CAs do it and some software
# requires this to avoid interpreting an end user certificate as a CA.
#basicConstraints = CA:FALSE     #--- 我不想启用它


# 颁发典型客户端证书的秘钥用法：
#     - nonRepudiation    不可抵赖
#     - digitalSignature  数字签名 
#     - keyEncipherment   秘钥加密
# This is typical in keyUsage for a client certificate.
#keyUsage = nonRepudiation,digitalSignature,keyEncipherment


## Netscape证书类型，现在已经被【basicConstraints、keyUsage、extendedKeyUsage】替代
## 参考：https://www.openssl.org/docs/manmaster/man5/x509v3_config.html
## nsCertType证书类型的示例
## 类型包含：
##     - server   : 服务器SSL
##     - client   : 客户端
##     - email    : email
##     - objsign  : 对象签名
## 默认：如果省略，则证书可以是除【对象签名】之外的任何类型，即：server、client、email
## Here are some examples of the usage of nsCertType. If it is omitted
## the certificate can be used for anything *except* object signing.
#
## 服务器SSL签名
## This is OK for an SSL server.
##nsCertType = server
#
## 对象签名
## For an object signing certificate this would be used.
##nsCertType = objsign
#
## 典型客户端签名
## For normal client use this is typical
##nsCertType = client,email
#
## 客户端所有类型签名
## and for everything including object signing:
##nsCertType = client,email,objsign


# 显示在Netscape浏览器上的
# This will be displayed in Netscape's comment listbox.
nsComment = "OpenSSL Generated Certificate"


# 如果无害，则建议包含在所有证书中
# PKIX recommendations harmless if included in all certificates.
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer


# 这些是为【主题备用名称】和【发行人备用名称】用的
# This stuff is for subjectAltName and issuerAltname.
#
# 导入email地址
# Import the email address.
#subjectAltName = email:copy
# 生成不被弃用的符合PKIX标准的证书（根据 PKIX标准 生成不被弃用的证书的替代方法）
# An alternative to produce certificates that aren't
# deprecated according to PKIX.
#subjectAltName = email:move
#
# 复制主题详细信息
# Copy subject details
#issuerAltName = issuer:copy


# CA相关Url
#nsCaRevocationUrl = http://www.domain.dom/ca.crl.pem
#nsBaseUrl         =
#nsRevocationUrl   =
#nsRenewalUrl      =
#nsCaPolicyUrl     =
#nsSslServerName   =


# 代理证书所必需
# This really needs to be in place for it to be a proxy certificate.
proxyCertInfo = critical,language:id-ppl-anyLanguage,pathlen:3,policy:foo



####################################################################
[ tsa ]
# 调用段：tsa_config1
default_tsa = tsa_config1   # the default TSA section


####################################################################
[ tsa_config1 ]

# These are used by the TSA reply generation only.
dir     = ./demoCA      # TSA root directory
serial      = \$dir/tsaserial   # The current serial number (mandatory)
crypto_device   = builtin       # OpenSSL engine to use for signing
signer_cert = \$dir/tsacert.pem     # The TSA signing certificate
                    # (optional)
certs       = \$dir/cacert.pem  # Certificate chain to include in reply
                    # (optional)
signer_key  = \$dir/private/tsakey.pem # The TSA private key (optional)

default_policy  = tsa_policy1       # Policy if request did not specify it
                    # (optional)
other_policies  = tsa_policy2, tsa_policy3  # acceptable policies (optional)
digests     = sha1, sha256, sha384, sha512  # Acceptable message digests (mandatory)
accuracy    = secs:1, millisecs:500, microsecs:100  # (optional)
clock_precision_digits  = 0 # number of digits after dot. (optional)
ordering        = yes   # Is ordering defined for timestamps?
                # (optional, default: no)
tsa_name        = yes   # Must the TSA name be included in the reply?
                # (optional, default: no)
ess_cert_id_chain   = no    # Must the ESS cert id chain be included?
                # (optional, default: no)
    "
}



# 生成证书用法变量
F_CERT_USE_FOR_VAR()
{
    # Do
    case ${CERT_USE_FOR} in
        1|ca)
            export MY_KEY_USAGE_S='nonRepudiation,keyCertSign,cRLSign'
            export MY_EXTENDED_KEY_USAGE_S=''
            ;;
        2|code)
            export MY_KEY_USAGE_S='digitalSignature'
            export MY_EXTENDED_KEY_USAGE_S='codeSigning'
            ;;
        3|computer)
            export MY_KEY_USAGE_S='digitalSignature,keyAgreement'
            export MY_EXTENDED_KEY_USAGE_S='serverAuth'
            ;;
        4|webserver)
            export MY_KEY_USAGE_S='digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment,keyAgreement'
            export MY_EXTENDED_KEY_USAGE_S='serverAuth'
            ;;
        5|client)
            export MY_KEY_USAGE_S='digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment'
            export MY_EXTENDED_KEY_USAGE_S='clientAuth'
            ;;
        6|trustlist)
            export MY_KEY_USAGE_S='digitalSignature'
            export MY_EXTENDED_KEY_USAGE_S='msCTLSign'
            ;;
        7|timestamp)
            export MY_KEY_USAGE_S='digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment'
            export MY_EXTENDED_KEY_USAGE_S='timeStamping'
            ;;
        8|ipsec)
            export MY_KEY_USAGE_S='digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment'
            export MY_EXTENDED_KEY_USAGE_S='1.3.6.1.5.5.8.2.2'
            ;;
        9|email)
            export MY_KEY_USAGE_S='digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment'
            export MY_EXTENDED_KEY_USAGE_S='emailProtection'
            ;;
        10|smartcard)
            export MY_KEY_USAGE_S='digitalSignature,keyAgreement,decipherOnly'
            export MY_EXTENDED_KEY_USAGE_S='1.3.6.1.4.1.311.10.3.11,msEFS,1.3.6.1.4.1.311.20.2.2'
            ;;
        *)
            #echo -e "\n峰哥说：配置文件【/my_conf/env.sh--你的证书名称】中的参数【CERT_USE_FOR】设置错误，请检查\n"
            return 1
            ;;
    esac
    #
    return 0
}



