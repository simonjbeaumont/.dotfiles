# .dotfiles

## Installation

```bash
$ git submodule init
$ git submodule update
$ python install.py --config install.yml
$ vi -c :VundleInstall -c :qall
$ source ~/.bash_profile
```

## Customisation

The installation script is driven from a YAML configuration.

### Simple symlinks

If you just wish to have a symlink to a file in your dotfiles repo:

```yaml
~/desired/location/of/symlink: relative/path/to/file/in/repo
```

### Templates

```yaml
~/desired/location/of/symlink:
  template: relative/path/to/template/in/repo
  # list of substitutions to make
  subs:
    # replace occurences of "@@TO_REPLACE_STRING@@" with "REPLACE_WITH_STRING"
    - TO_REPLACE_STRING: REPLACE_WITH_STRING
    # entries in the list with no value will cause a prompt for the value
    - TO_PROMPT_STRING
    ...
```

## Extra steps

```sh
$ cd ~/.vim/bundle/YouCompleteMe
$ ./install.py --clang-completer
```

### For Mac:

The launchctl scripts for mutt (mbsync) need to be placed in
`~/Library/LaunchAgents/` and then loaded:

```bash
$ cp ~/.mutt/macos/sjbx.*.plist ~/Library/LaunchAgents
$ launchctl load ~/Library/LaunchAgents/sjbx.*.plist
```

iTerm colors and macOS defaults script are in `macos/` directory.

List of useful Homebrew packages aslo in the `macos/` directory.

### For Linux:

```bash
$ crontab ~/.mutt/linux/crontab-entries
```
