# zzxia-openssl-ca-server

An OpenSSL-based CA (Certificate Authority) server management toolkit.

[中文文档](README.md)



## Introduction

Build your own private CA server to manage the entire certificate lifecycle: generate private keys, certificate signing requests (CSR), issue certificates, revoke certificates, renew certificates, and generate Certificate Revocation Lists (CRL).

It supports **10 predefined certificate types** including web server, code signing, client authentication, email (S/MIME), IPSec, smart card login, and more. Certificates are fully compatible with Windows, Linux, Android, and iOS.

The project is production-ready — no code modifications needed to manage the full CA lifecycle through simple configuration files.



## Features

1. Initialize CA server
2. Generate CA private key and self-signed certificate
3. Generate user private key and certificate (all-in-one)
4. Step-by-step: generate user private key, CSR, and certificate separately
5. Issue certificates for third-party CSR files
6. Renew certificates
7. Revoke certificates
8. Generate CA Certificate Revocation List (CRL)



## Supported Certificate Types

Set via the `CERT_USE_FOR` parameter in the configuration file:

| # | Value | Type | keyUsage | extendedKeyUsage |
|---|-------|------|----------|------------------|
| 1 | `ca` | CA Certificate | nonRepudiation, keyCertSign, cRLSign | - |
| 2 | `code` | Code Signing | digitalSignature | codeSigning |
| 3 | `computer` | Computer | digitalSignature, keyAgreement | serverAuth |
| 4 | `webserver` | Web Server | digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment, keyAgreement | serverAuth |
| 5 | `client` | Client Auth | digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment | clientAuth |
| 6 | `trustlist` | Trust List | digitalSignature | msCTLSign |
| 7 | `timestamp` | Timestamping | digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment | timeStamping |
| 8 | `ipsec` | IPSec | digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment | 1.3.6.1.5.5.8.2.2 |
| 9 | `email` | S/MIME Email | digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment | emailProtection |
| 10 | `smartcard` | Smart Card Login | digitalSignature, keyAgreement, decipherOnly | msEFS, 1.3.6.1.4.1.311.20.2.2 |

> To add custom certificate types, refer to `key_usage.md` and modify `F_CERT_USE_FOR_VAR` in `function.sh`.



## Requirements

- **OS**: Linux (tested on Ubuntu and CentOS 7)
- **Dependencies**: `openssl`, `bash`



## Quick Start

### 1. Clone and Initialize

```bash
git clone https://gitee.com/zhf_sy/zzxia-openssl-ca-server.git
cd zzxia-openssl-ca-server

# Initialize CA environment
./0-init_ca.sh -y
```

### 2. Configure and Create CA

```bash
# Create CA config from sample
cp ./my_conf/env.sh--CA.sample ./my_conf/env.sh--CA
vi ./my_conf/env.sh--CA    # Edit CA information

# Generate CA key and self-signed certificate
./1-generate_CA_key_and_crt.sh -y
```

### 3. Issue User Certificates

**All-in-one** (recommended for most cases):

```bash
# Create user config
cp ./my_conf/env.sh--model ./my_conf/env.sh--example.com
vi ./my_conf/env.sh--example.com   # Edit certificate info

# Generate key + CSR + certificate in one step
./m-3in1-generate_user_key-csr-crt.sh -n example.com

# With custom options
./m-3in1-generate_user_key-csr-crt.sh -n example.com -p 4096 -d 730
```

**Step-by-step**:

```bash
# Step 1: Generate private key
./m-1-generate_user_key.sh -n example.com

# Step 2: Generate CSR
./m-2-generate_user_csr.sh -n example.com

# Step 3: Issue certificate
./m-3-generate_user_crt.sh -n example.com
```

**Third-party CSR**:

```bash
./m-3-generate_user_crt.sh -f /path/to/external.csr -n example.com
```

### 4. Other Operations

```bash
# Renew certificate
./m-x-renew_user_crt.sh -n example.com

# Revoke certificate
./m-x-revoke_user_crt.sh -n example.com

# Generate/update CRL (run after revoking)
./m-x-generate_CA_crl.sh -y
```

> All scripts support `-h|--help` for detailed usage information.



## Scripts

| Script | Purpose |
|--------|---------|
| `0-init_ca.sh` | Initialize CA server environment |
| `1-generate_CA_key_and_crt.sh` | Generate CA private key and self-signed certificate |
| `m-1-generate_user_key.sh` | Generate user private key |
| `m-2-generate_user_csr.sh` | Generate user CSR |
| `m-3-generate_user_crt.sh` | Issue user certificate (supports external CSR) |
| `m-3in1-generate_user_key-csr-crt.sh` | All-in-one: key + CSR + certificate |
| `m-x-renew_user_crt.sh` | Renew certificate (symlink to `m-3-generate_user_crt.sh`) |
| `m-x-revoke_user_crt.sh` | Revoke user certificate |
| `m-x-generate_CA_crl.sh` | Generate/update CRL |
| `function.sh` | Shared function library |
| `test_ca.sh` | Automated test suite |



## Configuration

Configuration files are stored in `my_conf/`:

| File | Description |
|------|-------------|
| `env.sh--CA.sample` | CA config sample (copy to `env.sh--CA` before use) |
| `env.sh--model` | User certificate config template |
| `env.sh--test.lan` | Example user certificate config |

### Key Parameters

```bash
export PRIVATEKEY_BITS=${PRIVATEKEY_BITS:-2048}    # Private key length
export CERT_BITS=${CERT_BITS:-2048}                # Certificate key length
export CERT_DAYS=${CERT_DAYS:-365}                 # Certificate validity (days)
export CERT_MD=${CERT_MD:-sha256}                  # Signature digest algorithm
export commonName_default="example.com"            # Common Name (CN)
export CERT_USE_FOR='4'                            # Certificate type (4=webserver)

# Subject Alternative Names (SAN)
export alt_names=$(echo "
DNS.1 = example.com
DNS.2 = *.example.com
IP.1 = 192.168.1.1
")
```



## Testing

The project includes a comprehensive test suite covering the entire CA lifecycle:

```bash
bash test_ca.sh
```

Tests run in a temporary directory and do not affect project data.



## Contributing

1. Fork this repository
2. Create a `Feat_xxx` branch
3. Commit your changes
4. Submit a Pull Request



## License

[GNU GPLv3](LICENSE)
