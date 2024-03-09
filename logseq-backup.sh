#!/bin/bash
# logseq-backup: script to create compressed and encrypted
# archivi compressi e criptati con 7-zip
# Richiede: pacchetto p7zip (Ubuntu, Debian) o p7zip* (Fedora)
# Scrive sul log di sistema il risultato delle operazioni: 
# Usa journalctl -t "logseq-backup" per vedere questi record
# Attenzione: 7-zip non salva proprietari, gruppi e permessi dei file! 
# Questo non è un problema se usi questo script per fare il backup delle tue 
# note personali. 
# Per usarlo con gli unit file per systemd, colloca questo script in ~/bin/

#### CONFIGURAZIONE DI DEFAULT ####

## IMPOSTAZIONI DI BASE ##
# Directory delle note
note_dir=
# Directory di backup
backup_dir=
# Numero massimo di backup da mantenere
max_backups=8
# Password per la crittografia: Se vuoto e siamo su una shell interattiva, 
# chiede all'utente, altrimenti esce con errore
# ATTENZIONE: se lutente digita una password vuota, il pacchetto NON viene criptato!
password=

## IMPOSTAZIONI AVANZATE ##
# file di configurazione personalizzato
config_file=~/.config/logseq-backup.conf
# Nome del file di backup
backup_filename=logseq-backup-$(date +"%Y-%m-%d_%H.%M.%S").$(hostname).7z
# Se impostato su YES crea un nuovo pacchetto SOLO se ci sono modifiche rispetto al
# backup precedente
only_on_change=YES
# File di controllo dei dati dell'ultimo backup, utile per verificare se ci sono 
# modifiche rispetto al backup precedente
state_file=~/.local/state/logseq-backup.check
# Identificativo per syslog
tag=logseq-backup
#### ####

## FUNCTIONS
# Write messages both to stdout and to system log
send_message () {
    logger -t $1 $2
    echo $2
}

# Create template configuration file in ~/.config/logseq-backup.conf
create-conf () {
    echo "create conf"
}

# Create and enable unit files to automate backups
install-unit-files () {
    echo "install unit files"
}

# Disable and remove unit files to automate backups
install-unit-files () {
    echo "uninstall unit files"
}

# Leggi la configurazione personalizzata, se presente
source $config_file > /dev/null

main () {
    #### Validazione delle opzioni ####
    # Se non c'è una password nella configurazione, e non è una shell interattiva, esci con errore
    if [[ -z "$password" ]] && ! [[ -t 0 ]]; then
        echo "L'utente non ha fornito una password, non posso continuare!"
        logger -t $tag "L'utente non ha fornito una password, non posso continuare!"
        exit 1
    fi

    # Se non è stata definito il percorso del grafo di logseq o il percorso di backup, esci con errore
    if [[ -z "$note_dir" ]] || [[ -z "$backup_dir" ]]; then
        echo "L'utente non ha definito note_dir e/o backup_dir, non posso continuare!"
        logger -t $tag "L'utente non ha definito note_dir e/o backup_dir, non posso continuare!"
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
        echo "Nessuna modifica rilevata: Backup non necessario."
        logger -t $tag "Nessuna modifica rilevata: Backup non necessario."
        exit 0
    fi

    # Crea il pacchetto di backup
    echo "Rilevate modifiche: Eseguo il backup delle note..."
    logger -t $tag "Eseguo il backup di $note_dir su $backup_dir/$backup_filename ..."
    7z a -p${password} -mhe=on "$backup_dir/$backup_filename" "$note_dir"/

    # Verifica se la creazione del pacchetto ha avuto successo o meno
    if [[ $? -eq 0 ]]; then
        echo "Backup completato."
        logger -t $tag "Backup di $note_dir su $backup_dir/$backup_filename completato."
    else 
        echo "Backup fallito - impossibile creare il pacchetto"
        logger -t $tag "Backup di $note_dir su $backup_dir/$backup_filename fallito - impossibile creare il pacchetto."
        exit 3
    fi

    # Rimuovere i backup eccedenti
    echo "Cerco backup eccedenti..."
    logger -t $tag "Cerco backup eccedenti..."
    backup_count=$(ls -t "$backup_dir" | wc -l)
    if [ $backup_count -gt $max_backups ]; then
        excess_backups=$((backup_count - max_backups))
        ls -t "$backup_dir" | tail -n $excess_backups | xargs -I {} rm "$backup_dir"/{}
        echo "$excess_backups backup eccedenti rimossi."
        logger -t $tag "$excess_backups backup eccedenti rimossi."
    else
        echo "Nessun backup eccedente da rimuovere."
        logger -t $tag "Nessun backup eccedente da rimuovere."
    fi

    # salva il checksum nel file di stato
    echo $status > $state_file

    exit 0 
}
