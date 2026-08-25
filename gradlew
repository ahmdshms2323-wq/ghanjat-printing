#!/usr/bin/env sh
set -eu
GRADLE_VERSION=8.6
CACHE_DIR="${HOME}/.gradle/ghanjat-gradle-${GRADLE_VERSION}"
GRADLE_BIN="${CACHE_DIR}/gradle-${GRADLE_VERSION}/bin/gradle"
if [ ! -x "$GRADLE_BIN" ]; then
  mkdir -p "$CACHE_DIR"
  ZIP="$CACHE_DIR/gradle.zip"
  echo "Downloading Gradle ${GRADLE_VERSION}..."
  if command -v curl >/dev/null 2>&1; then
    curl -L "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o "$ZIP"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$ZIP" "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"
  else
    echo "curl or wget is required to download Gradle." >&2; exit 1
  fi
  unzip -q -o "$ZIP" -d "$CACHE_DIR"
fi
exec "$GRADLE_BIN" "$@"
