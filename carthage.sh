#! /bin/bash

FRAMEWORKS=()

parse_argu() {
    FRAMEWORKS=($@)
}

check_framework_need() {
    for f in ${FRAMEWORKS[@]}
    do
        if [ "$f" == "$1" ]
        then
            return 1
        fi
    done
    return 0
}

delete_not_dependencies() {
    for d in `ls -1`
    do
        if check_framework_need $d
        then
            rm -rf $d
        fi
    done
}

carthage_build() {
    carthage checkout
    pushd "./Carthage/Checkouts/HIComponents"
    delete_not_dependencies
    popd
    carthage build
}

main() {
    parse_argu $@
    carthage_build
}

main $@