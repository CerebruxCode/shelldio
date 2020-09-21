# Shelldio
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-1-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

Ένα απλό shell script για να παίζετε τους αγαπημένους σας ραδιοφωνικούς σταθμούς στο τερματικό. 

## Οδηγίες εγκατάστασης

Το Shelldio είναι συμβατό με Linux, BSD και macOS. Απαιτείται το πακέτο ```mpv``` για να δουλέψει. Μπορείτε να το εγκαταστήσετε από το αποθετήριο λογισμικών του λειτουργικού σας.

### Arch Linux

Για να το κάνετε εγκατάσταση σε Arch Linux αρκεί να έχετε ενεργό το **AUR** οπότε, με έναν AUR helper κάντε εγκατάσταση το  **shelldio** 

```bash
yay -S shelldio
```

το οποίο θα κάνει αυτόματα εγκατάσταση και το `mpv` που χρειάζεστε. Τώρα μπορείτε να πάτε παρακάτω στις οδηγίες χρήσης.

### Στα υπόλοιπα λειτουργικά συστήματα

Για να το εγκαταστήσετε στα υπόλοιπα λειτουργικά συστήματα πρώτα κάνετε εγκατάσταση το **MPV**

#### Σε Debian based διανομές

```bash
sudo apt install -y mpv
```

#### Σε Fedora based διανομές

```bash
sudo dnf -y install mpv
```

#### Σε OpenSuse Linux

```bash
sudo zypper in mpv
```

#### Σε CentOS Linux (από το nux-desktop repository)

```bash
sudo yum -y install mpv
```

#### Σε FreeBSD Unix

```bash
sudo pkg install mpv
```

#### Σε macOS (μέσω [Brew](https://docs.brew.sh/Installation))

```bash
brew install mpv
```

Τέλος αφού έχετε κάνει εγκατάσταση το **MPV** τρέχετε μια μια τις παρακάτω εντολές για να εγκαταστήσετε το Shelldio:

```bash
git clone https://github.com/CerebruxCode/shelldio ~/shelldio
sudo ln -s ~/shelldio/shelldio.sh /usr/local/bin/shelldio
```

## Οδηγίες Αναβάθμισης

Για να κατεβάσετε νέους σταθμούς που μπορεί κατά καιρούς να προσθέτουμε, τρέξτε στο τερματικό :
```bash
shelldio --fresh
```
Για να κατεβάσετε νέες εκδόσεις του **shelldio** που περιλαμβάνουν διορθώσεις και νέα χαρακτηριστικά τότε διαβάστε παρακάτω (ανάλογα με την διανομή σας).

### Arch Linux

Οι ενημερώσεις θα σας έρθουν αυτόματα την επόμενη φορά που θα κάνετε αναβάθμιση το Arch Linux σας και συγκεκριμένα στα πακέτα που προέρχονται απο το AUR.

### Υπόλοιπες διανομές

Μπείτε στον φάκελο shelldio που κάνατε clone και τρέξετε pull. π.χ. 
```bash
cd ~/shelldio
git pull
```
## Οδηγίες Απεγκατάστασης

Ανάλογα του τρόπου εγκατάστασης μπορείτε να απεγκαταστήσετε το Shelldio με τους παρακάτω τρόπους

### Arch Linux

Μπορείτε να το απεγκαταστήσετε με τον AUR helper σας π.χ.:
```bash
yay -Rcsu shelldio
```
### Υπόλοιπες διανομές

Τρέξτε τις παρακάτω εντολές :
```bash
sudo unlink /usr/bin/shelldio
```

Τέλος μπορείτε να διαγράψετε και τον φάκελο που κατέβηκε με `git clone`
```bash
rm -rf ~/shelldio
```

### macOS

```bash
sudo unlink /usr/local/bin/shelldio
```

Τέλος μπορείτε να διαγράψετε και τον φάκελο που κατέβηκε με `git clone`
```bash
rm -rf ~/shelldio
```

## Οδηγίες χρήσης

Εξ'ορισμού το script αν δε δοθεί όρισμα στο τερματικό ανοίγει τη λίστα με τους αγαπημένους σας σταθμούς (εφόσον υπάρχουν στο ```~/.shelldio/my_stations.txt```). 

