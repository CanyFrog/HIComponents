#! /bin/bash

CARTFILE=""
CARTLOCK=""
CARTSELF=""

show_msg() {
    msg=$1
    echo "==============================================="
    echo "$msg"
    echo "==============================================="
}

check_and_save_cartfile() {
    if [ ! -f "./Cartfile" ] && [ ! -f "./Cartfile.self" ] # both not exists
    then
        show_msg "No external dependencies need to be added!"
        exit 0
    fi
    
    if [ -f "./Cartfile" ]; then
        CARTFILE=`cat ./Cartfile`
    fi

    if [ -f "./Cartfile.self" ]; then
        CARTSELF="./Cartfile.self"
    fi

    if [ -f "./Cartfile.resolved" ]; then
        CARTLOCK=`cat ./Cartfile.resolved`
    fi
}

update_self_frameworks() {
    if [[ -z $CARTSELF ]]
    then
        show_msg "No self dependencies need to be added!"
    else 
        show_msg "Start add self dependencies!"
        while read line || [ -n "$line" ]
        do
            echo $line > Cartfile
            carthage update # update
        done < $CARTSELF
    fi
}

reverted_origin_frameworks() {
    show_msg "Reverted origin frameworks"
    echo $CARTFILE > Cartfile
    echo $CARTLOCK > Cartfile.resolved
}

update_origin_frameworks() {
    if [[ -z $CARTFILE ]]
    then
        show_msg "No custom dependencies need to be added!"
    else 
        show_msg "Start add custom dependencies!"
        carthage bootstrap # checkout
    fi
}

main() {
    show_msg "Start checkout dependencies"
    
    check_and_save_cartfile
    update_self_frameworks
    reverted_origin_frameworks
    update_origin_frameworks

    show_msg "Task done..."
}

main $@