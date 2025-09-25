#!/bin/bash
#
#
# Shelldio - ακούστε online ραδιόφωνο από το τερματικό
# Shelldio was based on bash_radio.sh (c)2018-2020 Vasilis Niakas and Contributors.
#
# (c)2020 Shelldio | Salih Emin, JohnGavr and Contributors.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation version 3 of the License.
#
# Please read the file LICENSE and README for more information.
#

### Colors
if [ -t 1 ]; then
    RED=$(printf '\033[31m')
    BLUE=$(printf '\033[34m')
    RESET=$(printf '\033[m')
else
    RED=""
    BLUE=""
    RESET=""
fi

### Variable List

version="v25.09.25"

all_stations="$HOME/.shelldio/all_stations.txt"
my_stations="$HOME/.shelldio/my_stations.txt"

### Functions List

validate_csv() {
	awk 'BEGIN{FS=","}!n{n=NF}n!=NF{failed=1;exit}END{print !failed}' "$1"
}

validate_station_lists() {
	if [ -f "$all_stations" ]; then
		if [[ $(validate_csv "$all_stations") -eq 0 ]]; then
			echo "Πρόβλημα: Η λίστα σταθμών: $all_stations δεν είναι έγκυρη"
			echo "Εκτέλεσε shelldio --fresh για να κατεβάσεις τη λίστα εκ νέου"
			exit 1
		fi
	fi

	if [ -f "$my_stations" ]; then
		if [[ $(validate_csv "$my_stations") -eq 0 ]]; then
			echo "Πρόβλημα: Η λίστα σταθμών: $my_stations δεν είναι έγκυρη"
			echo "Εκτέλεσε shelldio --reset για να διαγράψεις τη λίστα αγαπημένων"
			echo "Στη συνέχεια πρόσθεσε ξανά τους αγαπημένους σου σταθμούς"
			exit 1
		fi
	fi
}

#start_mpv() {
#  mpv --no-video --input-ipc-server=/tmp/mpv_socket "$stathmos_url" &>/dev/null &
#  mpv_pid=$!
#}
# start_mpv() {
# 	if [[ -n "$mpv_pid" ]]; then
# 		kill $mpv_pid 2>/dev/null
# 		wait $mpv_pid 2>/dev/null
# 	fi
# 	mpv --no-video --input-ipc-server=/tmp/mpv_socket "$stathmos_url" &>/dev/null &
# 	mpv_pid=$!
# }
fade_out() {
  if [ -S /tmp/mpv_socket ]; then
    for vol in {100..0..-5}; do
      echo '{ "command": ["set_property", "volume", '"$vol"'] }' | socat - /tmp/mpv_socket &>/dev/null
      sleep 0.03
    done
  fi
}

fade_in() {
  if [ -S /tmp/mpv_socket ]; then
    for vol in {0..100..5}; do
      echo '{ "command": ["set_property", "volume", '"$vol"'] }' | socat - /tmp/mpv_socket &>/dev/null
      sleep 0.03
    done
  fi
}

start_mpv() {
    if [[ -n "$mpv_pid" ]] && kill -0 "$mpv_pid" 2>/dev/null; then
        fade_out
        kill "$mpv_pid" 2>/dev/null
        # Wait up to 3 seconds for process to terminate
        for i in {1..30}; do
            if ! kill -0 "$mpv_pid" 2>/dev/null; then
                break
            fi
            sleep 0.1
        done
        # Force kill if still running
        if kill -0 "$mpv_pid" 2>/dev/null; then
            kill -9 "$mpv_pid" 2>/dev/null
        fi
        rm -f /tmp/mpv_socket
    fi

    mpv --no-video --input-ipc-server=/tmp/mpv_socket --volume=0 "$stathmos_url" &>/dev/null &
    mpv_pid=$!

    # Wait for the IPC socket to be ready with loading indicator
    echo -n "Συνδέεται στον σταθμό"
    for i in {1..40}; do
        if [ -S /tmp/mpv_socket ]; then
            echo " OK"
            fade_in
            return 0
        fi
        echo -n "."
        sleep 0.05
    done
    
    # Connection failed
    echo " ✗"
    echo "Αποτυχία σύνδεσης στον σταθμό"
    if kill -0 "$mpv_pid" 2>/dev/null; then
        kill -9 "$mpv_pid" 2>/dev/null
    fi
    mpv_pid=""
    return 1
}

