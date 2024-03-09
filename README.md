# logseq-backup

Bash script to crate backup archives of [Logseq](https://logseq.com/) graphs, inspired by the workflow of [Joplin Backup Plugin](https://github.com/JackGruber/joplin-plugin-backup). Tested on It can run automatic backups through Systemd. 


## How does it work

This script is designed to create a compressed and optionally encrypted backup of a Logseq graph directory using 7zip, so you can safely store them also on removable or cloud storage. If a password is provided by the user, both file names and contents are encrypted with AES-256 encryption. 

Options such as graph directory and backup paths can be given on the command line or, better, in the `~/.config/logseq-backup.conf` configuration file (use the `--create-conf` option to create a template config file to customise).

Backup archives are named after current date and local hostname using this pattern, so you can tidily keep archives from multiple devices on the same location: `logseq-backup-YYYY-MM-DD_HH.MM.SS.hostname.7z` 

If no changes from last backup are detected, it doesn't create any new backup archive. 

The user can provide a maximum number of backups to keep, to automatically remove older backups. 

This script can create Systemd unit files to run backups periodically and every time the user logs in. 


## Requirements and Install

Requires `7z` binary to create archives. You can get it running `sudo apt install p7zip*` on Debian/Ubuntu, `sudo dnf install p7zip*` on Fedora or `brew install p7zip` on macOS. 

To enable (optional) automatic backup you need a Systemd-based distro (sorry macOS!). 

Then download, fork or copy and paste the script to your machine, put it in `~/.local/bin` or somewhere in your path and make it executable. 

```bash
$ cp logseq-backup.sh ~/.local/bin/ 
$ chmod +x logseq-backup.sh
```

### Install systemd service and timer

For automatic backups you need to install the required systemd unit files. To do so use the following command: 

```bash
$ logseq-backup.sh --install-unit-files
```

If not needed any more, you can uninstall them with: 

```bash
$ logseq-backup.sh --uninstall-unit-files
```

## Usage

TODO

```bash
$ logseq-backup.sh --help
    --create-conf             Create a template config file in ~/.config/logseq-backup.conf
    --install-unit-files      Setup unit files to automate backups
    --uninstall-unit-files    Remove unit files and disable automatic backups
```

## Examples

TODO

## Motivation

I love Logseq, and use Syncthng to sync my note graph between my devices. One day I got several sync conflicts between my desktop and laptop (it was my fault), and after spending too much time trying to resolve them, I decided I needed a way to take snapshot of my graph I can keep as a reference or as a quick restore point in case of disaster. I used [Joplin](https://joplinapp.org/) in the past, and liked the workflow of the [Backup plugin](https://github.com/JackGruber/joplin-plugin-backup), so I wrote this script, trying to replicate that workflow. 
