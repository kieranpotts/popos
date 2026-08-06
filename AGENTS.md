# Pop_OS!

A personal backup of Kieran's Pop!_OS ("Cosmic" desktop) configuration, for
migrating to or restoring on a new machine. This is a data/config archive,
not application code — there is no build, test, or lint tooling.

## Project structure

- **[run/install](./run/install)** \
  Restores the backups below onto the current machine: extracts the Cosmic
  settings tarball, loads the dconf dump, links/copies the backgrounds
  directory, and builds `cos-cli` (pinned rev — see `COS_CLI_REV`) plus the
  startup-workspaces autostart entry. Run `./run/install --help` for
  options. Does not apply `Dark.ron` — that has no scriptable import and
  must be applied manually.

- **[src/Dark.ron](./src/Dark.ron)** \
  Desktop appearance configuration, exported from Cosmic Settings
  (**Desktop > Appearance**).

- **[src/cosmic-settings-backup.tar.gz](./src/cosmic-settings-backup.tar.gz)** \
  Archive of `~/.config/cosmic`, covering theme, desktop layout, panel/dock
  config, and keyboard shortcuts. Created with
  `tar -czf src/cosmic-settings-backup.tar.gz -C ~/.config cosmic` and restored
  with `tar -xzf src/cosmic-settings-backup.tar.gz -C ~/.config`.

- **[src/pop_os_settings.dconf](./src/pop_os_settings.dconf)** \
  Application settings dump, created with `dconf dump / > src/pop_os_settings.dconf`
  and restored with `dconf load / < src/pop_os_settings.dconf`.

- **[src/Documents/Backgrounds/](./src/Documents/Backgrounds)** \
  Desktop wallpaper images, copied or symlinked to `~/Documents/Backgrounds`.

- **[src/cosmic-startup-workspaces.sh](./src/cosmic-startup-workspaces.sh)** \
  Launches configured apps at login and places each on its own workspace,
  via [cos-cli](https://github.com/estin/cos-cli) (COSMIC has no native
  window-rule/workspace-assignment feature yet). `run/install` installs an
  autostart entry that runs this script in place, from this repo checkout.
  The app list is machine-specific — set it via the `$COSMIC_STARTUP_APPS`
  env var in `~/.config/environment.d/cosmic-startup-workspaces.conf`
  (systemd --user reads this before autostart apps launch; `~/.bashrc` is
  NOT sourced by autostart, so don't set it there) rather than editing the
  script; see the CONFIG block in the script for the format. Falls back to
  a built-in example list if unset.

## Rules

- Do not symlink `~/.config/cosmic` directly to the archive in this
  repository — always export/import via the tarball.

- When updating a settings file, regenerate it fresh with the export command
  above rather than hand-editing it.

- `src/cosmic-startup-workspaces.sh`'s app list is machine-specific — set it
  via `$COSMIC_STARTUP_APPS`, don't hardcode it in the script, and don't
  assume it matches the current machine without checking `cos-cli info`
  first.

- `cos-cli` is third-party and unaffiliated with System76, and has no
  tagged releases. `run/install` pins it to a specific commit
  (`COS_CLI_REV`) rather than floating on `main` — bump that rev
  deliberately, not automatically.
