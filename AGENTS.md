# Pop_OS!

A personal backup of Kieran's Pop!_OS ("Cosmic" desktop) configuration, for
migrating to or restoring on a new machine. This is a data/config archive,
not application code — there is no build, test, or lint tooling.

## Project structure

- **[run/install](./run/install)** \
  Restores the backups below onto the current machine: extracts the Cosmic
  settings tarball, loads the dconf dump, links/copies the backgrounds
  directory, builds `cos-cli` (pinned rev — see `COS_CLI_REV`), symlinks
  `src/environment.d/cosmic-startup-workspaces.conf` into
  `~/.config/environment.d/`, and installs the startup-workspaces autostart
  entry. Run `./run/install --help` for options. Does not apply `Dark.ron`
  — that has no scriptable import and must be applied manually.

- **[src/Dark.ron](./src/Dark.ron)** \
  Desktop appearance configuration, exported from Cosmic Settings
  (**Desktop > Appearance**).

- **[src/cosmic-settings-backup.tar.gz](./src/cosmic-settings-backup.tar.gz)** \
  Archive of `~/.config/cosmic`, covering theme, desktop layout, panel/dock
  config, and keyboard shortcuts. Created with
  `tar -czf src/cosmic-settings-backup.tar.gz -C ~/.config cosmic` and restored
  with `tar -xzf src/cosmic-settings-backup.tar.gz -C ~/.config`.

- **[src/pop_os_settings.dconf](./src/pop_os_settings.dconf)** \
  Application settings dump, created with
  `dconf dump / > src/pop_os_settings.dconf` and restored with
  `dconf load / < src/pop_os_settings.dconf`.

- **[src/Documents/Backgrounds/](./src/Documents/Backgrounds)** \
  Desktop wallpaper images, copied or symlinked to `~/Documents/Backgrounds`.

- **[src/cosmic-startup-workspaces.sh](./src/cosmic-startup-workspaces.sh)** \
  Launches configured apps at login and places each on its own workspace,
  via [cos-cli](https://github.com/estin/cos-cli) (COSMIC has no native
  window-rule/workspace-assignment feature yet). `run/install` installs an
  autostart entry that runs this script in place, from this repo checkout.
  Reads its app list from `$COSMIC_STARTUP_APPS` (see the CONFIG block for
  the format) — a no-op, not an error, if that's unset. `~/.bashrc` is NOT
  sourced by autostart, so this is never set there.

- **[src/environment.d/cosmic-startup-workspaces.conf](./src/environment.d/cosmic-startup-workspaces.conf)** \
  Version-controlled `COSMIC_STARTUP_APPS` value. `run/install` symlinks it
  to `~/.config/environment.d/cosmic-startup-workspaces.conf`, which
  `systemd --user` reads once at the start of a login session — edit this
  file (not the script) to change which apps launch at login, and expect
  the change to take effect on the next fresh login, not mid-session.
  Entries are `<workspace>|<command>|<app-id>[|<state>]`, where the
  optional 4th field is comma-separated window states (`maximize`,
  `fullscreen`, `minimize`, `sticky`, and their `un-` forms) applied via
  `cos-cli state` after the window has been placed.

## Rules

- Do not symlink `~/.config/cosmic` directly to the archive in this
  repository — always export/import via the tarball.

- When updating a settings file, regenerate it fresh with the export command
  above rather than hand-editing it.

- Edit `src/environment.d/cosmic-startup-workspaces.conf` to change the
  startup app list — don't hardcode it in
  `src/cosmic-startup-workspaces.sh`, and don't assume an existing entry
  matches the current machine without checking `cos-cli info` first.

- `cos-cli` is third-party and unaffiliated with System76, and has no
  tagged releases. `run/install` pins it to a specific commit
  (`COS_CLI_REV`) rather than floating on `main` — bump that rev
  deliberately, not automatically.

## References

The following technical standards (TS) govern this project. Fetch and ingest
the relevant standards as-and-when required for the task at hand.

- [**TS-9: Version Control**](https://kieranpotts.com/standards/009) \
  Use when working with Git. Covers commits, branching, merging, integration
  strategies, cutting releases, and configuring Git/PR/CI tooling.

- [**TS-31: Unix Shells and POSIX Standards**](https://kieranpotts.com/standards/031) \
  Use when authoring or modifying shell scripts that must be POSIX-compliant
  and run across multiple shells (sh, bash, zsh, dash) and platforms.

- [**TS-30: YAML**](https://kieranpotts.com/standards/030) \
  Use when writing or reviewing YAML files.
