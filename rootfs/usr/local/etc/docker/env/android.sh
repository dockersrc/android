#!/usr/bin/env bash
# shellcheck shell=bash
# The entrypoint resets PATH before sourcing this file, so restore the toolchain directories
export PATH="${PATH}:${JAVA_HOME}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/build-tools/${ANDROID_BUILD_TOOLS_VERSION}:${ANDROID_SDK_ROOT}/cmake/${ANDROID_CMAKE_VERSION}/bin"
# Google's Maven aapt2 is x86_64-only, so arm64 Gradle builds must use the SDK's native aapt2
if [ "$(uname -m)" = "aarch64" ]; then
  export GRADLE_OPTS="${GRADLE_OPTS:+$GRADLE_OPTS }-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_SDK_ROOT}/build-tools/${ANDROID_BUILD_TOOLS_VERSION}/aapt2"
fi