get_current_title() {
    if [ -S /tmp/mpv_socket ]; then
        local title
        # Try to get ICY metadata first (more reliable for radio streams)
        title=$(printf '{ "command": ["get_property", "metadata"] }\n' | socat - /tmp/mpv_socket 2>/dev/null | jq -r '(.data // {}) | to_entries[] | select(.key | ascii_downcase | test("icy-title|title")) | .value' 2>/dev/null | head -n1)
        
        # Fallback to media-title if no metadata
        if [[ -z "$title" || "$title" == "null" ]]; then
            title=$(printf '{ "command": ["get_property", "media-title"] }\n' | socat - /tmp/mpv_socket 2>/dev/null | jq -r '.data' 2>/dev/null)
        fi
        
        # Clean up the title
        if [[ -n "$title" && "$title" != "null" && "$title" != "radio" ]]; then
            echo "$title"
        else
            echo ""
        fi
    else
        echo ""
    fi
}

# Μήνυμα καλωσορίσματος

welcome_screen() {
	echo '                                       .-_   _-.'
	echo '                                      / / _ _ \ \ '
	echo '                                     ( ( (-o-) ) )'
	echo '                                      \.\_-!-_/./'
	echo '                                         --+--'
	echo "                                           |"
	echo '                                           |'
	echo '._;======================================;_|'
	echo '| [______________________________________] |'
	echo '|      |############################|      |'
	echo '| (_)  |############################|  (_) |'
	echo "|_______________ Shelldio _________________|"
	echo "|               $version                  |"
	echo "|                                          |"
	echo "|       Ακούστε τους αγαπημένους σας       |"
	echo "|        σταθμούς από το τερματικό         |"
	echo "|                                          |"
	echo "|      https://cerebrux.net/shelldio       |"
	echo "|__________________________________________|"
}

