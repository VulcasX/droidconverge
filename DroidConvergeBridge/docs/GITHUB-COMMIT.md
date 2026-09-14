# DroidConverge Bridge - repository integration

`DroidConvergeBridge` is maintained as part of the main DroidConverge repository.

The Android project lives at:

```text
DroidConverge/DroidConvergeBridge/
```

There is no separate Git repository for the Bridge.

## Adding Bridge changes

From the root of the DroidConverge repository:

```bash
git add DroidConvergeBridge
git status
git diff --cached
```

Review the staged changes before committing.

A suitable commit message for the initial Bridge integration is:

```bash
git commit -m "feat: add Android bridge haptic proof of concept"
```

Then push the main DroidConverge repository normally:

```bash
git push
```

## Files that must not be committed

Do not commit:

- APKs or generated build output
- signing keys
- `local.properties`
- private device data
- machine-specific credentials
- temporary test files
- private logs containing sensitive information

Release artifacts should be published separately when an appropriate release workflow is established.

## Licensing and attribution

The Bridge is distributed as part of DroidConverge.

Before publishing Bridge changes, review:

- `LICENSE`
- `LICENSE-DOCS.md`
- `SOURCES.md`
- `THIRD-PARTY-NOTICES.md`

Third-party projects retain their own licenses and copyright notices.
