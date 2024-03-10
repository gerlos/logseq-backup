#!/bin/bash
# logseq-backup: script to create compressed and encrypted backups of logseq graph
# backup archives are created using 7-zip and encrypted with AES256 encryption
# AUTHOR: Gerlando Lo Savio
# LICENSE: GNU General Public License 3.0
# DATE: 2024-03-10
# REQUIRES: p7zip ('sudo apt install p7zip*' on Ubuntu, Debian or
# 'sudo dnf install p7zip*' on Fedora or 'brew install p7zip' on macOS)
# Write its output on system log. Use 'journalctl -t "logseq-backup"' to see it

# WARNING: 7-zip archives don't keep owner, groups and file permissions. This shouldn't 
# be a problem if you backup your own notes. 
 
# Please put this script in ~/.local/bin and make it executable if you want to 
#run scheduled backups

#### DEFAULT CONFIGURATION ####
# Will be used if no configuration file exists
# WARNING: Don't quote paths if you need tilde expansion (e.g. ~ to /home/username)

## REQUIRED PARAMETERS ##
# Logseq graph dir to backup
note_dir=
# Directory to save archives to 
backup_dir=

## BASIC PARAMETERS ##
# Encryption password. 
# If empty and shell is interactive, asks to the user. Otherwise, continue without password
# WARNING: without any password the archive isn't encrypted
password=
# Maximum numer of backups to keep
max_backups=8

## ADVANCED PARAMETERS ##
# Custom backup archive file name
backup_filename=logseq-backup-$(date +"%Y-%m-%d_%H.%M.%S").$(hostname).7z
# How often should backups run?
backup_interval=12h
# If YES create a new backup only if it detects changes compared to previous backup
# Otherwise, it always create a new backup
only_on_change=YES
# checksum file from previous backup, used to detect changes
state_file=~/.local/state/logseq-backup.check
# System log tag. Use journalctl -t "$tag" to filter out messages from this script
tag=logseq-backup

#### END OF DEFAULT CONFIGURATION ####

# Custom configuration file path
config_file=~/.config/logseq-backup.conf
# Read custom configuration, if available
source $config_file 2> /dev/null

#### FUNCTIONS ####

# Print script usage
function usage () {
    echo "Usage: logseq-backup.sh [OPTION] 
Create logseq graph backups. Use parameters from command line or from config file 
in $config_file
    --note-dir=PATH             Logseq graph path
    --backup-dir=PATH           Backup dir path
    --password=PASSWORD         Encryption password
    --backup_filename=FILENAME  Backup archive file name 

    --create-conf               Create a template config file in $config_file
    --install-unit-files        Setup unit files to automate backups
    --uninstall-unit-files      Remove unit files and disable automatic backups
"
    return 0
}

# Write messages both to stdout and system log
function send_message () {
    logger -t $tag $1
    echo $1
}

# Create a file with the specified contents. Parent dir needs to exist
function write_file () {
    if [[ -e $2 ]]; then
        send_message "ERROR: File $2 already exists. I won't overwrite your custom files"
        send_message "Please move it elsewhere and re-run the command to create it"
        # exit 5
    else
        send_message "Writing $2 file..."
        echo -e "$1" > $2
    fi
}

# Create template configuration file in $config_file path
function create_conf () {
    send_message "Creating configuration file $config_file"
    config_template="#logseq-backup.sh template configuration file
# You can create this template with the command logseq-backup.sh --create-conf
# Please fill at least the required parameters 
# WARNING: Don't quote paths if you need tilde expansion (e.g. ~ to /home/username)

## REQUIRED PARAMETERS ##
# Logseq graph dir to backup
note_dir=
# Directory to save archives to 
backup_dir=

## BASIC PARAMETERS ##
# Encryption password. 
# If empty and shell is interactive, asks to the user. Otherwise, continue without password
# WARNING: without any password the archive isn't encrypted
password=
# Maximum numer of backups to keep
max_backups=$max_backups

## ADVANCED PARAMETERS ##
# Custom backup archive file name
backup_filename=$backup_filename
# If YES create a new backup only if it detects changes compared to previous backup
# Otherwise, it always create a new backup
only_on_change=$only_on_change
# checksum file from previous backup, used to detect changes
state_file=$state_file
# System log tag. Use journalctl -t "\$tag" to filter out messages from this script
tag=$tag"
    write_file "$config_template" $config_file 
    return 0
}