option_detail() {
	cat <<EOF

Το shelldio έχει τις παρακάτω επιλογές

	Χρήση: shelldio [όρισμα]

Αν δεν δοθεί όρισμα, το shelldio θα ξεκινήσει με τους αγαπημένους σας σταθμούς (εφόσον υπάρχουν).
Αλλιώς θα φορτώσει την ενσωματωμένη λίστα με όλους τους διαθέσιμους σταθμούς.

Αν θέλουμε να ξεκινήσουμε το shelldio με όρισμα τότε αυτό μπορεί να είναι ένα από τα παρακάτω:

	<1-9>:		Γρήγορη εκκίνηση. Ξεκινάει την αναπαραγωγή του σταθμού απευθείας
			από τη θέση που δόθηκε ως όρισμα χωρίς να εμφανίζει την λίστα αγαπημένων μας.
			(π.χ. shelldio 4, ξεκινάει τον σταθμό που βρίσκεται στην θέση 4 από την λίστα των αγαπημένων μας)

	-a, --add: 	Εμφανίζει την γενική λίστα με όλους τους διαθέσιμους ραδιοφωνικούς σταθμούς
			και σας δίνει την δυνατότητα να προσθέσετε, όποια επιθυμείτε, στην λίστα με τoυς αγαπημένους σας
			σταθμούς (στο αρχείο $my_stations)

	-n, --new:	Σας δίνει την δυνατότητα να προσθέσετε έναν νέο σταθμό στην λίστα με τους αγαπημένους σας
			ραδιοφωνικούς σταθμούς (στο αρχείο $my_stations)

	-f, --fresh: 	Κατεβάζει εκ νέου την γενική λίστα των ραδιοφωνικών σταθμών με επικαιροποιημένους
			ραδιοφωνικούς σταθμούς, διορθωμένα links αλλά και νέους ραδιοφωνικούς σταθμούς

	-h, --help: 	Εμφανίζει αυτές τις πληροφορίες για την χρήση της εφαρμογής

	-j, --joker: 	Ξεκινάει την αναπαραγωγή τυχαίου σταθμού

	-l, --list: 	Εμφανίζει την γενική λίστα με τους ραδιοφωνικούς σταθμούς. Μπορείτε να χρησιμοποιήσετε
			την επιλογή αυτή σε συνδυασμό με άλλη εντολή. πχ. για να κάνετε αναζήτηση :

					shelldio -l | grep -i "onoma stathmou"

	-r, --remove: 	Εμφανίζει την λίστα με τους σταθμούς που έχετε προσθέσει στα αγαπημένα σας και σας
			δίνει την δυνατότητα να αφαιρέσετε όποια θέλετε
			(από το $my_stations)

	-u, --update: 	Σας δίνει την δυνατότητα να κάνετε αναβάθμιση του Shelldio στην νεότερη διαθέσιμη έκδοση.
			Προσοχή, η αναβάθμιση με αυτόν τον τρόπο ισχύει μόνο για αυτούς που έκαναν εγκατάσταση το shelldio
			με git clone και όχι απο πακέτο εγκατάστασης (π.χ. στο Arch Linux)

	--reset: 	Προσοχή - Καθαρίζει τη λίστα με τους σταθμούς που έχετε προσθέσει στα αγαπημένα σας
			διαγράφοντας το αρχείο $my_stations. Είναι χρήσιμο αν
			θέλετε να ξεκινήσετε απο την αρχή την δημιουργία της λίστας των αγαπημένων σας.
EOF
}

# Δημιουργεί και εμφανίζει σε λίστα τους σταθμούς στο txt file που δέχεται σαν flag
list_stations() {
	num=0  # Initialize counter
	while IFS='' read -r line || [[ -n "$line" ]]; do
		num=$((num + 1))
		echo ["$num"] "$line" | cut -d "," -f1
	done <"$1"
}

# Πληροφορίες που εμφανίζονται μετά την επιλογή του σταθμού
info() {
    welcome_screen
    tput civis # Εξαφάνιση cursor
    
    # Display initial station info
    echo ""
    echo -ne "  Ακούτε: $stathmos_name\n"
    echo ""
    
    last_title=""
    last_time=""
    
    while kill -0 "$mpv_pid" 2>/dev/null; do
        current_title=$(get_current_title)
        current_time=$(date +"%T")
        
        # Update title only when it changes  
        if [[ "$current_title" != "$last_title" ]]; then
            tput cup 21 0  # Move to title line (after welcome screen)
            tput el        # Clear line
            if [[ -n "$current_title" && "$current_title" != "null" && "$current_title" != "radio" ]]; then
                echo -ne "  Τίτλος: $current_title"
            else
                echo -ne "  Τίτλος: Φόρτωση..."
            fi
            last_title="$current_title"
        fi
        
        # Update time display at the bottom
        if [[ "$current_time" != "$last_time" ]]; then
            tput cup 23 0  # Move to time line (bottom area)
            tput el        # Clear line
            echo -ne "  Σταθμός: [$selected_play]    Η ώρα είναι $current_time"
            last_time="$current_time"
        fi
        
        # Move cursor to menu at the bottom
        tput cup 24 0
        echo -ne "   ____________               ___________"
        tput cup 25 0
        echo -ne "  [Έξοδος (Q/q)].___________.[Πίσω  (R/r)]"
        tput cup 26 0
        echo -ne " "
        
        # Check for user input
        read -r -n1 -s -t 0.1 input_play
        case "$input_play" in
            [Qq]) return 1 ;;  # Signal to quit
            [Rr]) return 0 ;;  # Signal to return to menu
        esac
    done
}

