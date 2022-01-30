#!/bin/zsh

# Usage
if [ -z "$1" ]; then
	echo "$0 your_url";
	exit
else
	echo "Creating a key pair for $1...";
fi
host=$1

# Use the homebrew-provided openssl
alias openssl=/opt/homebrew/opt/openssl@1.1/bin/openssl

# Create a directory for the target host's files
mkdir -p $host

# Generate the target host's key pair
openssl genrsa -out $host/key.pem 4096

# Create the CSR
cat>$host/csr.conf<<EOF
[ req ]
distinguished_name = req_distinguished_name
prompt = no
[ req_distinguished_name ]
CN=$host
EOF
openssl req -sha256 -new -config $host/csr.conf -key $host/key.pem -nodes -out $host/csr.pem

# Define the certificate configuration
cat>$host/crt.conf<<EOF
basicConstraints=critical,CA:false
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=critical,serverAuth
subjectAltName=critical,DNS:$host
EOF

# Sign the CSR and output the certificate
openssl << EOF
engine dynamic -pre SO_PATH:/opt/homebrew/Cellar/libp11/0.4.11/lib/engines-1.1/pkcs11.dylib -pre ID:pkcs11 -pre NO_VCHECK:1 -pre LIST_ADD:1 -pre LOAD -pre MODULE_PATH:/Library/OpenSC/lib/opensc-pkcs11.so -pre VERBOSE
x509 -engine pkcs11 -CAkeyform engine -sha512 -CAkey slot_0-id_2 -CA root/crt.pem -req -passin pass:$pin -in $host/csr.pem -extfile $host/crt.conf -days $(( ( RANDOM % 1000 )  + 365*50 )) -out $host/crt.pem
EOF
openssl x509 -text < $host/crt.pem