#!/bin/bash

for arg in "$@"; do

    if [[ "$arg" == "run" ]]; then
        
        ./nsa

    elif [[ "$arg" == "clean" ]]; then
    
        rm nsa

    elif [[ "$arg" == "build" ]]; then
    
        odin build .
    
    fi

done
