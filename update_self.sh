#! /bin/bash

CARTFILE=""

check_save_origin_cartfile() {
    if [ ! -f "./Cartfile" ]
    then
        exit
    fi
    CARTFILE=`cat ./Cartfile`
}

update_self_frameworks() {
    while read line || [ -n "$line" ]
    do
        echo $line > Cartfile
        carthage update
    done < ./Cartfile.self
}

update_origin_frameworks() {
    echo $CARTFILE > Cartfile
    carthage update
}

main() {
    check_save_origin_cartfile
    update_self_frameworks
    update_origin_frameworks
}

main $@