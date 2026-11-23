#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202608141335-git
# @@Author           :  CasjaysDev
# @@Contact          :  CasjaysDev <docker-admin@casjaysdev.pro>
# @@License          :  WTFPL
# @@Copyright        :  Copyright 2026 CasjaysDev
# @@Created          :  Fri Aug 14 01:35:28 PM EDT 2026
# @@File             :  05-custom.sh
# @@Description      :  script to run custom
# @@Changelog        :  newScript
# @@TODO             :  Refactor code
# @@Other            :  N/A
# @@Resource         :  N/A
# @@Terminal App     :  yes
# @@sudo/root        :  yes
# @@Template         :  templates/dockerfiles/init_scripts/05-custom.sh
# - - - - - - - - - - - - - - - - - - - - - - - - -
# shellcheck disable=SC1001,SC1003,SC2001,SC2003,SC2016,SC2031,SC2090,SC2115,SC2120,SC2155,SC2199,SC2229,SC2317,SC2329
# - - - - - - - - - - - - - - - - - - - - - - - - -
# Set bash options
set -eo pipefail
if [ "$DEBUGGER" = "on" ]; then
  echo "Enabling debugging"
  set -x$DEBUGGER_OPTIONS
fi
# - - - - - - - - - - - - - - - - - - - - - - - - -
# Set env variables
exitCode=0

# - - - - - - - - - - - - - - - - - - - - - - - - -
# Predefined actions

# - - - - - - - - - - - - - - - - - - - - - - - - -
# Main script
# Pinned community arm64 builds (Google ships no Linux arm64 host binaries); SHA-256 verified before use
CUSTOM_ARM64_TOOLS_VERSION="35.0.2"
CUSTOM_ARM64_TOOLS_SHA256="db1cea2c4454d5f9c5a802646b2d1cf560b4ee7badbe23e51ab8e1881bb50fc2"
CUSTOM_ARM64_NDK_RELEASE="v1.0.7"
CUSTOM_ARM64_NDK_SHA256="d088c89320c596dcd69cccd5c01a9c282825ece2301ccfdc2d46a64e0a1f48c2"

# Gradle names the wrapper dist dir after base36(md5(distributionUrl)); pure bash so no extra packages are needed
__md5_base36() {
  local hex chars="0123456789abcdefghijklmnopqrstuvwxyz" out="" i d rem cur nonzero
  local -a n=() q=()
  hex="$(printf '%s' "$1" | md5sum | cut -d' ' -f1)"
  for ((i = 0; i < ${#hex}; i++)); do n+=($((16#${hex:i:1}))); done
  while :; do
    rem=0
    nonzero=0
    q=()
    for d in "${n[@]}"; do
      cur=$((rem * 16 + d))
      q+=($((cur / 36)))
      [ $((cur / 36)) -eq 0 ] || nonzero=1
      rem=$((cur % 36))
    done
    out="${chars:rem:1}$out"
    n=("${q[@]}")
    [ "$nonzero" -eq 1 ] || break
  done
  printf '%s' "$out"
}

case "$(uname -m)" in
x86_64) CUSTOM_ARCH="amd64" ;;
aarch64 | arm64) CUSTOM_ARCH="arm64" ;;
*)
  echo "Unsupported architecture: $(uname -m)" >&2
  exit 1
  ;;
esac

echo "Installing glab ${GLAB_VERSION}"
CUSTOM_GLAB_FILE="glab_${GLAB_VERSION}_linux_${CUSTOM_ARCH}.tar.gz"
CUSTOM_GLAB_URL="https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VERSION}/downloads"
mkdir -p "/tmp/glab"
wget -q "$CUSTOM_GLAB_URL/$CUSTOM_GLAB_FILE" -O "/tmp/glab/$CUSTOM_GLAB_FILE"
wget -q "$CUSTOM_GLAB_URL/checksums.txt" -O "/tmp/glab/checksums.txt"
(cd "/tmp/glab" && grep -F -- " $CUSTOM_GLAB_FILE" checksums.txt | sha256sum -c -)
tar -xzf "/tmp/glab/$CUSTOM_GLAB_FILE" -C "/tmp/glab"
install -m 0755 "/tmp/glab/bin/glab" "/usr/local/bin/glab"
rm -rf "/tmp/glab"
glab --version

echo "Installing tea ${TEA_VERSION}"
CUSTOM_TEA_FILE="tea-${TEA_VERSION}-linux-${CUSTOM_ARCH}.xz"
CUSTOM_TEA_URL="https://gitea.com/gitea/tea/releases/download/v${TEA_VERSION}"
mkdir -p "/tmp/tea"
wget -q "$CUSTOM_TEA_URL/$CUSTOM_TEA_FILE" -O "/tmp/tea/$CUSTOM_TEA_FILE"
wget -q "$CUSTOM_TEA_URL/$CUSTOM_TEA_FILE.sha256" -O "/tmp/tea/$CUSTOM_TEA_FILE.sha256"
(cd "/tmp/tea" && sha256sum -c "$CUSTOM_TEA_FILE.sha256")
xz -dc "/tmp/tea/$CUSTOM_TEA_FILE" >"/usr/local/bin/tea"
chmod 0755 "/usr/local/bin/tea"
rm -rf "/tmp/tea"
tea --version

