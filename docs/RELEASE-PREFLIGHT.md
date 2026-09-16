# DroidConverge release preflight

The release preflight runs before the Git commit and never performs `git commit` or `git push`.

It recovers selected checkpoint material, preserves conflicts instead of overwriting them, checks repository hygiene, runs Android tests/builds, and produces a report under `.release-work/`.

Production signing keys are never generated or published automatically. Verify the Android target SDK before Play publication.
