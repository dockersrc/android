## 👋 Welcome to android 🚀

Debian-based Android build toolchain image. It is the shared build image
(`casjaysdev/android`) consumed by every CasjaysDev Android app project — see
[APPLICATION.md](https://github.com/claudemgr/android) for the project template
that builds against it. Nothing app-specific (no baked `build.gradle`
dependencies, no project source) lives in this image; only the toolchain that
is identical across projects does.

### What's included

| Component | Version | Notes |
|---|---|---|
| Base OS | `casjaysdev/debian` | via `ENV_PULL_URL` |
| JDK | 17 (Temurin) | installed from the Adoptium apt repo, `JAVA_HOME=/opt/jdk-17` |
| Android SDK cmdline-tools | `15859902` | `$ANDROID_SDK_ROOT/cmdline-tools/latest` |
| Android platforms | `android-34`, `android-35` | via `sdkmanager` |
| Android build-tools | `35.0.0` | via `sdkmanager` |
| Android NDK | `27.3.13750724` (r27d LTS) | via `sdkmanager`, for native/JNI builds |
| CMake | `3.31.6` | via `sdkmanager`, for native/JNI builds |
| Gradle | `8.14.5` | wrapper distribution pre-warmed into `$GRADLE_USER_HOME` so `./gradlew` never re-downloads it |
| GitHub CLI | `gh` | from the official apt repo, for release/CI steps that shell out to `gh` |

`ANDROID_HOME` / `ANDROID_SDK_ROOT` default to `/opt/android-sdk`.
`GRADLE_USER_HOME` defaults to `/root/.gradle`. All of the above are
overridable at build time via `--build-arg` (see `Dockerfile` for the full
`ARG` list and defaults: `ANDROID_CMDLINE_TOOLS_VERSION`,
`ANDROID_PLATFORM_VERSIONS`, `ANDROID_BUILD_TOOLS_VERSION`,
`ANDROID_NDK_VERSION`, `ANDROID_CMAKE_VERSION`, `GRADLE_VERSION`).

### How it's built

- `PACK_LIST` (wired from `ENV_PACKAGES` in `.env.scripts`) installs
  `wget unzip git curl gnupg` from the base distro's own repos — the minimum
  needed to fetch and unpack everything else. `ca-certificates` is already
  installed by the base template before `PACK_LIST` runs.
- `rootfs/root/docker/setup/02-packages.sh` adds the Adoptium Temurin and
  GitHub CLI apt repositories (both need a keyring + `sources.list.d` entry
  that `pkmgr install` alone can't set up) and then installs
  `temurin-17-jdk` and `gh` through `pkmgr install`, same as any other
  package-manager install.
- `rootfs/root/docker/setup/05-custom.sh` downloads and unpacks the Android
  SDK cmdline-tools, accepts the SDK licenses, installs the pinned
  platforms/build-tools/cmake/NDK via `sdkmanager`, and pre-warms the Gradle
  wrapper distribution zip so the wrapper never fetches it at build time.
- No project `build.gradle`/dependency pre-warm is baked in here — that step
  is project-specific and belongs in each app's own CI, not in the shared
  base image.

## Install my system scripts

```shell
 sudo bash -c "$(curl -q -LSsf "https://github.com/systemmgr/installer/raw/main/install.sh")"
 sudo systemmgr --config && sudo systemmgr install scripts
```

## Automatic install/update

```shell
dockermgr update os android
```

## Install and run container

```shell
mkdir -p "/var/lib/srv/root/docker/casjaysdev/android/latest"
git clone "https://github.com/dockermgr/android" "$HOME/.local/share/CasjaysDev/dockermgr/android"
cp -Rfva "$HOME/.local/share/CasjaysDev/dockermgr/android/rootfs/." "/var/lib/srv/root/docker/casjaysdev/android/latest/"
docker run -d \
--restart always \
--privileged \
--name casjaysdev-android-latest \
--hostname android \
-e TZ=${TIMEZONE:-America/New_York} \
-v "/var/lib/srv/root/docker/casjaysdev/android/latest/data:/data:z" \
-v "/var/lib/srv/root/docker/casjaysdev/android/latest/config:/config:z" \
casjaysdev/android:latest
```

## Build an Android app with this image

This image is a build toolchain, not a long-running service — run it once per
build and let it exit:

```shell
docker run --rm --name {project_name}-$(tr -dc 'a-z0-9' </dev/urandom | head -c8) \
  --memory=4g --cpus=2 \
  -v "$PWD":/workspace -w /workspace \
  -e GRADLE_USER_HOME=/workspace/.gradle \
  casjaysdev/android:latest ./gradlew assembleDebug
```

- Source tree → `/workspace`; Gradle cache → `GRADLE_USER_HOME=/workspace/.gradle`
  (project-scoped, safe for concurrent builds across app repos).
- Never volume-mount over `/opt/android-sdk` — it overlays the SDK baked into
  the image. `ANDROID_HOME`/`ANDROID_SDK_ROOT` are preset and should be left
  alone unless the consuming project intentionally overrides the SDK.
- `cmake`/`ndk` versions referenced in `app/build.gradle` must match the
  versions baked into this image (see the table above) — the image never
  lazily downloads SDK components mid-build, so a mismatch fails the build
  instead of silently fetching a different version.
- `gh` is on `PATH` for CI steps (e.g. `gh release delete`, `gh release
  upload`) that run inside this image.

## via docker-compose

```yaml
version: "2"
services:
  ProjectName:
    image: casjaysdev/android
    container_name: casjaysdev-android-latest
    environment:
      - TZ=America/New_York
      - HOSTNAME=android
    volumes:
      - "/var/lib/srv/root/docker/casjaysdev/android/latest/data:/data:z"
      - "/var/lib/srv/root/docker/casjaysdev/android/latest/config:/config:z"
    restart: always
```

## Get source files

```shell
dockermgr download src os android
```

## Build container

```shell
git clone "https://github.com/dockersrc/android" "$HOME/Projects/github/dockersrc/android"
cd "$HOME/Projects/github/dockersrc/android" && buildx all
```

To override a pinned version at build time:

```shell
docker build --build-arg ANDROID_BUILD_TOOLS_VERSION=35.0.0 -t casjaysdev/android:latest .
```

## Authors

🤖 casjay: [Github](https://github.com/casjay) 🤖
⛵ casjaysdev: [Github](https://github.com/dockersrc) [Docker](https://hub.docker.com/u/casjaysdev) ⛵
