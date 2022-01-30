#!/bin/zsh

mkdir -p root
openssl genrsa -out root/key.pem 2048
cat>root/crt.conf<<EOF
[ req ]
x509_extensions = v3_ca
distinguished_name = req_distinguished_name
prompt = no
[ req_distinguished_name ]
CN=Yubico Internal HTTPS CA
[ v3_ca ]
subjectKeyIdentifier=hash
basicConstraints=critical,CA:true,pathlen:1
keyUsage=critical,keyCertSign,cRLSign
nameConstraints=critical,@nc
[ nc ]
permitted;otherName=1.3.6.1.5.5.7.8.7;IA5:yubico.com
permitted;email.0=yubico.com
permitted;email.1=.yubico.com
permitted;DNS=yubico.com
permitted;URI.0=yubico.com
permitted;URI.1=.yubico.com
permitted;IP.0=0.0.0.0/255.255.255.255
permitted;IP.1=::/ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
EOF
openssl req -new -sha256 -x509 -set_serial 1 -days 7300 -config root/crt.conf -key root/key.pem -out root/crt.pem
echo 01 > root/crt.srl

echo WARNING: Slot 9c on your YubiKey PIV application will be overwritten!
yubico-piv-tool -k $key -a import-key -s 9c --pin-policy=always --touch-policy=always < root/key.pem
yubico-piv-tool -k $key -a import-certificate -s 9c < root/crt.pem
rm root/key.pem
openssl x509 -in root/crt.pem -text -noout
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain root/crt.pem