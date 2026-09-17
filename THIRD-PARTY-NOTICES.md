# Third-party notices

DroidConverge is an integration project.

The GNU GPL license applied to original DroidConverge code does not relicense third-party software. Third-party projects retain their own copyrights, licenses and applicable notices.

This file provides a high-level attribution map. It is not a replacement for the license files distributed by the respective upstream projects or packages.

## Design reference: MagicDesk

[MagicDesk](https://github.com/mekhontsev/magicdesk) inspired the internal
control-panel concept for external display sessions. Its repository is
[MIT licensed](https://github.com/mekhontsev/magicdesk/blob/main/LICENSE).
DroidConverge does not copy MagicDesk source or its privileged display stack.

## Core upstream projects

### chroot-distro

Source:

https://github.com/Magisk-Modules-Alt-Repo/chroot-distro

License: GNU General Public License v3.0 (GPL-3.0).

DroidConverge uses chroot-distro as the Android-side real-chroot management layer.

### Anland: Termux

Source:

https://github.com/lfdevs/anland-termux

License: GNU General Public License v3.0 (GPL-3.0).

DroidConverge uses Anland: Termux for the Android/Wayland integration used by the reference platform.

### Termux

Source:

https://github.com/termux/termux-app

Primary project license: GNU GPLv3-only.

Termux also contains components with separate licensing, including Apache-2.0 and MIT-licensed code. The upstream license files must be consulted for the exact file or component involved.

### Termux:API

Source:

https://github.com/termux/termux-api

License: GNU General Public License v3.0 (GPL-3.0).

The separate `termux-api-package` project contains MIT-licensed code and must be treated according to its own license.

### Shizuku

Source:

https://github.com/RikkaApps/Shizuku

License: Apache License 2.0.

The upstream project also specifies additional restrictions concerning certain Shizuku branding, resources, application identifiers and permissions. Those restrictions remain applicable to the corresponding upstream materials.

DroidConverge does not claim ownership of Shizuku.

### Shizuku API

Source:

https://github.com/RikkaApps/Shizuku-API

License: MIT License.

### KDE Plasma

Source:

https://invent.kde.org/plasma

KDE software is distributed under the licenses applicable to the individual components and files. Depending on the component, KDE projects may use GPL, LGPL, BSD, MIT and other compatible open-source licenses.

Do not treat all KDE software as being under a single license.

### Maliit

Source:

https://gitlab.com/maliit

Maliit components have their own per-project and per-file licensing.

For Maliit Keyboard, the combined work is LGPL-3.0-only, while individual files and directories may use BSD or LGPL licensing according to the upstream license notices.

### Mesa

Source:

https://gitlab.freedesktop.org/mesa/mesa

Mesa is a multi-component project with multiple applicable licenses. Depending on the component, the source tree includes licenses such as MIT, Apache-2.0, GPL and other licenses.

DroidConverge does not redistribute the Mesa source tree as part of this repository unless explicitly stated elsewhere.

### Ubuntu

Source:

https://ubuntu.com/

Ubuntu is an aggregate distribution containing many independently licensed packages.

The license for a specific Ubuntu package is determined by that package and its accompanying license and copyright information. Canonical's Ubuntu intellectual-property policy does not replace or reduce the licenses applicable to individual works.

DroidConverge does not claim ownership of Ubuntu or its individual packages.

## Android build tooling and libraries

`DroidConvergeBridge` is an Android application and uses third-party Android build tooling and libraries declared by its Gradle configuration.

These include, as applicable:

- Android Gradle Plugin
- Gradle
- Kotlin
- AndroidX
- Jetpack Compose
- Material components
- JUnit
- AndroidX Test
- Espresso

Their respective licenses remain applicable to the tooling and libraries used by the Android project.

The exact versions are recorded in:

```text
DroidConvergeBridge/gradle/libs.versions.toml
DroidConvergeBridge/gradle/wrapper/gradle-wrapper.properties
DroidConvergeBridge/build.gradle.kts
DroidConvergeBridge/app/build.gradle.kts
```

## Original DroidConverge work

Original DroidConverge source code, scripts and documentation are separately licensed as described in:

- `LICENSE`
- `LICENSE-DOCS.md`

Third-party software is not relicensed by those files.

For source URLs, versions, hashes and additional references, see `SOURCES.md`.
