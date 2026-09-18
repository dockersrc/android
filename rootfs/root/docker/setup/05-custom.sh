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
  sdk_packages="platform-tools build-tools;${ANDROID_BUILD_TOOLS_VERSION} cmake;${ANDROID_CMAKE_VERSION} ndk;${ANDROID_NDK_VERSION}"
  IFS=','
  for platform in $ANDROID_PLATFORM_VERSIONS; do
    sdk_packages="$sdk_packages platforms;$platform"
  done
  unset IFS
  # shellcheck disable=SC2086
  sdkmanager $sdk_packages >/dev/null 2>&1

  echo "Pre-warming the Gradle wrapper distribution"
  dist_dir="${GRADLE_USER_HOME}/wrapper/dists/gradle-${GRADLE_VERSION}-bin"
  mkdir -p "$dist_dir"
  wget -q "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -O "$dist_dir/gradle-${GRADLE_VERSION}-bin.zip"
  unzip -q "$dist_dir/gradle-${GRADLE_VERSION}-bin.zip" -d "$dist_dir"
  touch "$dist_dir/gradle-${GRADLE_VERSION}-bin.zip.lck"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - -
# Set the exit code
exitCode=$?
# - - - - - - - - - - - - - - - - - - - - - - - - -
exit $exitCode
# - - - - - - - - - - - - - - - - - - - - - - - - -
# ex: ts=2 sw=2 et filetype=sh
# - - - - - - - - - - - - - - - - - - - - - - - - -

