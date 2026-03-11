#!/bin/bash
set -euo pipefail

# Generate a GPG key with a passphrase for use with nfpm signing.
# The passphrase is "example".

GNUPGHOME="$(mktemp -d)"
export GNUPGHOME

cat >key-config <<EOF
%echo Generating GPG key for nfpm signing example
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: Example
Name-Email: example@goreleaser.com
Passphrase: example
Expire-Date: 0
%commit
%echo Done
EOF

gpg --batch --gen-key key-config
gpg --batch --pinentry-mode loopback --passphrase "example" --armor --export-secret-keys example@goreleaser.com >gpg.asc
rm key-config

echo "Key exported to gpg.asc"
echo "Passphrase: example"

openssl genrsa -traditional -out apk.rsa 4096
openssl rsa -in apk.rsa -pubout -out apk.rsa.pub

echo "APK key exported to apk.rsa (private) and apk.rsa.pub (public)"
