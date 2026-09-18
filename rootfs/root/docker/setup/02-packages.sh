#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202608141335-git
# @@Author           :  CasjaysDev
# @@Contact          :  CasjaysDev <docker-admin@casjaysdev.pro>
# @@License          :  WTFPL
# @@Copyright        :  Copyright 2026 CasjaysDev
# @@Created          :  Fri Aug 14 01:35:28 PM EDT 2026
# @@File             :  02-packages.sh
# @@Description      :  script to run packages
# @@Changelog        :  newScript
# @@TODO             :  Refactor code
# @@Other            :  N/A
# @@Resource         :  N/A
# @@Terminal App     :  yes
# @@sudo/root        :  yes
# @@Template         :  templates/dockerfiles/init_scripts/02-packages.sh
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
if command -v update-ca-certificates >/dev/null 2>&1; then
  update-ca-certificates
elif command -v update-ca-trust >/dev/null 2>&1; then
  update-ca-trust extract
elif command -v trust >/dev/null 2>&1; then
  trust extract-compat
fi

if command -v apt-get >/dev/null 2>&1; then
  echo "Adding the Adoptium Temurin apt repository"
  mkdir -p "/etc/apt/keyrings"
  wget -qO - "https://packages.adoptium.net/artifactory/api/gpg/key/public" | gpg --dearmor >"/etc/apt/keyrings/adoptium.gpg"
  echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print $2}' /etc/os-release) main" >"/etc/apt/sources.list.d/adoptium.list"

  echo "Adding the GitHub CLI apt repository"
  wget -qO - "https://cli.github.com/packages/githubcli-archive-keyring.gpg" | tee "/etc/apt/keyrings/githubcli-archive-keyring.gpg" >/dev/null
  chmod go+r "/etc/apt/keyrings/githubcli-archive-keyring.gpg"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" >"/etc/apt/sources.list.d/github-cli.list"

  apt-get update
  pkmgr install temurin-17-jdk gh

  echo "Linking JAVA_HOME to a stable path"
  jdk_dir="$(dirname -- "$(dirname -- "$(readlink -f -- "$(command -v javac)")")")"
  ln -sfn "$jdk_dir" "${JAVA_HOME:-/opt/jdk-17}"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - -
# Set the exit code
exitCode=$?
# - - - - - - - - - - - - - - - - - - - - - - - - -
exit $exitCode
# - - - - - - - - - - - - - - - - - - - - - - - - -
# ex: ts=2 sw=2 et filetype=sh
# - - - - - - - - - - - - - - - - - - - - - - - - -

