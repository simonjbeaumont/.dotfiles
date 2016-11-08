# .dotfiles

## Installation

```bash
$ git submodule init
$ git submodule update
$ python install.py --config install.yml
$ vi -c :VundleInstall -c :qall
$ source ~/.bash_profile
```

## Extra steps

#### For Mac:

```bash
$ launchctl load ~/.mutt/macos/*.plist
```
iTerm colors and macOS defaults script are in `macos/` directory.

#### For Linux:

```bash
$ crontab ~/.mutt/linux/crontab-entries
```
