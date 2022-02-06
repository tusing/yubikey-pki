# yubikey-pki

This script uses your YubiKey as a CA to sign TLS certificates.

The benefits:

- Quickly and easily mint certificates
- A physical touch is required to mint any certificate
- No "certificate is not standards-compliant" error on iOS/macOS - the
generated certs adhere to Apple's requirements

The downsides:

- There is no intermediate CA
- No support for rotation
- No support for signing CSRs that aren't generated by this tool

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

This will **overwrite slot 9c** on your YubiKey's PIV application.

```
Generate an X.509 Root CA keypair for the specified domain and load it into your YubiKey.
Usage: ./root.sh [--(no-)keep-private-key] [--ttl <arg>] [-h|--help] <root_domain>
	<root_domain>: domain for the root CA
	--keep-private-key, --no-keep-private-key: keep the private key around after importing it to the YubiKey (off by default)
	--ttl: root CA ttl in days (default: '7300')
	-h, --help: Prints help
```

To create a root CA for `example.com` and load it into your YubiKey:

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

## 3. Generate endpoint subdomain certificates

```
Generate an X.509 cert pair for the specified endpoint, and sign the CSR with your YubiKey.
Usage: ./endpoint.sh [--ttl <arg>] [-h|--help] <endpoint_domain> <root_domain>
	<endpoint_domain>: subdomain to generate the certs for (e.g. 'foo' for 'foo.example.com')
	<root_domain>: domain of the root CA (e.g. 'example.com' for 'foo.example.com')
	--ttl: endpoint CA ttl in days (default: '820')
	-h, --help: Prints help
```

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

1. Input your YubiKey PIV PIN when prompted. Touch the YubiKey when it starts flashing.
2. Provide `example.com/foo/crt.pem` and `example.com/foo/key.pem` to your endpoint.
3. Delete `example.com/foo/key.pem`.

This creates a certificate for `foo.example.com` with a lifetime of 820 days in `example.com/foo`.