add_stations() {
	echo "Εμφάνιση λίστας σταθμών"
	sleep 1
	list_stations "$all_stations"
	while true; do
		read -rp "Επέλεξε αριθμού σταθμου  (Q/q για έξοδο): " input_station
		if [[ $input_station = "q" ]] || [[ $input_station = "Q" ]]; then
			echo "Έξοδος..."
			exit 0
		elif [ "$input_station" -gt 0 ] && [ "$input_station" -le "$num" ]; then #έλεγχος αν το input είναι μέσα στο εύρος της λίστας των σταθμών
			station=$(sed "${input_station}q;d" "$all_stations")
			stathmos_name=$(echo "$station" | cut -d "," -f1)
			stathmos_url=$(echo "$station" | cut -d "," -f2)
			echo "$stathmos_name,$stathmos_url" >>"$my_stations"
			echo " Προστέθηκε ο σταθμός $stathmos_name."
		else
			echo "Αριθμός εκτός λίστας"
		fi
	done
	exit 0

}

remove_station() {
	if [ ! -f "$HOME/.shelldio/my_stations.txt" ]; then
		echo "Δεν έχει δημιουργηθεί το αρχείο my_stations."
		echo "Για πληροφορίες τρέξε την παράμετρο --help."
	else
		echo "Εμφάνιση λίστας προσωπικών σταθμών"
		sleep 1
		list_stations "$my_stations"
		while true; do
			read -rp "Επέλεξε αριθμού σταθμού  (Q/q για έξοδο): " station_to_remove
			if [[ $station_to_remove = "q" ]] || [[ $station_to_remove = "Q" ]]; then
				echo "Έξοδος..."
				exit 0
			elif [ "$station_to_remove" -gt 0 ] && [ "$station_to_remove" -le "$num" ]; then #έλεγχος αν το input είναι μέσα στο εύρος της λίστας των σταθμών
				station=$(sed "${station_to_remove}q;d" "$my_stations")
				stathmos_name=$(echo "$station" | cut -d "," -f1)
				grep -v "$stathmos_name" "$HOME/.shelldio/my_stations.txt" >"$HOME/.shelldio/my_stations.tmp" && mv "$HOME/.shelldio/my_stations.tmp" "$HOME/.shelldio/my_stations.txt"
				echo "Διαγράφηκε ο σταθμός $stathmos_name."
			else
				echo "Αριθμός εκτός λίστας"
			fi
		done
	fi
}

install_msg() {
	local pkg="$1"

	if command -v apt &>/dev/null; then
		echo "Τρέξτε 'sudo apt install $pkg' για να το εγκαταστήσετε"
	elif command -v dnf &>/dev/null; then
		echo "Τρέξτε 'sudo dnf -y install $pkg' για να το εγκαταστήσετε"
	elif command -v zypper &>/dev/null; then
		echo "Τρέξτε 'sudo zypper in $pkg' για να το εγκαταστήσετε"
	elif command -v yum &>/dev/null; then
		echo "Τρέξτε 'sudo yum -y install $pkg' για να το εγκαταστήσετε"
	elif command -v pacman &>/dev/null; then
		echo "Τρέξτε 'sudo pacman -S $pkg' για να το εγκαταστήσετε"
	elif command -v brew &>/dev/null; then
		echo "Τρέξτε 'brew install $pkg' για να το εγκαταστήσετε"
	elif command -v pkg &>/dev/null; then
		echo "Τρέξτε 'sudo pkg install $pkg' για να το εγκαταστήσετε"
	else
		echo "Δεν μπορέσαμε να βρούμε ποιος package manager υπάρχει στο σύστημα."
		echo "Επισκεφτείτε τη σελίδα του πακέτου $pkg για οδηγίες."
		return 1
	fi
}

