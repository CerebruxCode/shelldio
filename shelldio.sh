#!/bin/bash
#
#
# Shelldio - ακούστε online ραδιόφωνο από το τερματικό
# Copyright (c)2018 Vasilis Niakas and Contributors
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation version 3 of the License.
#
# Please read the file LICENSE and README for more information.
#
#

# Verbosity
ERR="[Πρόβλημα]   : "
INFO="[Πληροφορία] : "
FATAL="[Σφάλμα]     : "

# Έλεγχος προαπαιτούμενων binaries
echo "$INFO ελεγχος προαπαιτούμενων"
player=$(command -v mpv 2>/dev/null || command -v mplayer 2>/dev/null || command -v mpg123 2>/dev/null || echo "1")
if [[ $player = 1 ]];
then
    echo "$FATAL δε βρέθηκε συμβατός player, συμβατοί players είναι οι 'mpv', 'mplayer' και 'mpg123'"
    exit 1
fi
for binary in wget info tput sleep clear killall; do
    if ! command -v $binary &> /dev/null; then
        echo "$FATAL δε βρέθηκε το '$binary'"
        exit 1
    fi
done

# Έλεγχος αρχείου σταθμών
user_stations="$HOME/.shelldio/my_stations.txt"
all_stations="$HOME/.shelldio/all_stations.txt"
stations_url="https://raw.githubusercontent.com/CerebruxCode/shelldio/master/.shelldio/all_stations.txt"
if [ "$#" -eq "0" ]
then
    echo "$ERR δεν ορίστηκε προσαρμοσμένο αρχείο σταθμών"
    echo "$INFO φόρτωση αγαπημένων σταθμών του χρήστη $USER"
    if [ ! -f "$user_stations" ]; then
        echo "$ERR δεν βρέθηκε το αρχείο '$user_stations'"
        echo "$INFO φόρτωση προκαθορισμένων σταθμών"
        if [ ! -f "$all_stations" ]; then
            echo "$ERR δεν βρέθηκε το αρχείο '$all_stations'"
            echo "$INFO προσπάθεια ανάκτησης αρχείου προκαθορισμένων σταθμών από το github"
            mkdir ~/.shelldio &> /dev/null
            if ! wget $stations_url -O "$all_stations" &> /dev/null;
            then
                echo "$ERR προέκυψε πρόβλημα με το δίκτυο"
                echo "$FATAL αδυναμία φόρτωση σταθμών"
                exit 1
            fi
            echo "$INFO το αρχείο κατέβηκε επιτυχώς"
        fi
        echo "$INFO φόρτωση προκαθορισμένων σταθμών"
        stations="$all_stations"
    else
        echo "$INFO φόρτωση αγαπημένων σταθμών"
        stations="$user_stations"
    fi
else
    echo "$INFO φόρτωση προσαρμοσμένου αρχείου"
    if [ ! -f "$1" ]; then
        echo "$ERR δεν βρέθηκε το αρχείο '$1'"
        echo "$FATAL αδυναμία φόρτωση σταθμών"
        exit 1
    fi
    stations=$1
fi

while true
do
    terms=0
    trap ' [ $terms = 1 ] || { terms=1; kill -TERM -$$; };  exit' EXIT INT HUP TERM QUIT
    
    info() {
        tput civis      -- invisible  # Εξαφάνιση cursor
        echo -ne "| Η ώρα είναι $(date +"%T")\n| Ακούτε $stathmos_name\n| Πατήστε Q/q για έξοδο ή R/r για επιστροφή στη λίστα σταθμών"
    }
    echo "---------------------------------------------------------"
    echo "Shelldio - ακούστε online ραδιόφωνο από το τερματικό"
    echo "---------------------------------------------------------"
    echo "https://github.com/CerebruxCode/Shelldio"
    
    while true
    do
        echo "---------------------------------------------------------"
        num=0
        
        while IFS='' read -r line || [[ -n "$line" ]]; do
            num=$(( num + 1 ))
            echo ["$num"] "$line" | cut -d "," -f1
        done < "$stations"
        echo "---------------------------------------------------------"
        read -rp "Διαλέξτε Σταθμό (Q/q για έξοδο): " input
        
        if [[ $input = "q" ]] || [[ $input = "Q" ]]
        then
            echo "Έξοδος..."
            tput cnorm   -- normal  # Εμφάνιση cursor
            exit 0
        fi
        
        # Έλεγχος αν το input είναι μέσα στο εύρος της λίστας των σταθμών
        if [ "$input" -gt 0 ] && [ "$input" -le $num ];
        then
            stathmos_name=$(< "$stations" head -n$(( "$input" )) | tail -n1 | cut -d "," -f1)
            stathmos_url=$(< "$stations" head -n$(( "$input" )) | tail -n1 | cut -d "," -f2)
            break
        else
            echo "Αριθμός εκτός λίστας"
            sleep 2
            clear
        fi
    done
    
    $player "$stathmos_url" &> /dev/null &
    while true
    
    do
        clear
        info
        sleep 0
        read -r -n1 -t1 input          # Για μικρότερη αναμονή της read
        if [[ $input = "q" ]] || [[ $input = "Q" ]]
        then
            clear
            echo "Έξοδος..."
            tput cnorm   -- normal  # Εμφάνιση cursor
            exit 0
        fi
        
        if [[ $input = "r" ]] || [[ $input = "R" ]]
        then
            killall -9 "$player" &> /dev/null
            clear
            echo "Επιστροφή στη λίστα σταθμών"
            tput cnorm   -- normal  # Εμφάνιση cursor
            sleep 2
            clear
            break
            
            
            
        fi
    done
    
done
