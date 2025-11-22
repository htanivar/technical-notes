#!/bin/bash

# A simple script to connect to various servers using aliases.

if [ -z "$1" ]; then
    echo "Usage: ssh <alias>"
    echo
    echo "Available aliases:"
    echo "  pi        (ravi@ravi-pi)"
    echo "  prod      (ravi@ravinath-prod)"
    echo "  prod-adm  (ravi_adm@ravinath-prod)"
    exit 1
fi

case "$1" in
    pi)
        ssh ravi@ravi-pi
        ;;
    prod)
        ssh ravi@ravinath-prod
        ;;
    prod-adm)
        ssh ravi_adm@ravinath-prod
        ;;
    *)
        echo "Error: Unknown alias \"$1\""
        echo
        echo "Available aliases:"
        echo "  pi        (ravi@ravi-pi)"
        echo "  prod      (ravi@ravinath-prod)"
        echo "  prod-adm  (ravi_adm@ravinath-prod)"
        exit 1
        ;;
esac