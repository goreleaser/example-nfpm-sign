# example-nfpm-sign

Example GoReleaser project demonstrating nfpm package signing.

Generates signed `.deb`, `.rpm`, and `.apk` packages.

- **deb/rpm** are signed with a passphrase-protected GPG key.
- **apk** is signed with a passphrase-protected RSA PEM key.

## Setup

### 1. Generate signing keys

```bash
./scripts/genkeys.sh
```

This creates:

- `gpg.asc` — armored GPG private key with the passphrase `example` (for deb/rpm)
- `apk.rsa` — passphrase-protected RSA private key in PEM format (for apk)
- `apk.rsa.pub` — corresponding public key

### 2. Configure GitHub secrets

| Secret           | Value                              |
| ---------------- | ---------------------------------- |
| `GPG_KEY`        | Contents of `gpg.asc`              |
| `GPG_PASSPHRASE` | The GPG key passphrase (`example`) |
| `APK_KEY`        | Contents of `apk.rsa`              |
| `APK_PASSPHRASE` | The APK key passphrase (`example`) |

### 3. Run locally

```bash
./scripts/genkeys.sh
NFPM_DEFAULT_PASSPHRASE=example goreleaser r --clean --snapshot
```

> [!NOTE]
> If you need different password for each format, you'll need to set
> `NFPM_{FORMAT}_PASSPHRASE` instead.

### 4. Release

Tag and push:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The [release workflow](.github/workflows/release.yml) writes both keys to disk,
which GoReleaser picks up via its configuration.
The GPG passphrase is provided through `NFPM_DEFAULT_PASSPHRASE` and the APK
key passphrase through `NFPM_APK_PASSPHRASE`.

> [!IMPORTANT]
> You should, of course, use your own keys in production, with a proper
> password.

## How it works

GoReleaser resolves the signing passphrase from environment variables in this order:

1. `NFPM_{APK,DEB,RPM}_PASSPHRASE` (format-specific)
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
