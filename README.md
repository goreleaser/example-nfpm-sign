# example-nfpm-sign

Example GoReleaser project demonstrating nfpm package signing.

Generates signed `.deb`, `.rpm`, and `.apk` packages.

- **deb/rpm** are signed with a passphrase-protected GPG key.
- **apk** is signed with an RSA PEM key.

## Setup

### 1. Generate signing keys

```bash
./scripts/genkeys.sh
```

This creates:

- `gpg.asc` — armored GPG private key with the passphrase `example` (for deb/rpm)
- `apk.rsa` — RSA private key in PEM format (for apk)
- `apk.rsa.pub` — corresponding public key

### 2. Configure GitHub secrets

| Secret           | Value                          |
| ---------------- | ------------------------------ |
| `GPG_KEY`        | Contents of `gpg.asc`          |
| `GPG_PASSPHRASE` | The key passphrase (`example`) |
| `APK_KEY`        | Contents of `apk.rsa`          |

### 3. Run locally

```bash
./scripts/genkeys.sh
NFPM_DEFAULT_PASSPHRASE=example goreleaser r --clean --snapshot
```

### 4. Release

Tag and push:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The [release workflow](.github/workflows/release.yml) writes both keys to disk,
which GoReleaser picks up via its configuration.
The GPG passphrase is provided through `NFPM_DEFAULT_PASSPHRASE`.

> [!IMPORTANT]
> You should, of course, use your own keys in production, with a proper
> password.

## How it works

GoReleaser resolves the signing passphrase from environment variables in this order:

1. `NFPM_DEFAULT_DEB_PASSPHRASE` (format-specific)
2. `NFPM_DEFAULT_PASSPHRASE` (id-specific)
3. `NFPM_PASSPHRASE` (global)

See the [nfpm docs](https://goreleaser.com/customization/nfpm/) for full configuration reference.

## Verifying signatures

After building, you can verify the packages are signed:

**deb** (a signed `.deb` contains a `_gpgorigin` member):

```bash
for f in dist/*.deb; do
  echo "$f:"
  ar t "$f" | grep _gpgorigin
done
```

**rpm:**

```bash
docker run --rm -v "$PWD/dist:/dist" fedora:latest bash -c \
  "rpm -qpi /dist/*.rpm | grep -i signature"
```

**apk** (a signed `.apk` contains a `.SIGN.RSA.*` entry):

```bash
for f in dist/*.apk; do
  echo "$f:"
  tar -tzf "$f" | grep -i sign
done
```