mpv_msg() { install_msg "mpv"; }
jq_msg() { install_msg "jq"; }
socat_msg() { install_msg "socat"; }

new_station() {
	if [ ! -f "$HOME/.shelldio/my_stations.txt" ]; then
		echo "Δεν έχει δημιουργηθεί το αρχείο my_stations."
		echo "Για πληροφορίες τρέξε την παράμετρο --help."
	else
		echo "Εμφάνιση λίστας προσωπικών σταθμών"
		sleep 1
		list_stations "$my_stations"
		while true; do
			read -rp "Δώσε όνομα νέου σταθμού (ή δώσε Q/q για έξοδο): " station_name
			if [[ $station_name = "q" ]] || [[ $station_name = "Q" ]]; then
				echo "Έξοδος..."
				exit 0
			fi
			read -rp "Δώσε url νέου σταθμού: " station_url
			echo "$station_name,$station_url" >>"$my_stations"
			echo " Προστέθηκε ο σταθμός $station_name."
		done
		exit 0
	fi
}

joker_info() {
	welcome_screen
	current_title=$(get_current_title)
	tput civis # Απόκρυψη cursor
	echo -ne "  Σταθμός: [$selected_play]    Η ώρα είναι $(date +"%T")\n"
	echo -ne " \n"
	echo -ne "  Ακούτε: $stathmos_name\n"
	echo -ne "\n"
    if [[ -n "$current_title" && "$current_title" != "radio" ]]; then
        echo -ne "  Τίτλος: $current_title\n"
        echo -ne "\n"
    fi
	echo -ne "   ____________               ___________\n"
	echo -ne "  [Έξοδος (Q/q)].___________.[Νέα τυχαία επιλογή  (N/n)]\n"
	echo -ne " "
}

joker() {
    local lines=0
    local stations="$all_stations"
    local station_number
    local input_play=""

    # Count total lines in stations file
    while IFS='' read -r line || [[ -n "$line" ]]; do
        lines=$((lines + 1))
    done <"$stations"

    validate_station_lists

    # Setup signal handling
    terms=0
    trap ' [ $terms = 1 ] || { terms=1; kill -TERM -$$; };  exit' EXIT INT HUP TERM QUIT

    # Ensure stations file exists
    if [ -d "$HOME/.shelldio/" ]; then
        if [ ! -f "$all_stations" ]; then
            echo "Δεν ήταν δυνατή η εύρεση του αρχείου σταθμών. Γίνεται η λήψη του..."
            sleep 2
            curl -sL https://raw.githubusercontent.com/CerebruxCode/shelldio/stable/.shelldio/all_stations.txt --output "$HOME/.shelldio/all_stations.txt"
        fi
    else
        echo "Δημιουργείται ο κρυφός φάκελος .shelldio ο οποίος θα περιέχει τα αρχεία των σταθμών."
        sleep 2
        mkdir -p "$HOME/.shelldio"
        echo "Γίνεται η λήψη του αρχείου με όλους τους σταθμούς."
        sleep 2
        curl -sL https://raw.githubusercontent.com/CerebruxCode/shelldio/stable/.shelldio/all_stations.txt --output "$HOME/.shelldio/all_stations.txt"
    fi

    while true; do
        # Pick random station
        station_number=$(( (RANDOM % lines) + 1 ))
        station=$(sed "${station_number}q;d" "$stations")
        selected_play=$station_number
        stathmos_name=$(echo "$station" | cut -d "," -f1)
        stathmos_url=$(echo "$station" | cut -d "," -f2)

        echo "Επιλέχθηκε τυχαία: $stathmos_name"
        
        if ! start_mpv; then
            echo "Δοκιμάζουμε άλλον σταθμό..."
            continue
        fi

        # Setup interrupt handler for this station
        trap '{ tput cnorm; echo; echo "Έξοδος..."; kill $mpv_pid 2>/dev/null; exit 1; }' SIGINT

        # Play this station
        while kill -0 "$mpv_pid" 2>/dev/null; do
            clear
            joker_info
            
            read -r -n1 -s -t 1 input_play
            case "$input_play" in
                [Qq])
                    tput cnorm
                    echo
                    echo "Έξοδος..."
                    kill $mpv_pid 2>/dev/null
                    exit 0
                    ;;
                [Nn])
                    kill $mpv_pid 2>/dev/null
                    wait $mpv_pid 2>/dev/null
                    echo "Επιλογή νέου τυχαίου σταθμού..."
                    sleep 1
                    break  # Break inner loop to pick new station
                    ;;
            esac
        done
    done
}