Η κλασσική χρήση του γίνεται στο τερματικό με την εντολή:

`shelldio`

Αν θέλουμε να ξεκινήσουμε το shelldio με όρισμα τότε αυτό μπορεί να είναι ένα απο τα παρακάτω:

Χρήση: `shelldio [όρισμα]`
Όπου `[όρισμα]` :
```
	-a, --add : Δημιουργεί το αρχείο ~/.shelldio/my_stations.txt
				στο οποίο μεταφέρει τους αγαπημένους σας σταθμούς
	-f, --fresh : Κατεβάζει εκ νέου την λίστα των σταθμών 
				 με επικαιροποιημένους ραδιοφωνικούς σταθμούς
	-h, --help: Εμφανίζει πληροφορίες για την χρήση της εφαρμογής
	-l, --list: Εμφανίζει την λίστα με τους ραδιοφωνικούς σταθμούς.
	-r, --remove: Διαγράφει σταθμούς της επιλογής σας από το my_stations.txt
```

Παράδειγμα:
```bash
shelldio
```
Θα φορτώσει τους αγαπημένους σας σταθμους. Αλλιώς μπορείτε να φορτώσετε το μεγάλο αρχείο με πάνω απο 100+ σταθμούς με την παρακάτω εντολή:

```bash
shelldio --list
```
Στην ερώτηση που θα σας κάνει επιλέγετε `f` για να σας εμφανίσει όλη την λίστα.

### Αναζήτηση με όνομα

Μπορείτε επίσης να κάνετε αναζήτηση για κάποιον σταθμό χρησιμοποιώντας την παρακάτω εντολή:
```bash
shelldio ~/.shelldio/all_stations.txt | grep -i "onoma_stathmou"
```
θα σας εμφανίσει τον αριθμό. Πατάτε `Q` για να σταματήσετε την αναζήτηση και έπειτα τρέχετε ```shelldio --add``` και βάζετε τον αριθμό του σταθμού που αναζητήσατε. Με αυτόν τον τρόπο μπορείτε να μαζέψετε π.χ. τους αγαπημένους σας σταθμούς και την επόμενη φορά που θα ξεκινήσετε το **shelldio** θα τα δείτε στην λίστα των αγαπημένων σας σταθμών.

## Πως βάζω νέους σταθμούς;

Αν γνωρίζετε το λινκ του σταθμού που θέλετε να βάλετε, παρακαλούμε ενημερώστε μας να το προσθέσουμε στο **shelldio** ανοίγοντας ένα [issue](https://github.com/CerebruxCode/shelldio/issues/new)

Αφού το προσθέσουμε μπορείτε να κατεβάσετε τους νέους σταθμούς, με την εντολή:
```bash
shelldio --fresh
```
Συνήθως, οι νέες προσθήκες θα μπαίνουν στο τέλος για να τις βρίσκετε άμεσα. Αν δεν εμφανίζονται μπορείτε να κάνετε αναζήτηση με όνομα όπως περιγράψαμε πιο πάνω.

Αν έχετε δικούς σας σταθμούς ή φίλων σας και είναι internetικά ραδιόφωνα, θα χαρούμε πολύ να τα προσθέσουμε στο **shelldio** ανοίγοντας μας ένα [issue](https://github.com/CerebruxCode/shelldio/issues/new)

## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://wiki.ubuntu.com/SalihEmin"><img src="https://avatars1.githubusercontent.com/u/914656?v=4" width="100px;" alt=""/><br /><sub><b>Salih Emin</b></sub></a><br /><a href="#projectManagement-cerebrux" title="Project Management">📆</a> <a href="https://github.com/CerebruxCode/shelldio/commits?author=cerebrux" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/JohnGavr"><img src="https://avatars0.githubusercontent.com/u/47471932?v=4" width="100px;" alt=""/><br /><sub><b>JohnGavr</b></sub></a><br /><a href="https://github.com/CerebruxCode/shelldio/commits?author=JohnGavr" title="Code">💻</a></td>
  </tr>
</table>

<!-- markdownlint-enable -->
<!-- prettier-ignore-end -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!