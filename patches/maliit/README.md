# Maliit haptic TCP patch

`0001-droidconverge-haptic-tcp.patch` is a selective diff between the preserved
Maliit backup and the modified source on the RedMagic Astra checkpoint. It
changes `src/plugin/feedback.cpp` and `CMakeLists.txt`; it does not include an
upstream source tree or a real Bridge token.

Apply from the root of the matching Maliit keyboard source checkout:

```bash
git apply --check /path/to/0001-droidconverge-haptic-tcp.patch
git apply /path/to/0001-droidconverge-haptic-tcp.patch
```

The patch was checked against the matching backup files with `git apply
--check`. It has not been rebuilt or tested on the tablet in this recovery
cycle. The code reads `~/.config/droidconverge.json` and sends an authenticated
request to the local Android Bridge. It still contains legacy process code from
the checkpoint; review that code and build on the target Linux environment
before using it in a release.

Rollback: run `git apply -R` on the same patch in the Maliit checkout, then
rebuild and reinstall the previous keyboard package.
