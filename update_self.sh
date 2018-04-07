#! /bin/bash

CARTFILE=""

save_origin_cartfile() {
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
    save_origin_cartfile
    update_self_frameworks
    update_origin_frameworks
}

main $@