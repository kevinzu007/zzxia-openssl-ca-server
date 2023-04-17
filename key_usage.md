# 密钥用法
#> 参考：https://my.oschina.net/u/3385288/blog/4641015
#
#有待完善
#| 序号 | 类别     | 参数值                  | 英文名称                                         | 中文名称                                           |
#| ---- | :------- | :---------------------- | :----------------------------------------------- | :------------------------------------------------- |
| 1    | normal   | digitalSignature        | Digital Signature                                | 数字签名                                           |
| 2    | normal   | nonRepudiation          | Non Repudiation                                  | 认可签名                                           |
| 3    | normal   | keyEncipherment         | key Encipherment                                 | 密钥加密                                           |
| 4    | normal   | dataEncipherment        | Data Encipherment                                | 数据加密                                           |
| 5    | normal   | keyAgreement            | key Agreement                                    | 密钥协商                                           |
| 6    | normal   | keyCertSign             | Key CertSign                                     | 证书签名                                           |
| 7    | normal   | cRLSign                 | Crl Sign                                         | CRL 签名                                           |
| 8    | normal   | encipherOnly            | Encipher Only                                    | 仅仅加密                                           |
| 9    | normal   | decipherOnly            | Decipher Only                                    | 仅仅解密                                           |
| 10   | extended | serverAuth              | TLS Web Server Authentication                    | SSL/TLS Web服务器身份验证                          |
| 11   | extended | clientAuth              | SSL/TLS Web Client Authentication                | SSL/TLS Web客户端身份验证                          |
| 12   | extended | codeSigning             | Code signing                                     | 代码签名                                           |
| 13   | extended | emailProtection         | E-mail Protection (S/MIME)                       | 安全电子邮件 (S/MIME)                              |
| 14   | extended | timeStamping            | Trusted Timestamping                             | 时间戳                                             |
| 15   | extended | msCodeInd               | Microsoft Individual Code Signing (authenticode) | Microsoft 个人代码签名 (authenticode)              |
| 16   | extended | msCodeCom               | Microsoft Commercial Code Signing (authenticode) | Microsoft 商业代码签名 (authenticode)              |
| 17   | extended | msCTLSign               | Microsoft Trust List Signing                     | Microsoft 信任列表签名 (1.3.6.1.4.1.311.10.3.1)    |
| 18   | extended | msSGC                   | Microsoft Server Gated Crypto                    | Microsoft 服务器门控加密                           |
| 19   | extended | msEFS                   | Microsoft Encrypted File System                  | Microsoft 加密文件系统 (1.3.6.1.4.1.311.10.3.4)    |
| 20   | extended | nsSGC                   | Netscape Server Gated Crypto                     | Netscape 服务器门控加密                            |
| 21   |          | 2.5.29.32.0             | X509v3 Any Policy                                | 所有颁发的策略 (2.5.29.32.0)                       |
| 22   |          | 1.3.6.1.4.1.311.10.3.10 |                                                  | 合格的部属 (1.3.6.1.4.1.311.10.3.10)               |
| 23   |          | 1.3.6.1.4.1.311.10.3.11 |                                                  | 密钥恢复 (1.3.6.1.4.1.311.10.3.11)                 |
| 24   |          | 1.3.6.1.4.1.311.10.6.2  |                                                  | 许可证服务器确认 (1.3.6.1.4.1.311.10.6.2)          |
| 25   |          | 1.3.6.1.4.1.311.10.3.13 |                                                  | 生存时间签名 (1.3.6.1.4.1.311.10.3.13)             |
| 26   |          |                         |                                                  | 文件恢复 (1.3.6.1.4.1.311.10.3.4.1)                |
| 27   |          |                         |                                                  | 根列表签名者 (1.3.6.1.4.1.311.10.3.9)              |
| 28   |          |                         |                                                  | 数字权利 (1.3.6.1.4.1.311.10.5.1)                  |
| 29   |          |                         |                                                  | 密钥数据包许可证 (1.3.6.1.4.1.311.10.6.1)          |
| 30   |          |                         |                                                  | 文档签名 (1.3.6.1.4.1.311.10.3.12)                 |
| 31   |          |                         |                                                  | 证书申请代理 (1.3.6.1.4.1.311.20.2.1)              |
| 32   |          |                         |                                                  | 私钥存档 (1.3.6.1.4.1.311.21.5)                    |
| 33   |          |                         |                                                  | 密钥恢复代理 (1.3.6.1.4.1.311.21.6)                |
| 34   |          |                         |                                                  | 目录服务电子邮件复制 (1.3.6.1.4.1.311.21.19)       |
| 35   |          |                         |                                                  | IP 安全用户 (1.3.6.1.5.5.7.3.7)                    |
| 36   |          |                         |                                                  | IP 安全 IKE 中级 (1.3.6.1.5.5.8.2.2)               |
| 37   |          |                         |                                                  | IP 安全终端系统 (1.3.6.1.5.5.7.3.5)                |
| 38   |          |                         |                                                  | IP 安全隧道终止 (1.3.6.1.5.5.7.3.6)                |
| 39   |          |                         |                                                  | OEM Windows 系统组件验证 (1.3.6.1.4.1.311.10.3.7)  |
| 40   |          |                         |                                                  | 内嵌 Windows 系统组件验证 (1.3.6.1.4.1.311.10.3.8) |
| 41   |          |                         |                                                  | Windows 系统组件验证 (1.3.6.1.4.1.311.10.3.6)      |
| 41   |          |                         |                                                  | Windows 硬件驱动程序验证 (1.3.6.1.4.1.311.10.3.5)  |
| 43   | extended | 1.3.6.1.4.1.311.20.2.2  |                                                  | Microsoft智能卡登录 (1.3.6.1.4.1.311.20.2.2)       |
| 44   |          | 1.3.6.1.4.1.311.10.3.2  |                                                  | Microsoft 时间戳 (1.3.6.1.4.1.311.10.3.2)          |