reset_favorites() {
	if [ ! -f "$my_stations" ]; then
		echo "Μη έγκυρη επιλογή. Το αρχείο αγαπημένων δεν υπάρχει."
		exit 1
	fi

	while true; do
		read -rp "Θελεις σίγουρα να διαγράψεις το αρχείο αγαπημένων; (y/n)" yn
		case $yn in
		[Yy]*)
			rm -f "$my_stations"
			break
			;;
		[Nn]*) exit ;;
		*) echo "Παρακαλώ απαντήστε με y (ναι) ή n (όχι)" ;;
		esac
	done

	if [ -f "$my_stations" ]; then
		echo "Απέτυχε η διαγραφή του αρχείου αγαπημένων"
		exit 1
	fi

	echo "Το αρχείο αγαπημένων διαγράφτηκε επιτυχώς"
	exit 0
}

git_updater() {
	if [[ -L "/usr/local/bin/shelldio" ]]; then
		printf "Το Shelldio έχει εγκατασταθεί σωστά μέσω git\n"
		RETURN_TO_PWD=$(pwd)
		basedir="$(dirname "$(readlink /usr/local/bin/shelldio)")"
		cd "$basedir" || return
		self_update
		cd "$RETURN_TO_PWD" || exit 0
	else
		echo "To Shelldio δεν έχει εγκατασταθεί μέσω git clone οπότε δεν είναι διαθέσιμη η ενημέρωση μέσω shelldio -u"
	fi
}

self_update() {
	if ! command -v git &>/dev/null; then
		return
	fi

	while true; do
		read -rp "Θέλεις να γίνει αναβάθμιση του shelldio; (y/n) : " update_confirm
		case $update_confirm in
		[Yy]*)
			printf "${BLUE}%s${RESET}\n" "Γίνεται αναβάθμιση του shelldio"
			if git pull --rebase --stat origin stable; then
				printf "${BLUE}%s${RESET}\n" "Ολοκληρώθηκε η αναβάθμιση του shelldio."
			else
				printf "${RED}%s${RESET}\n" 'Κάποιο πρόβλημα παρουσιάστηκε κατά την αναβάθμιση. Δοκίμασε ξανά αργότερα'
			fi
			exit 0
			;;
		[Nn]*) exit 0 ;;
		*) echo "Παρακαλώ απαντήστε με y (ναι) ή n (όχι)" ;;
		esac
	done
}

### Λίστα με τις επιλογές σαν 1ο όρισμα shelldio

