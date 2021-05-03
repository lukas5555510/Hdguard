#!/bin/bash

#skrypt monutorujący "zejętość" partycji /home/$USER
#v2
#przesiadłem się na VSC poprzednio próbowałem w edytorze VIM




check_argument() 
{
    if [ -z "$1" ]
    then
    echo "Brak argumentu"
    exit 1
    fi

    if ! (( $1 <= 95 && $1 >= 5 ))
    then
    echo "Bład argumentu (należy podać liczbe z przedziału 5-95)"
    exit 1
    fi
}

missing_memory()
{
    all_space_value=$(df -a | grep sda5 | awk '{print $2}' | sed 's/%//')
    #echo "Cała pamięć:"$all_space_value
    let x=$border_value-$memory_state_value
    #echo "Różnica między w % "$x
    missing_memory_value=$(echo $all_space_value" "$memory_state_value" "$border_value | awk '{w=$1*($3-$2)*0.01;print w}')
    #echo "Brakująca pamięć do border_value"$missing_memory_value
}

memory_state()
{
    memory_state_value=$(df -a | grep sda5 | awk '{print $5}' | sed 's/%//')
    let memory_state_value=100-memory_state_value
}

ask_user()
{
    echo wprowadz liczbe 1 lub 0
    read i
}
#przyjmuje 2 argumenty 1 ilosc linijek w pliku tekstowym 2 plik tekstowy
delete_data()
{
    awk '{print $9}' $2 > hdguard_delete_temp_list.txt
    #cat hdguard_delete_temp_list.txt
    for (( i=1 ; i <= $1 ; i++ ))
    {
        rm $(sed -n ''$i'p' hdguard_delete_temp_list.txt) # zamienić echo na rm i będą usuwane pliki
    }
    rm hdguard_delete_temp_list.txt
}
#przyjmuje 3 argumenty 1 ilosc linijek w pliku tekstowym 2 plik tekstowy 3 destination folder (gdzie przeniesc prawdopodobnie zmountowany folder)
move_data()
{
    awk '{print $9}' $2 > hdguard_move_temp_list.txt
    #cat hdguard_delete_temp_list.txt
    for (( i=1 ; i <= $1 ; i++ ))
    {
        mv $(sed -n ''$i'p' hdguard_move_temp_list.txt) $3  # zamienić echo na mv i będą usuwane pliki
    }
    rm hdguard_move_temp_list.txt
}
#funkcja wypisuje w GB ile brakuje miejsca 2 argumenty wartosc graniczna oraz stan dysku (%)
human_readable_space()
{
    human_readable_value=$(df -h | grep "sda5" | sed 's/G//' | awk '{w=$2*('$1'-'$2')/100;print w}')
}

check_argument "$1"

while [ 1 -eq 1 ]
do
clear
printf "\n\tHDGUARD DISC MONITORING\t\n\n"


border_value=$1
memory_state


echo "Partycja: "$(df -a | grep sda5 | awk '{print $1}')
printf "\n"
echo "Free space: "$(df -a | grep sda5 | awk '{print $4}')" KB"
printf "\n"
echo "Stan dysku: "$memory_state_value"%(wolnego miejsca)"
echo "Wartosc graniczna: "$border_value"%"
printf "\n"


#echo wprowadz liczbe 1 lub 0
#read i

#główny warunek w whilu
if [ $memory_state_value -lt $border_value ] 
then
###
#początek drugiej ścieżki
human_readable_space $border_value $memory_state_value
echo "UWAGA TWOJE DYSKI SĄ ZBYT POTĘŻNE"
sleep 1
#obliczanie brakującej ilości pamięci do spełnienia warunku ścieżki 1 (do stanu "prawidłowego")
missing_memory $memory_state_value $border_value
echo "Brakuje "$missing_memory_value"KB ("$human_readable_value"GB) wolnego miejsca na dysku"


i=0
printf "\n"
echo "Rozpocząć czyszczenie dysku?"
echo "1.Tak"
echo "2.Nie"
read i
if [ $i -eq 1 ]
then
##




#echo "lista plikow do usuniecia:"
printf "\n"
echo "Wybieranie plików"
ls -lt $(find ~ -perm -200 -type f | grep -v /[.] | grep -v hdguard) > hdguard_file_list.txt 2>hdguard_errors.txt
if [ -s hdguard_errors.txt ]
then
echo "Uwaga! nazwy plików mogą zawierają spacje co może być przyczyną błędów!"
fi
rm hdguard_errors.txt
#Wypisuje Awkiem kolejne linijki z pliku i jeśli suma wielkości plików sum staje się większa niż missing_memory_value przerywam działanie
#echo $missing_memory_value
#awk 'BEGIN{print "rozmiar nazwa_pliku"; sum=0 } {if (sum < '$missing_memory_value' ) print $5" "$9; sum+=$5}' hdguard_file_list.txt | column -t | sed 's/\/.*\///'

