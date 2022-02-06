#!/usr/bin/env bash
set -eou pipefail
# ARG_POSITIONAL_SINGLE([endpoint_domain],[subdomain to generate the certs for (e.g. 'foo' for 'foo.example.com')],[])
# ARG_POSITIONAL_SINGLE([root_domain],[domain of the root CA (e.g. 'example.com' for 'foo.example.com')],[])
# ARG_OPTIONAL_SINGLE([ttl],[],[endpoint CA ttl in days],[820])
# ARG_HELP([Generate an X.509 cert pair for the specified endpoint and load it into your YubiKey.])
# ARGBASH_GO()
# needed because of Argbash --> m4_ignore([
### START OF CODE GENERATED BY Argbash v2.10.0 one line above ###
# Argbash is a bash code generator used to get arguments parsing right.
# Argbash is FREE SOFTWARE, see https://argbash.io for more info

die() {
	local _ret="${2:-1}"
	test "${_PRINT_HELP:-no}" = yes && print_help >&2
	echo "$1" >&2
	exit "${_ret}"
}

begins_with_short_option() {
	local first_option all_short_options='h'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - POSITIONALS
_positionals=()
# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_ttl="820"

print_help() {
	printf '%s\n' "Generate an X.509 cert pair for the specified endpoint and load it into your YubiKey."
	printf 'Usage: %s [--ttl <arg>] [-h|--help] <endpoint_domain> <root_domain>\n' "$0"
	printf '\t%s\n' "<endpoint_domain>: subdomain to generate the certs for (e.g. 'foo' for 'foo.example.com')"
	printf '\t%s\n' "<root_domain>: domain of the root CA (e.g. 'example.com' for 'foo.example.com')"
	printf '\t%s\n' "--ttl: endpoint CA ttl in days (default: '820')"
	printf '\t%s\n' "-h, --help: Prints help"
}

parse_commandline() {
	_positionals_count=0
	while test $# -gt 0; do
		_key="$1"
		case "$_key" in
		--ttl)
			test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
			_arg_ttl="$2"
			shift
			;;
		--ttl=*)
			_arg_ttl="${_key##--ttl=}"
			;;
		-h | --help)
			print_help
			exit 0
			;;
		-h*)
			print_help
			exit 0
			;;
		*)
			_last_positional="$1"
			_positionals+=("$_last_positional")
			_positionals_count=$((_positionals_count + 1))
			;;
		esac
		shift
	done
}

handle_passed_args_count() {
	local _required_args_string="'endpoint_domain' and 'root_domain'"
	test "${_positionals_count}" -ge 2 || _PRINT_HELP=yes die "FATAL ERROR: Not enough positional arguments - we require exactly 2 (namely: $_required_args_string), but got only ${_positionals_count}." 1
	test "${_positionals_count}" -le 2 || _PRINT_HELP=yes die "FATAL ERROR: There were spurious positional arguments --- we expect exactly 2 (namely: $_required_args_string), but got ${_positionals_count} (the last one was: '${_last_positional}')." 1
}

assign_positional_args() {
	local _positional_name _shift_for=$1
	_positional_names="_arg_endpoint_domain _arg_root_domain "

	shift "$_shift_for"
	for _positional_name in ${_positional_names}; do
		test $# -gt 0 || break
		eval "$_positional_name=\${1}" || die "Error during argument parsing, possibly an Argbash bug." 1
		shift
	done
}

parse_commandline "$@"
handle_passed_args_count
assign_positional_args 1 "${_positionals[@]}"

# OTHER STUFF GENERATED BY Argbash

### END OF CODE GENERATED BY Argbash (sortof) ### ])
# [ <-- needed because of Argbash

if [ $_arg_ttl -gt 825 ]; then
	echo WARNING: Setting a certificate TTL longer than 825 days can lead trust warnings within some browsers.
fi

# Specify host
host=$_arg_endpoint_domain.$_arg_root_domain

# Specify paths
outDir=$_arg_root_domain/$_arg_endpoint_domain
key=$outDir/key.pem
csr=$outDir/csr.pem
csrConf=$outDir/csr.conf
crt=$outDir/crt.pem
crtConf=$outDir/crt.conf

echo Creating a key pair for $host

stat $_arg_root_domain &>/dev/null || {
	echo ERROR: Could not find directory for root CA.
	exit 1
}

stat $outDir &>/dev/null && {
	echo ERROR: $outDir already exists.
	exit 1
}

mkdir $outDir

# Generate the target host's key pair
openssl genrsa -out $key 2048

# Create the CSR
cat >$csrConf <<EOF
[ req ]
distinguished_name = req_distinguished_name
prompt = no
[ req_distinguished_name ]
CN=$host
EOF

openssl req -sha256 -new -config $csrConf -key $key -nodes -out $csr

# Define the certificate configuration
cat >$crtConf <<EOF
basicConstraints = critical,CA:false
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=critical,serverAuth
subjectAltName=critical,DNS:$host
EOF

echo NOTE: If your YubiKey starts blinking, touch it.

# Sign the CSR and output the certificate
openssl <<EOF
engine dynamic -pre SO_PATH:$SO_PATH -pre ID:pkcs11 -pre NO_VCHECK:1 -pre LIST_ADD:1 -pre LOAD -pre MODULE_PATH:$MODULE_PATH -pre VERBOSE
x509 -engine pkcs11 -CAkeyform engine -sha256 -CAkey slot_0-id_2 -CA $_arg_root_domain/crt.pem -req -in $csr -extfile $crtConf -days $_arg_ttl -out $crt
EOF

echo NOTE: You can inspect your certificate file with
echo \# On Nix:
echo "$ nix-shell --run \"openssl x509 -text <$crt\""
echo \# Otherwise:
echo "$ openssl x509 -text <$crt"

echo WARNING: DO NOT forget to delete the private key here after exporting it to your endpoint.

# ] <-- needed because of Argbash
