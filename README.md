# logseq-backup

Bash script to crate backup archives of [Logseq](https://logseq.com/) graphs, inspired by the workflow of [Joplin Backup Plugin](https://github.com/JackGruber/joplin-plugin-backup). Tested on It can run automatic backups through Systemd. 


## How does it work

This script is designed to create a compressed and optionally encrypted backup of a Logseq graph directory using 7zip, so you can safely store them also on removable or cloud storage. If a password is provided by the user, both file names and contents are encrypted with AES-256 encryption. 

- Options such as graph directory and backup paths can be given on the command line or, better, in the `~/.config/logseq-backup.conf` configuration file (use the `--create-conf` option to create a template config file to customise).
- Backup archives are named after current date and local hostname using this pattern, so you can tidily keep archives from multiple devices on the same location: `logseq-backup-YYYY-MM-DD_HH.MM.SS.hostname.7z` 
- If no changes from last backup are detected, it doesn't create any new backup archive. 
- The user can provide a maximum number of backups to keep, to automatically remove older backups. 
- This script can create Systemd unit files to run backups periodically and every time the user logs in. 


## Requirements and Install

Requires `7z` binary to create archives. You can get it running `sudo apt install p7zip*` on Debian/Ubuntu, `sudo dnf install p7zip*` on Fedora or `brew install p7zip` on macOS. 

To enable (optional) automatic backup you need a Systemd-based distro (sorry macOS users!). 

Then download, fork or copy and paste the script to your machine, put it in `~/.local/bin` or somewhere in your path and make it executable. 

```bash
$ cp logseq-backup.sh ~/.local/bin/ 
$ chmod +x ~/.local/bin/logseq-backup.sh
```

### Install systemd service and timer

Automatic backups are done via systemd. To install the required systemd unit files: 

```bash
$ logseq-backup.sh -i
```

If not needed any more, you can uninstall them with: 

```bash
$ logseq-backup.sh -u
```


## Usage

```bash
$ logseq-backup.sh --help
Usage: logseq-backup.sh [OPTION] 
Create logseq graph backups. Use parameters from command line or from config file 
in ~/.config/logseq-backup.conf
Command line parameters override config file ones
    -n NOTEPATH     Logseq graph path directory
    -b BACKUPPATH   Backup directory path
    -p PASSWORD     Encryption password
    -f FILENAME     Backup archive file name 

    -c     Create a template config file in ~/.config/logseq-backup.conf
    -i     Setup systemd unit files to automate backups
    -u     Remove systemd unit files and disable automatic backups
    -h     Display this help
```


## Examples

### Example #1: everything on the command line

Let's say that your notes are in `~/Documents/logseq` and you want to backup them
to `~/Backup/notes/`, encrypting them with the password `foobar`:

```shell
$ ./logseq-backup.sh -n ~/Documents/logseq/ -b ~/Backup/notes/ -p foobar
Changes detected: let's create a new backup
Changes detected: Creating a new backup archive...

7-Zip [64] 16.02 : Copyright (c) 1999-2016 Igor Pavlov : 2016-05-21
p7zip Version 16.02 (locale=it_IT.UTF-8,Utf16=on,HugeFiles=on,64 bits,12 CPUs Intel(R) Core(TM) i7-9750H CPU @ 2.60GHz (906EA),ASM,AES-NI)

Scanning the drive:
7 folders, 22 files, 28151425 bytes (27 MiB)

Creating archive: /home/user/Backup/notes//logseq-backup-2024-03-11_19.27.23.carbon.7z

Items to compress: 29

                                                                              
Files read from disk: 22
Archive size: 20426585 bytes (20 MiB)
Everything is Ok
Backup of /home/user/Documents/logseq/ in /home/user/Backup/notes//logseq-backup-2024-03-11_19.27.23.carbon.7z completed.
Looking form excess archives to remove...
No excess backups to remove.
```

### Example #2: fully automated backup

Let's say we want to automate previous backup, running it at every login and twice a day.

First, put the script in your path:

```shell
$ mv logseq-backup.sh ~/.local/bin
```

Then create a template configuration file:

```shell
logseq-backup -c
```

Edit the configuration file in `~/.config/logseq-backup.conf` as needed. For example: 

```
# Logseq graph dir to backup
note_dir=~/Documents/logseq
# Directory to save archives to 
backup_dir=~/Backup/notes/

# Encryption password
password=foobar
# How often should backups run?
backup_interval=12h
```

Install systemd unit files to automate backups:

```shell
$ logseq-backup.sh -i
```

This way, at next login and 12 hours later you'll get a new package, if there are 
changes in your Logseq graph. 


### Restoration example

Backup are useless if you can't restore them. From time to time you should try to
restore some of your backup archives to be sure everything went fine. 

Luckily, on Logseq you can open a second (or third, ...) graph TODO


## Motivation

I love Logseq, and use Syncthng to sync my note graph between my devices. One day I got several sync conflicts between my desktop and laptop (it was my fault), and after spending too much time trying to resolve them, I decided I needed a way to take snapshot of my graph I can keep as a reference or as a quick restore point in case of disaster. 

I used [Joplin](https://joplinapp.org/) in the past, and liked the workflow of the [Backup plugin](https://github.com/JackGruber/joplin-plugin-backup), so I wrote this script, trying to replicate that workflow. 
