#!/usr/bin/env bash
set -eou pipefail

# Usage
if [ $# -lt 2 ]; then
	echo "Create a certificate for endpoint.rootCaDomain and get it signed by the Root CA in the YubiKey."
	echo "Usage: $0 endpoint rootCaDomain"
	echo "Example 1: $0 raspberrypi localdomain"
	echo "Example 2: $0 foo example.com"
	exit
fi

endpoint=$1
rootCaDomain=$2
host=$endpoint.$rootCaDomain
outDir=$rootCaDomain/$endpoint

echo "Creating a key pair for $host"
stat $rootCaDomain &>/dev/null || {
	echo "Could not find directory for root CA."
	exit 1
}
stat $outDir &>/dev/null || echo "Warning! $outDir already exists."
mkdir -p $outDir

# Generate the target host's key pair
openssl genrsa -out $outDir/key.pem 2048

# Create the CSR
cat >$outDir/csr.conf <<EOF
[ req ]
distinguished_name = req_distinguished_name
prompt = no
[ req_distinguished_name ]
CN=$host
EOF

openssl req -sha256 -new -config $outDir/csr.conf -key $outDir/key.pem -nodes -out $outDir/csr.pem

# Define the certificate configuration
cat >$outDir/crt.conf <<EOF
basicConstraints = critical,CA:false
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=critical,serverAuth
subjectAltName=critical,DNS:$host
EOF

# Sign the CSR and output the certificate
openssl <<EOF
engine dynamic -pre SO_PATH:$SO_PATH -pre ID:pkcs11 -pre NO_VCHECK:1 -pre LIST_ADD:1 -pre LOAD -pre MODULE_PATH:$MODULE_PATH -pre VERBOSE
x509 -engine pkcs11 -CAkeyform engine -sha256 -CAkey slot_0-id_2 -CA $rootCaDomain/crt.pem -req -in $outDir/csr.pem -extfile $outDir/crt.conf -days 820 -out $outDir/crt.pem
EOF

openssl x509 -text <$outDir/crt.pem

echo "WARNING: DO NOT forget to delete the private key after exporting"
