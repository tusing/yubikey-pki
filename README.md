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

## 0. Prerequisites

The following dependencies are required:

- openssl@1.1
- opensc
- libp11
- ykman

### Using Nix

[Nix Package Manager](https://nixos.org/download.html) is **strongly
recommended.** If you're using Nix, dependencies will be autoloaded
just for this project in a manner that does not pollute your environment.

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

### Using Brew

```bash
brew install openssl@1.1 homebrew/cask/opensc libp11 ykman
```

## 1. Set Up Your YubiKey

Set up the YubiKey PIV application on your YubiKey.
First, change the default PIN, PUK, and Management Key, and save the values somewhere:

```bash
nix-shell # (if you're using Nix)
ykman piv access change-management-key
ykman piv access change-pin
ykman piv access change-puk
```

## 2. Create a Root CA

Generate the root CA for the root of your choice, and import it to your YubiKey.
This will **overwrite slot 9c** on your YubiKey's PIV application.

To create a root CA for `example.com`:

```bash
# Using Nix:
nix-shell --run "./root.sh example.com"

# Otherwise:
./root.sh example.com
```

This script will create a CA name-restricted to example.com, with a
lifetime of 20 years, import it to your YubiKey, delete the private key,
and give you a command to add the certificate to macOS Keychain for
compatibility with Safari.

To add the cert to Firefox, go to `Settings -> Security -> Certificates -> View Certificates`,
and add `example.com/crt.pem` to the `Authorities` section.

## 3. Generate subdomain certificates

To generate a public/private key pair for `foo.example.com`:

```bash
# Using Nix:
nix-shell --run "./endpoint.sh foo example.com"

# Otherwise:
# (you might have to adjust the lib paths)
export SO_PATH="/opt/homebrew/Cellar/libp11/0.4.11/lib/engines-1.1/pkcs11.dylib"
export MODULE_PATH="Library/OpenSC/lib/opensc-pkcs11.so"
./endpoint.sh foo example.com
```

1. Input your YubiKey PIV PIN when prompted. Touch the disk when it starts flashing.
2. Provide `example.com/foo/crt.pem` and `example.com/foo/key.pem` to your endpoint.
3. Delete `example.com/foo/key.pem`.

This creates a certificate for `foo.example.com` with a lifetime of 820 days in `example.com/foo`.
