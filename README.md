# yubikey_pki

This quick and dirty script uses your YubiKey as a CA to generate TLS certificates for hosts on my local (home network) domains.

Do NOT use this in production. This was just a few commands I whipped together to *marginally* improve the security of accessing servers over my local network. Namely, this flow

- Has no intermediate CA
- Generates certificates with long lifetimes
- Doesn't support rotation
- Doesn't support any customization of the domain's certificate
- Generates the endpoint's key pair locally instead of accepting a CSR

## 0. Install Prerequisites

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

Generate the root CA, and import it to your YubiKey:

```bash
# Warning, this overwrites slot 9c on your YubiKey!
./root.sh
```

Add this root CA to the trusted root CA store on each device. For macOS:

```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain root/crt.pem
```

## 2. Generate the certificates

1. Simply run `./endpoint.sh your_domain`, e.g. `./endpoint.sh raspberrypi.localdomain`.
2. When the YubiKey starts flashing, touch it.
3. Provide `your_domain/crt.pem` and `your_domain/key.pem` to the destination server.
4. Finally, delete `your_domain/key.pem`.