while [ "$1" != "" ]; do
	case $1 in
	[1-9])
		clear
		break # Συνέχεια στο script για αναπαραγωγή
		;;
	-h | --help)
		option_detail
		exit 0
		;;
	-l | --list)
		welcome_screen
		while true; do
			if [ -f "$my_stations" ]; then
				read -rp "Θέλετε να εμφανισθούν όλοι οι σταθμοί ή οι αγαπημένοι σας σταθμοί; (a=Όλοι οι σταθμοί | f=Αγαπημένοι):" list_choice
				if [ "$list_choice" == "a" ]; then
					echo "Εμφάνιση όλων των σταθμών:"
					sleep 1
					list_stations "$all_stations"
					exit 0
				elif [ "$list_choice" == "f" ]; then
					echo "Εμφάνιση αγαπημένων σταθμών:"
					sleep 1
					list_stations "$my_stations"
					exit 0
				else
					echo "Λάθος επιλογή, θα πρέπει να γράψετε a ή f και να πατήσετε enter"
				fi
			else
				list_stations "$all_stations"
				exit 0
			fi
		done
		;;
	-a | --add)
		welcome_screen
		validate_station_lists
		add_stations
		# shellcheck disable=SC2317
		validate_station_lists
		# shellcheck disable=SC2317
		exit 0
		;;
	-n | --new-station)
		welcome_screen
		validate_station_lists
		new_station
		validate_station_lists
		exit 0
		;;
	-j | --joker)
		joker
		exit 0
		;;
	-r | --remove)
		welcome_screen
		remove_station
		exit 0
		;;
	--reset)
		reset_favorites
		# shellcheck disable=SC2317
		exit 0
		;;
	-f | --fresh)
		welcome_screen
		if [ ! -d "$HOME/.shelldio" ]; then
			mkdir "$HOME/.shelldio"
		fi
		echo "Γίνεται λήψη του αρχείου των σταθμών από το αποθετήριο."
		sleep 1
		if ! curl -sL https://raw.githubusercontent.com/CerebruxCode/shelldio/stable/.shelldio/all_stations.txt --output "$HOME/.shelldio/all_stations.txt"; then
			echo "Αποτυχία λήψης του αρχείου σταθμών. Ελέγξτε τη σύνδεσή σας στο διαδίκτυο."
			exit 1
		fi
		echo "Επιτυχής λήψη του αρχείου σταθμών."
		exit 0
		;;
	-u | --update)
		git_updater
		;;
	*)
		echo "Λάθος επιλογή."
		echo "Εκτέλεσε shelldio --help για να δεις τις δυνατές επιλογές!"
		exit 0
		;;
	esac
done

### Base script
# Έλεγχος προαπαιτούμενων binaries
missing_binaries=()
unknown_os_binaries=()
unknown_os_detected=0

for binary in mpv jq socat; do
	if ! command -v "$binary" &>/dev/null; then
		missing_binaries+=("$binary")
	fi
done

if (( ${#missing_binaries[@]} > 0 )); then
	echo "Έλεγχος προαπαιτούμενων για το Shelldio"
	echo "Λείπουν τα παρακάτω προαπαιτούμενα:"
	for bin in "${missing_binaries[@]}"; do
		echo " - $bin"
	done
	echo

	for bin in "${missing_binaries[@]}"; do
		case "$bin" in
			mpv)
				if ! mpv_msg; then
					unknown_os_binaries+=("mpv")
					unknown_os_detected=1
				fi
				;;
			jq)
				if ! jq_msg; then
					unknown_os_binaries+=("jq")
					unknown_os_detected=1
				fi
				;;
			socat)
				if ! socat_msg; then
					unknown_os_binaries+=("socat")
					unknown_os_detected=1
				fi
				;;
		esac
	done

	if (( unknown_os_detected == 1 )); then
		echo "Δεν μπορέσαμε να εντοπίσουμε το λειτουργικό σας σύστημα."
	fi

	echo "Παρακαλούμε εγκαταστήστε τα παραπάνω πριν τρέξετε ξανά το Shelldio."
	exit 1
fi

# Έλεγχος εγκυρότητας λίστας σταθμών
validate_station_lists

