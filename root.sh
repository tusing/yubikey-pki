#!/bin/zsh

if [ -z "$1" ]; then
	echo "Create a root CA in your YubiKey, name-constrained to the provided domain."
	echo "Usage: $0 rootCaDomain";
	echo "Example 1: $0 localdomain"
	echo "Example 2: $0 example.com"
	exit
else
	echo "Creating a root in YubiKey for $1...";
fi
rootCaDomain=$1

mkdir -p $rootCaDomain
openssl genrsa -out $rootCaDomain/key.pem 2048
cat>$rootCaDomain/crt.conf<<EOF
[ req ]
x509_extensions = v3_ca
distinguished_name = req_distinguished_name
prompt = no
[ req_distinguished_name ]
CN=$rootCaDomain Root CA
[ v3_ca ]
subjectKeyIdentifier=hash
basicConstraints=critical,CA:true,pathlen:1
keyUsage=critical,keyCertSign,cRLSign
nameConstraints=critical,@nc
[ nc ]
permitted;otherName=1.3.6.1.5.5.7.8.7;IA5:$rootCaDomain
permitted;email.0=$rootCaDomain
permitted;email.1=.$rootCaDomain
permitted;DNS=$rootCaDomain
permitted;URI.0=$rootCaDomain
permitted;URI.1=.$rootCaDomain
permitted;IP.0=0.0.0.0/255.255.255.255
permitted;IP.1=::/ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
EOF

openssl req -new -sha256 -x509 -set_serial 1 -days 7300 -config $rootCaDomain/crt.conf -key $rootCaDomain/key.pem -out $rootCaDomain/crt.pem
echo 01 > $rootCaDomain/crt.srl

echo WARNING: Slot 9c on your YubiKey PIV application will be overwritten!
yubico-piv-tool -k $key -a import-key -s 9c --pin-policy=always --touch-policy=always < $rootCaDomain/key.pem
yubico-piv-tool -k $key -a import-certificate -s 9c < $rootCaDomain/crt.pem
rm $rootCaDomain/key.pem
openssl x509 -in $rootCaDomain/crt.pem -text -noout

echo "Adding the root CA to your trust store:"
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $rootCaDomain/crt.pem