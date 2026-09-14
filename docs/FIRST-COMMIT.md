# First commit — step by step

## Best route: PC + VS Code

For the first publication I recommend the PC because it is easier to inspect the complete tree and Git history. The same repository can then be managed from the tablet with Termux.

### 1. On the PC

Extract the DroidConverge archive and open the `droidconverge-v2` folder in VS Code.

Open **Terminal → New Terminal**.

Check Git:

```bash
git --version
```

### 2. Initialize the local repository

```bash
git init -b main
git status
```

GitHub documents `git init -b main` for current Git versions. citeturn133312search1

### 3. Configure your identity

Use your real GitHub display identity, or GitHub's no-reply address if you prefer privacy:

```bash
git config user.name "YOUR NAME"
git config user.email "YOUR GITHUB EMAIL"
```

### 4. Inspect before staging

```bash
git status
git add .
git status
```

Do not commit secrets, authentication tokens, private keys or personal device dumps. GitHub explicitly warns against pushing sensitive information. citeturn133312search1turn133312search2

### 5. Create the first commit

```bash
git commit -m "docs: establish DroidConverge project baseline"
```

At this point the history exists locally.

### 6. Create the GitHub repository

On GitHub choose **New repository**.

Recommended:

```text
Owner: your account
Name: droidconverge
Visibility: Public
```

Because we already have a local README, license and gitignore, **do not initialize the GitHub repository with those files**. GitHub specifically recommends leaving them unchecked when pushing an existing local project, to avoid unnecessary merge conflicts. citeturn133312search0turn133312search1

### 7. Add the GitHub remote

Copy the repository HTTPS URL from GitHub, then:

```bash
git remote add origin https://github.com/YOUR-USERNAME/droidconverge.git
git remote -v
```

### 8. Push the first commit

```bash
git push -u origin main
```

These are the official GitHub steps for publishing a locally initialized repository. citeturn133312search1

### 9. Verify the public repository

Reload GitHub. The first page should immediately show the DroidConverge README.

## Can this be done from the tablet?

**Yes.** There are two practical routes.

### Route A — GitHub website

The GitHub web interface can upload files and create commits. Current limits include 25 MiB per file through the browser and up to 100 files per upload. GitHub also notes that browser uploads do not apply `.gitattributes` behavior the same way a Git push does. citeturn133312search2

This route is fine for small documentation edits, but I recommend the PC for the first complete import.

### Route B — Termux + Git

This is the route I recommend for later tablet development.

Install Git in Termux:

```bash
pkg install git
```

Then:

```bash
cd ~/droidconverge
git status
```

After editing:

```bash
git add .
git commit -m "docs: update installation notes"
git push
```

The tablet can therefore become your real development machine. The PC remains useful for Android Studio/Kotlin later.

## Recommended milestone commits

Use one commit for each meaningful, working milestone:

```text
docs: establish DroidConverge project baseline
docs: document Ubuntu 26.04 chroot setup
docs: document Anland KDE integration
docs: document Desktop and Touch modes
feat: add Android Bridge prototype
feat: add Android haptic provider
feat: add battery bridge
feat: add Wi-Fi and Bluetooth bridge
feat: add startup launcher
```

The key rule is simple: **commit after a known-good milestone**, not after every tiny command.