while true; do
	terms=0
	trap ' [ $terms = 1 ] || { terms=1; kill -TERM -$$; };  exit' EXIT INT HUP TERM QUIT

	if [ -d "$HOME/.shelldio/" ]; then
		if [ -f "$my_stations" ]; then
			if [ -s "$my_stations" ]; then
				stations="$my_stations"
			else
				stations="$all_stations"
			fi
		else
			if [ ! -f "$all_stations" ]; then
				echo "Δεν ήταν δυνατή η εύρεση του αρχείου σταθμών. Γίνεται η λήψη του..."
				sleep 2
				curl -sL https://raw.githubusercontent.com/CerebruxCode/shelldio/stable/.shelldio/all_stations.txt --output "$HOME/.shelldio/all_stations.txt"
			fi
			stations="$all_stations"
		fi
	else
		echo "Δημιουργείται ο κρυφός φάκελος .shelldio ο οποίος θα περιέχει τα αρχεία των σταθμών."
		sleep 2
		mkdir -p "$HOME/.shelldio"
		echo "Γίνεται η λήψη του αρχείου με όλους τους σταθμούς."
		sleep 2
		curl -sL https://raw.githubusercontent.com/CerebruxCode/shelldio/stable/.shelldio/all_stations.txt --output "$HOME/.shelldio/all_stations.txt"
		stations="$all_stations"
	fi

	while true; do
		welcome_screen

		num=0
		list_stations "$stations"

		if [ "$#" -eq "0" ]; then # στην περίπτωση που δε δοθεί όρισμα εμφάνισε τη λίστα σταθμών
			if [ ! -f "$my_stations" ]; then
				echo "Από προεπιλογή η λίστα σταθμών περιέχει όλους τους σταθμούς."
				echo "Μπορείς να δημιουργήσεις ένα αρχείο με τους αγαπημένους σου σταθμούς."
				echo "shelldio --help για να δεις πως μπορείς να το κάνεις!"
			elif [ ! -s "$my_stations" ]; then
				echo "Το αρχείο my_stations.txt υπάρχει αλλά είναι κενό."
				echo "Θα φορτώσει η λίστα με όλους τους σταθμούς."
				echo "Αν θέλεις να προσθέσεις αγαπημένους σταθμούς δοκίμασε την επιλογή add"
				echo "shelldio --add"
			fi
			echo "--------------------------------------------"
			read -rp "Διαλέξτε Σταθμό (ή Q/q για έξοδο): " input_play
		else
			input_play="$1"
			shift # αφαιρούμε το cli argument ώστε να μπορεί ζητήσει από STDIN αν δωθεί 'r' στη συνέχεια (reload)
		fi

		if [[ $input_play = "q" ]] || [[ $input_play = "Q" ]]; then
			echo "Έξοδος..."
			tput cnorm # Εμφάνιση cursor
			exit 0
		elif [ "$input_play" -gt 0 ] && [ "$input_play" -le $num ]; then #έλεγχος αν το input είναι μέσα στο εύρος της λίστας των σταθμών
			station=$(sed "${input_play}q;d" "$stations")
			selected_play=$input_play # για να εμφανίζει το αριθμό που επέλεξε ο χρήστης στον Player UI
			stathmos_name=$(echo "$station" | cut -d "," -f1)
			stathmos_url=$(echo "$station" | cut -d "," -f2)
			break
		else
			echo "Αριθμός εκτός λίστας"
			sleep 1
			clear
		fi
	done

	start_mpv

	while true; do
		trap '{ clear; echo  "Έξοδος..."; tput cnorm; kill $mpv_pid 2>/dev/null; exit 1; }' SIGINT
		clear
		
		if info; then
			# info() returned 0, go back to menu
			if [[ -n "$mpv_pid" ]]; then
				fade_out
				kill "$mpv_pid" 2>/dev/null
				wait "$mpv_pid" 2>/dev/null
			fi
			clear
			echo "Επιστροφή στη λίστα σταθμών"
			tput cnorm # Εμφάνιση cursor
			sleep 1
			clear
			break
		else
			# info() returned 1, quit application
			clear
			echo "Έξοδος..."
			tput cnorm # Εμφάνιση cursor
			if [[ -n "$mpv_pid" ]]; then
				kill "$mpv_pid" 2>/dev/null
			fi
			exit 0
		fi
	done

done