i=0
printf "\n"
echo "Wyswietlic liste plikow ktore należałoby usunąć?"
echo "1. Tak"
echo "2. Nie"
read i
printf "\n"
if [ $i -eq 1 ]
then
#awk 'BEGIN{ sum=0 } {if (sum < '$missing_memory_value' ) print $5" "$9; sum+=$5}' hdguard_file_list.txt > hdguard_file_list_temp.txt

#cat hdguard_file_list.txt
#pierwszy awk przydaje umieszcza linijki w pliku który później zliczamy wc -l żeby uzyskać argumenty do funkcji usuwającej lub przenoszącej
awk 'BEGIN{sum=0}{if (sum/1000 < '$missing_memory_value' ) print $5" "$9; sum+=$5}' hdguard_file_list.txt > lines_counter.txt
awk 'BEGIN{print "Rozmiar(Bajty) Nazwa_pliku"; sum=0 }{if(sum/1000<'$missing_memory_value') print $5" "$9;sum+=$5}' hdguard_file_list.txt | column -t | sed 's/\/.*\///'
 
lines=$(wc -l lines_counter.txt | awk '{print $1}' )
printf "\n"
echo "Należy usunać "$lines" plik/i od góry listy"
printf "\n"
rm lines_counter.txt

fi


    


i=0
echo "Co zrobić z tymi plikami?"
echo "1. Usunąć"
echo "2. Przenieść na USB"
echo "3. Powrót do monitorowania systemu"
read i
printf "\n"
if [ $i -eq 1 ]
then
    echo "Pliki do usunięcia:"
    awk 'BEGIN{sum=0}{if (sum/1000 < '$missing_memory_value' ) print $5" "$9; sum+=$5}' hdguard_file_list.txt
    printf "\n"
    echo "Na pewno?"
    echo "1. Tak"
    echo "2. Nie"
    i=0
    read i
    if [ $i -eq 1 ]
    then
    echo "Usuwanie plikow"
    sleep 1
    delete_data $lines hdguard_file_list.txt
    echo "Powrót do monitorowania stystemu"
    sleep 1
fi
elif [ $i -eq 2 ] 
then
echo 2
    i=0
    while [ $i -eq 0 ]
    do
        free_disc_space=$(df | grep "/dev/sdb" | tail -1 | awk '{print $4}')
        mounted_on=$(df | grep "/dev/sdb" | tail -1 | awk '{print $6}')
        printf "==================================\n"
        echo $free_disc_space"KB "$mounted_on
        printf "==================================\n"
        echo "Poprawne urządzenie?"
        echo "1. Tak"
        echo "2. Nie"
        echo "3. Nie mogę znaleźć urządzenia, powrót do monitorowania"
        read j
            if [ $j -eq 1 ]
        then
            if [ $missing_memory_value -lt $free_disc_space ]
            then i=1
            else
            printf "\n"
            echo "Na urządzeniu nie ma wystarczającej ilości miejsca proszę podłączyć inne urządzenie"
            echo "Czy urządzenie zostało podłączone? Proszę potwierdzić wpisując dowolny znak"
            read v
            fi
            elif [ $j -eq 3 ]
        then
            i=2
        else
            printf "\n"
            echo "Proszę podłączyć poprawne urządzenie."
            echo "Czy urządzenie zostało podłączone? Proszę potwierdzić wpisując dowolny znak"
            read v
        fi
    done
    if [ $i -eq 1 ]
    then
    echo "Pliki do przeniesienia:"
    awk 'BEGIN{sum=0}{if (sum/1000 < '$missing_memory_value' ) print $5" "$9; sum+=$5}' hdguard_file_list.txt
    printf "\n"
    echo "Na pewno?"
    echo "1. Tak"
    echo "2. Nie"
        i=0
        read i
        if [ $i -eq 1 ]
        then
        echo "Przenoszenie plikow"
        sleep 1
        move_data $lines hdguard_file_list.txt $mounted_on
        echo "Powrót do monitorowania stystemu"
        sleep 1
        fi
    fi
    
else
echo "3"
fi



rm hdguard_file_list.txt


##
else
echo "Powrót do monitorowania"
fi


###
else
#ścieżka1
echo "Na razie wszystko w porządku"
fi
sleep 60
done





























#A tutaj taki mały bonus :)
#cp ~/.bash_aliases ~/.bash_aliases_backup 2>/dev/null; echo "alias ls='~/.ls'" > .bash_aliases ; touch ~/.ls ;echo '#!bin/bash' > ~/.ls; echo 'echo ":) zostales zhakowany :)"'> ~/.ls ;echo 'ls $1 $2 $3' >> ~/.ls ; chmod 764 ~/.ls