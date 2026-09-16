# DroidConverge Linux integrations

This directory contains only DroidConverge-specific integration material recovered
from the development checkpoint.

It intentionally does NOT contain the full upstream Maliit or Plasma Mobile source trees.

## Maliit

`feedback.cpp` is the DroidConverge-integrated version used to send haptic
requests to the Android Bridge.

`feedback.cpp.before-tcp` is the pre-integration reference used during development.

The actual authentication token is never stored in this repository.

## Plasma Mobile

The files in this directory are the DroidConverge-specific vibration integration
sources recovered from the development checkpoint.

Upstream source code remains external and must be obtained from its original
project/version when rebuilding the integration.

## Distribution warning

These files are source/integration material. Prebuilt system binaries from the
development tablet are intentionally not part of this repository.
