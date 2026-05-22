# sediment-cli-releases

> Public release mirror for the **Sediment CLI** — the command-line client for the [Sediment](https://sediment.hypeproof-ai.xyz) evidence-grounded memory layer.
>
> Source code lives in the (private) `jayleekr/sediment` monorepo. Binaries are mirrored here so they can be downloaded without a GitHub token.

## Install

### Homebrew (macOS + Linux)

```bash
brew install jayleekr/sediment/sediment
```

### One-line install script (any Unix)

```bash
curl -fsSL https://raw.githubusercontent.com/jayleekr/sediment-cli-releases/main/install.sh | bash
```

The script:
- Detects your OS + arch (macOS arm64, macOS x86_64, Linux x86_64)
- Downloads the matching tarball from the latest release
- Verifies the SHA256
- Installs to `~/.local/bin/sediment` (or `/usr/local/bin/` if writable)
- Prints PATH instructions if needed

### Manual download

If you prefer a click-and-untar workflow:

1. Open the [latest release](https://github.com/jayleekr/sediment-cli-releases/releases/latest)
2. Pick your platform:
   - `sediment-aarch64-apple-darwin.tar.gz` → Apple Silicon Mac
   - `sediment-x86_64-apple-darwin.tar.gz` → Intel Mac
   - `sediment-x86_64-unknown-linux-gnu.tar.gz` → Linux
3. Extract and move to a directory on your `PATH`:
   ```bash
   tar xzf sediment-*-*.tar.gz
   sudo mv sediment /usr/local/bin/
   sediment --version
   ```

Each binary ships with a `.sha256` companion file — verify before extracting if you're paranoid:
```bash
shasum -a 256 -c sediment-aarch64-apple-darwin.tar.gz.sha256
```

## First use

```bash
sediment login                 # browser OAuth (GitHub)
sediment ask "what did we decide about X last week"
```

See the [Sediment app](https://sediment.hypeproof-ai.xyz) for what you're connecting to.

## Updating

```bash
# Homebrew users
brew update && brew upgrade sediment

# install.sh users
curl -fsSL https://raw.githubusercontent.com/jayleekr/sediment-cli-releases/main/install.sh | bash
# (the script is idempotent — re-running pulls the latest release)
```

## Uninstall

```bash
# Homebrew
brew uninstall sediment

# install.sh
rm -f ~/.local/bin/sediment /usr/local/bin/sediment
```

## Why a separate repo?

The Sediment source code is in a private monorepo. Public download URLs from a private repo return 404 — every download would need a GitHub token. To keep CLI install painless for teammates and tenants, this public sibling repo carries only the release artifacts. CD in the private repo mirrors each tagged release here.

## Releasing

The release pipeline lives in `jayleekr/sediment/.github/workflows/sediment-cli-release.yml`. Push a tag `sediment-cli-v*` to that repo and:
1. Build runs on three runners (macOS arm, macOS Intel, Linux x86)
2. Artifacts are uploaded to the source repo's release
3. The same artifacts are mirrored here via `gh release create`

No manual steps in this repo for routine releases. Manual edits to `install.sh` land here directly.

## License

MIT — same as the source repo.