if [ -n "$ANDROID_SDK_ROOT" ]; then
  echo "Installing the Android SDK cmdline-tools"
  mkdir -p "$ANDROID_SDK_ROOT"
  wget -q "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip" -O "/tmp/cmdline-tools.zip"
  unzip -q "/tmp/cmdline-tools.zip" -d "/tmp/cmdline-tools-raw"
  mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
  mv "/tmp/cmdline-tools-raw/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
  rm -rf "/tmp/cmdline-tools.zip" "/tmp/cmdline-tools-raw"

  echo "Accepting Android SDK licenses"
  yes | sdkmanager --licenses >/dev/null 2>&1 || true

  echo "Installing Android SDK platforms, build-tools, cmake and NDK"
  sdk_packages="platform-tools build-tools;${ANDROID_BUILD_TOOLS_VERSION}"
  # Google only ships Linux x86_64 native binaries; arm64 gets community builds below
  if [ "$CUSTOM_ARCH" = "amd64" ]; then
    sdk_packages="$sdk_packages cmake;${ANDROID_CMAKE_VERSION} ndk;${ANDROID_NDK_VERSION}"
  fi
  IFS=','
  for platform in $ANDROID_PLATFORM_VERSIONS; do
    sdk_packages="$sdk_packages platforms;$platform"
  done
  unset IFS
  # shellcheck disable=SC2086
  sdkmanager $sdk_packages

  if [ "$CUSTOM_ARCH" = "arm64" ]; then
    echo "Overlaying native arm64 build-tools and platform-tools (lzhiyong/android-sdk-tools ${CUSTOM_ARM64_TOOLS_VERSION})"
    mkdir -p "/tmp/arm64-tools"
    wget -q "https://github.com/lzhiyong/android-sdk-tools/releases/download/${CUSTOM_ARM64_TOOLS_VERSION}/android-sdk-tools-static-aarch64.zip" -O "/tmp/arm64-tools.zip"
    printf '%s  %s\n' "$CUSTOM_ARM64_TOOLS_SHA256" "/tmp/arm64-tools.zip" | sha256sum -c -
    unzip -q "/tmp/arm64-tools.zip" -d "/tmp/arm64-tools"
    cp -f "/tmp/arm64-tools/build-tools"/* "$ANDROID_SDK_ROOT/build-tools/${ANDROID_BUILD_TOOLS_VERSION}/"
    cp -f "/tmp/arm64-tools/platform-tools"/* "$ANDROID_SDK_ROOT/platform-tools/"
    rm -rf "/tmp/arm64-tools" "/tmp/arm64-tools.zip"

    echo "Installing the arm64 NDK (kaspersigi/android-ndk-r27d-linux-aarch64 ${CUSTOM_ARM64_NDK_RELEASE})"
    wget -q "https://github.com/kaspersigi/android-ndk-r27d-linux-aarch64/releases/download/${CUSTOM_ARM64_NDK_RELEASE}/android-ndk-r27d-linux.zip" -O "/tmp/arm64-ndk.zip"
    printf '%s  %s\n' "$CUSTOM_ARM64_NDK_SHA256" "/tmp/arm64-ndk.zip" | sha256sum -c -
    unzip -q "/tmp/arm64-ndk.zip" -d "/tmp/arm64-ndk"
    rm -f "/tmp/arm64-ndk.zip"
    mkdir -p "$ANDROID_SDK_ROOT/ndk"
    mv "/tmp/arm64-ndk/android-ndk-r27d" "$ANDROID_SDK_ROOT/ndk/${ANDROID_NDK_VERSION}"
    rm -rf "/tmp/arm64-ndk"
    grep -q -- "^Pkg.Revision = ${ANDROID_NDK_VERSION}\$" "$ANDROID_SDK_ROOT/ndk/${ANDROID_NDK_VERSION}/source.properties" || {
      echo "arm64 NDK revision does not match ANDROID_NDK_VERSION=${ANDROID_NDK_VERSION}" >&2
      exit 1
    }

    echo "Linking distro cmake and ninja as SDK cmake ${ANDROID_CMAKE_VERSION}"
    pkmgr install cmake ninja-build
    cmake --version | head -n1 | grep -q -- " ${ANDROID_CMAKE_VERSION}\$" || {
      echo "Distro cmake does not match ANDROID_CMAKE_VERSION=${ANDROID_CMAKE_VERSION}" >&2
      exit 1
    }
    mkdir -p "$ANDROID_SDK_ROOT/cmake/${ANDROID_CMAKE_VERSION}/bin"
    for bin in cmake ctest cpack ninja; do
      ln -sf "$(command -v "$bin")" "$ANDROID_SDK_ROOT/cmake/${ANDROID_CMAKE_VERSION}/bin/$bin"
    done
    printf 'Pkg.Desc = CMake\nPkg.Revision = %s\n' "$ANDROID_CMAKE_VERSION" >"$ANDROID_SDK_ROOT/cmake/${ANDROID_CMAKE_VERSION}/source.properties"
  fi

  echo "Pre-warming the Gradle wrapper distribution"
  dist_url="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"
  dist_dir="${GRADLE_USER_HOME}/wrapper/dists/gradle-${GRADLE_VERSION}-bin/$(__md5_base36 "$dist_url")"
  mkdir -p "$dist_dir"
  wget -q "$dist_url" -O "$dist_dir/gradle-${GRADLE_VERSION}-bin.zip"
  unzip -q "$dist_dir/gradle-${GRADLE_VERSION}-bin.zip" -d "$dist_dir"
  rm -f "$dist_dir/gradle-${GRADLE_VERSION}-bin.zip"
  touch "$dist_dir/gradle-${GRADLE_VERSION}-bin.zip.ok"
  ln -sfn "$dist_dir/gradle-${GRADLE_VERSION}/bin/gradle" "/usr/local/bin/gradle"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - -
# Set the exit code
exitCode=$?
# - - - - - - - - - - - - - - - - - - - - - - - - -
exit $exitCode
# - - - - - - - - - - - - - - - - - - - - - - - - -
# ex: ts=2 sw=2 et filetype=sh
# - - - - - - - - - - - - - - - - - - - - - - - - -