# Create and enable unit files to automate backups
function install_unit_files () {
    send_message "Install and enable unit files"
    # create logseq-backup.service
    service_template="
# Unit file to schedule Logseq backups. See ~/.local/bin/logseq-backup.sh
[Unit]
Description=BackLogseq notes backup. Run at every login
After=graphical.target

[Service]
Type=simple
ExecStart=/bin/bash %h/.local/bin/logseq-backup.sh

[Install]
WantedBy=default.target
"
    write_file "$service_template" ~/.config/systemd/user/logseq-backup.service
    # create logse-backup.timer
    timer_template="
# Unit file to schedule Logseq backups. See ~/.local/bin/logseq-backup.sh
[Unit]
Description=Timer to run note backup every $backup_interval

[Timer]
OnUnitActiveSec=$backup_interval
Unit=logseq-backup.service

[Install]
WantedBy=default.target
"
    write_file "$timer_template" ~/.config/systemd/user/logseq-backup.timer
    # enable service and timer
    systemctl --user enable logseq-backup.service
    systemctl --user start logseq-backup.service 
    systemctl --user enable logseq-backup.timer
    systemctl --user start logseq-backup.timer
    return 0
}

# Disable and remove unit files to automate backups
function uninstall_unit_files () {
    send_message "Disable and uninstall unit files"
    # stop, disable and remove service and timer
    systemctl --user stop logseq-backup.timer
    systemctl --user stop logseq-backup.service
    systemctl --user disable logseq-backup.timer
    systemctl --user disable logseq-backup.service 
    rm  ~/.config/systemd/user/logseq-backup.service
    rm  ~/.config/systemd/user/logseq-backup.timer 
    return 0
}

# Decide if a new backup is needed. First check user preference, then check 
# timestamp checksum and compare with results from previous run, if available
function is_backup_needed () {
    if [[ $only_on_change == "YES" ]]; then
        # Calculate checksum of timestamps of files in note directory
        status=($( find $note_dir -type f -printf '%T@,' | md5sum ))
        # Retrieve last backup checksum, if available
        if old_status=$(<$state_file); then
            # If checksums match we don't need a new backup
            if [[ "$status" == "$old_status" ]]; then
                send_message "No change detected: backup unnecessary"
                return 1
            else
                send_message "Changes detected: let's create a new backup"
                # save current checksum in state file
                echo $status > $state_file
                return 0
            fi
        else 
            send_message "No previous backup found, let's create first backup..."
            # save current checksum in state file
            echo $status > $state_file
            return 0
        fi
    else
        send_message "User required to always create a backup..."
        return 0
    fi
}

# Validate options 
function validate_options () {
    # We can't continue if note_dir and backup_dir are not defined
    if [[ -z "$note_dir" ]] || [[ -z "$backup_dir" ]]; then
        send_message "User did not provide note dir and/or backup dir, we can't continue!"
        return 2
    else 
        return 0
    fi
}

function main () {
    #### Processo effettivo ####
    if validate_options && is_backup_needed; then
        # Crea il pacchetto di backup
        send_message "Rilevate modifiche: Eseguo il backup delle note..."
        7z a -p${password} -mhe=on "$backup_dir/$backup_filename" "$note_dir"/

        # Verifica se la creazione del pacchetto ha avuto successo o meno
        if [[ $? -eq 0 ]]; then
            send_message "Backup di $note_dir su $backup_dir/$backup_filename completato."
        else 
            send_message "Backup di $note_dir su $backup_dir/$backup_filename fallito - impossibile creare il pacchetto."
            exit 3
        fi

        # Rimuovere i backup eccedenti
        send_message "Cerco backup eccedenti..."
        backup_count=$(ls -t "$backup_dir" | wc -l)
        if [ $backup_count -gt $max_backups ]; then
            excess_backups=$((backup_count - max_backups))
            ls -t "$backup_dir" | tail -n $excess_backups | xargs -I {} rm "$backup_dir"/{}
            send_message "$excess_backups backup eccedenti rimossi."
        else
            send_message "Nessun backup eccedente da rimuovere."
        fi

    return 0 
    fi
}
