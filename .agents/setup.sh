#!/usr/bin/env bash
set -euo pipefail

SWIFT_DEFAULT_VERSION="6.4.3"
SWIFTLINT_VERSION="0.65.1"

if [ -f .swift-version ]; then
  SWIFT_VERSION="$(tr -d '[:space:]' < .swift-version)"
else
  SWIFT_VERSION="$SWIFT_DEFAULT_VERSION"
fi

OS_NAME="$(uname -s)"

if [ "$OS_NAME" = "Linux" ]; then
  # 1. Install Ubuntu/Debian system packages required by Swift and SourceKit
  if command -v apt-get >/dev/null 2>&1; then
    REQUIRED_PKGS=(
      binutils
      build-essential
      curl
      git
      gnupg2
      libc6-dev
      libcurl4-openssl-dev
      libedit2
      libncurses-dev
      libpython3-dev
      libsqlite3-dev
      libxml2-dev
      libz3-dev
      pkg-config
      tzdata
      unzip
      zlib1g-dev
    )
    MISSING_PKGS=()
    for pkg in "${REQUIRED_PKGS[@]}"; do
      if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        MISSING_PKGS+=("$pkg")
      fi
    done

    if [ "${#MISSING_PKGS[@]}" -gt 0 ]; then
      SUDO_CMD=()
      if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
        SUDO_CMD=(sudo)
      fi
      "${SUDO_CMD[@]}" env DEBIAN_FRONTEND=noninteractive apt-get update -y
      "${SUDO_CMD[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${MISSING_PKGS[@]}"
    fi
  fi

  # 2. Configure ~/.bashrc so non-interactive shells inherit PATH and SourceKit settings
  touch "$HOME/.bashrc"
  sed -i '/case \$- in/,/esac/d' "$HOME/.bashrc" 2>/dev/null || true

  # 3. Install swiftly and the target Swift toolchain in ~/.local/share/swiftly
  if [ ! -x "$HOME/.local/share/swiftly/bin/swiftly" ]; then
    TMP_SWIFTLY="$(mktemp -d)"
    curl -fsSL "https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz" | tar -xz -C "$TMP_SWIFTLY"
    "$TMP_SWIFTLY/swiftly" init --no-modify-profile --quiet-shell-followup --skip-install --assume-yes
    rm -rf "$TMP_SWIFTLY"
  fi

  # shellcheck source=/dev/null
  [ -f "$HOME/.local/share/swiftly/env.sh" ] && . "$HOME/.local/share/swiftly/env.sh"

  if [ ! -x "$HOME/.local/share/swiftly/toolchains/$SWIFT_VERSION/usr/bin/swift" ]; then
    "$HOME/.local/share/swiftly/bin/swiftly" install --use "$SWIFT_VERSION" --assume-yes
  else
    "$HOME/.local/share/swiftly/bin/swiftly" use --global-default "$SWIFT_VERSION" --assume-yes >/dev/null
  fi

  # 4. Install SwiftLint Linux binary and SourceKit wrapper
  mkdir -p "$HOME/.local/bin" "$HOME/.local/libexec"
  CURRENT_SL_VERSION="$("$HOME/.local/libexec/swiftlint" version 2>/dev/null || true)"
  if [ "$CURRENT_SL_VERSION" != "$SWIFTLINT_VERSION" ]; then
    ARCH="$(uname -m)"
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
      SL_ASSET="swiftlint_linux_arm64.zip"
    else
      SL_ASSET="swiftlint_linux_amd64.zip"
    fi
    TMP_SL="$(mktemp -d)"
    curl -fsSL "https://github.com/realm/SwiftLint/releases/download/${SWIFTLINT_VERSION}/${SL_ASSET}" -o "$TMP_SL/${SL_ASSET}"
    unzip -qo "$TMP_SL/${SL_ASSET}" -d "$TMP_SL"
    install -m 0755 "$TMP_SL/swiftlint" "$HOME/.local/libexec/swiftlint"
    rm -rf "$TMP_SL"
  fi

  cat > "$HOME/.local/bin/swiftlint" <<'WRAPPER'
#!/usr/bin/env bash
if [ -z "${LINUX_SOURCEKIT_LIB_PATH:-}" ] && [ -x "$HOME/.local/share/swiftly/bin/swiftly" ]; then
  LINUX_SOURCEKIT_LIB_PATH="$("$HOME/.local/share/swiftly/bin/swiftly" use --print-location 2>/dev/null)/usr/lib"
  export LINUX_SOURCEKIT_LIB_PATH
fi
exec "$HOME/.local/libexec/swiftlint" "$@"
WRAPPER
  chmod +x "$HOME/.local/bin/swiftlint"

  export PATH="$HOME/.local/bin:$PATH"
  export LINUX_SOURCEKIT_LIB_PATH="$HOME/.local/share/swiftly/toolchains/$SWIFT_VERSION/usr/lib"

  grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  grep -qxF '[ -f "$HOME/.local/share/swiftly/env.sh" ] && . "$HOME/.local/share/swiftly/env.sh"' "$HOME/.bashrc" || echo '[ -f "$HOME/.local/share/swiftly/env.sh" ] && . "$HOME/.local/share/swiftly/env.sh"' >> "$HOME/.bashrc"

  SOURCEKIT_EXPORT="export LINUX_SOURCEKIT_LIB_PATH=\"\$HOME/.local/share/swiftly/toolchains/$SWIFT_VERSION/usr/lib\""
  if ! grep -qxF "$SOURCEKIT_EXPORT" "$HOME/.bashrc"; then
    sed -i '/^export LINUX_SOURCEKIT_LIB_PATH=/d' "$HOME/.bashrc" 2>/dev/null || true
    echo "$SOURCEKIT_EXPORT" >> "$HOME/.bashrc"
  fi
elif [ "$OS_NAME" = "Darwin" ]; then
  if ! command -v swiftlint >/dev/null 2>&1 && command -v brew >/dev/null 2>&1; then
    HOMEBREW_NO_AUTO_UPDATE=1 brew install swiftlint
  fi
fi

# Resolve Swift Package Manager dependencies when Package.swift is present
if [ -f Package.swift ]; then
  swift package resolve
fi

swift --version
swiftlint version
