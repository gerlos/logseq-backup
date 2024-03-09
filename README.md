# logseq-backup

Bash script to crate backup archives of [Logseq](https://logseq.com/) graphs, inspired by the workflow of [Joplin Backup Plugin](https://github.com/JackGruber/joplin-plugin-backup). It can run automatic backups through Systemd. 

## Requirements and Install

Requires `7z` binary to create archives. You can get it running `sudo apt install p7zip*` on Debian/Ubuntu or `sudo dnf install p7zip*` on Fedora. 

To enable (optional) automatic backup you need a Systemd-based distro. 

Then download, fork or copy and paste the script to your machine and make it executable.

```bash
 $ chmod +x logseq-backup.sh
```

### Install systemd service and timer

TODO

## Usage

TODO

## Examples

TODO

## Motivation

I love Logseq, and use Syncthng to sync my note graph between my devices. One day I got several sync conflicts between my desktop and laptop (it was my fault), and after spending too much time trying to resolve them, I decided I needed a way to take snapshot of my graph I can keep as a reference or as a quick restore point in case of disaster. I used [Joplin](https://joplinapp.org/) in the past, and liked the workflow of the [Backup plugin](https://github.com/JackGruber/joplin-plugin-backup), so I wrote this script, trying to replicate that workflow. 
