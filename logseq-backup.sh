#!/bin/bash
# logseq-backup: script to create compressed and encrypted backups of logseq graph
# archivi compressi e criptati con 7-zip
# Richiede: pacchetto p7zip (Ubuntu, Debian) o p7zip* (Fedora)
# Scrive sul log di sistema il risultato delle operazioni: 
# Usa journalctl -t "logseq-backup" per vedere questi record
# Attenzione: 7-zip non salva proprietari, gruppi e permessi dei file! 
# Questo non è un problema se usi questo script per fare il backup delle tue 
# note personali. 
# Per usarlo con gli unit file per systemd, colloca questo script in ~/bin/

#### DEFAULT CONFIGURATION ####

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
# If YES create a new backup only if it detects changes compared to previous backup
# Otherwise, it always create a new backup
only_on_change=YES
# checksum file from previous backup, used to detect changes
state_file=~/.local/state/logseq-backup.check
# System log tag. Use journalctl -t "$tag" to filter out messages from this script
tag=logseq-backup

# Custom configuration file path
config_file=~/.config/logseq-backup.conf

#### END OF DEFAULT CONFIGURATION ####

## FUNCTIONS
# Write messages both to stdout and system log
send_message () {
    logger -t $tag $1
    echo $1
}

# Create a file with the specified contents. Create parent dir if doesn't exist
write_file () {
    send_message "Writing $1 file..."
    echo -e $2 > $1
}

# Create template configuration file in ~/.config/logseq-backup.conf
create-conf () {
    send_message "create conf"
    # Create parent path if it doesn't exist
    mkdir -p $(dirname "$config_file")
    cat <<EOF > $config_file
EOF
}

# Create and enable unit files to automate backups
install-unit-files () {
    send_message "install unit files"
}

# Disable and remove unit files to automate backups
install-unit-files () {
    send_message "uninstall unit files"
}

# Leggi la configurazione personalizzata, se presente
source $config_file > /dev/null

main () {
    #### Validazione delle opzioni ####
    # Se non c'è una password nella configurazione, e non è una shell interattiva, esci con errore
    if [[ -z "$password" ]] && ! [[ -t 0 ]]; then
        send_message "L'utente non ha fornito una password, non posso continuare!"
        exit 1
    fi

    # Se non è stata definito il percorso del grafo di logseq o il percorso di backup, esci con errore
    if [[ -z "$note_dir" ]] || [[ -z "$backup_dir" ]]; then
        send_message "L'utente non ha definito note_dir e/o backup_dir, non posso continuare!"
        exit 2
    fi

    #### Processo effettivo ####
    # Calcola il checksum dei timestamp dei file della directory delle note
    status=($( find $note_dir -type f -printf '%T@,' | md5sum ))
    # Recupera il checksum dell'ultimo backup dal file di controllo
    old_status=$(<$state_file)

    # Verifica se i due checksum sono uguali: se sì, non è necessario proseguire a creare 
    # un nuovo pacchetto di backup
    if [[ "$status" == "$old_status" ]]; then
        send_message "Nessuna modifica rilevata: Backup non necessario."
        exit 0
    fi

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

    # salva il checksum nel file di stato
    echo $status > $state_file

    exit 0 
}
