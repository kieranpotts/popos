# Pop_OS!

A personal backup of Kieran's Pop!_OS ("Cosmic" desktop) configuration, for
migrating to or restoring on a new machine. This is a data/config archive,
not application code — there is no build, test, or lint tooling.

## Project structure

- **[run/install](./run/install)** \
  Restores the backups below onto the current machine: extracts the Cosmic
  settings tarball, loads the dconf dump, and links/copies the backgrounds
  directory. Run `./run/install --help` for options. Does not apply
  `Dark.ron` — that has no scriptable import and must be applied manually.

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

## Rules

- Do not symlink `~/.config/cosmic` directly to the archive in this
  repository — always export/import via the tarball.

- When updating a settings file, regenerate it fresh with the export command
  above rather than hand-editing it.
