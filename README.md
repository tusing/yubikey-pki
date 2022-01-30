# yubikey_pki

This quick and dirty script uses your YubiKey as a CA to generate TLS certificates for hosts on my local (home network) domains.

Do NOT use this in production. This was just a few commands I whipped together to *marginally* improve the security of accessing servers over my local network. Namely, this flow

- Has no intermediate CA
- Generates certificates with long lifetimes
- Doesn't support rotation
- Doesn't support any customization of the domain's certificate

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

Generate the root CA on your YubiKey:

```bash
# Create the public/private key
ykman piv keys generate -a RSA2048 --pin-policy ALWAYS --touch-policy CACHED 9c slot_9c.pem
# Create the certificate, with a random expiry to prevent exploitation of any clock-related RNG bugs
ykman piv certificates generate -s "CN=YubiKey" -d $(( ( RANDOM % 1000 )  + 365*50 )) -a SHA512 9c slot_9c-crt.pem
# Begin the serial at 00
echo 00 > slot_9c-crt.srl
```

- Import `slot_9c-crt.pem` to your trusted root CA store on each device.
- Both `slot_9c-crt.pem` and `slot_9c-crt.srl` must be present.

## 2. Generate the certificates

Simply run `./script.sh your_domain`, e.g. `./script.sh raspberrypi.localdomain`.

Provide `your_domain/crt.pem` and `your_domain/key.pem` to the destination server.

Finally, delete `your_domain/key.pem`.
