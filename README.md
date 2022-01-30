# yubikey_pki

This quick and dirty script uses your YubiKey as a CA to sign TLS certificates.

Don't use this in production.

The benefits are as follows:

- A physical touch is required to mint a certificate for each endpoint
- Quickly and easily mint certificates for all local servers

The downsides are:

- There is no intermediate CA
- Doesn't support rotation
- Doesn't support any customization
- Generates the endpoint's key pair locally instead of accepting a CSR

This project is purely for fun.

## 0. Install Prerequisites

macOS is required.

```bash
brew install openssl@1.1 homebrew/cask/opensc libp11 ykman
```

Reasoning:

- OpenSSL is installed because the LibreSSL included with macOS was not compiled with custom engine support.
- OpenSC provides the OpenSSL module interface the smartcard.
- LibP11 provides the OpenSSL engine.
- ykman is necessary to provision your YubiKey.


## 1. Set Up Your YubiKey

Set up the YubiKey PIV application on your YubiKey. First, change the default PIN, PUK, and Management Key, and save the values somewhere:

```bash
ykman piv access change-management-key
ykman piv access change-pin
ykman piv access change-puk
```

Generate the root CA for the root of your choice, and import it to your YubiKey:

```bash
# Warning, this overwrites slot 9c on your YubiKey!
# To create a root CA for example.com: 
./root.sh example.com
```

This script will create a CA name-restricted to example.com, with a lifetime of 20 years, import it to your YubiKey, delete the private key, and add the certificate to macOS Keychain for compatibility with Safari.

To add the cert to Firefox, go to `Settings -> Security -> Certificates -> View Certificates`, and add `example.com/crt.pem` to the `Authorities` section.

## 2. Generate the certificates

```bash
# To create a certificate for foo.example.com:
./endpoint.sh foo example.com
```

1. Input your YubiKey PIV PIN when prompted. Touch the disk when it starts flashing.
2. Provide `example.com/foo/crt.pem` and `example.com/foo/key.pem` to your endpoint.
3. Delete `example.com/foo/key.pem`.