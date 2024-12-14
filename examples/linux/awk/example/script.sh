#!/bin/bash

#service.txt
#
#gozeus,dev,sl,10001,http://sl.com


# Check if the input file exists
if [ ! -f "service.txt" ]; then
    echo "Error: service.txt does not exist."
    exit 1
fi

# Check if the input $1 is valid
MS=("ravi" "arthi" "suresh" "sathya")
# shellcheck disable=SC2199
# shellcheck disable=SC2076
if [[ ! " ${MS[@]} " =~ " $1 " ]]; then
    echo "Error: $1 is not a valid input."
    echo "Valid inputs for \$1 are: ${MS[*]}"
    exit 1
fi

# Check if the input $2 is valid
MS_ENV=("dev" "int" "stguk" "stgus" "produk" "produs")
# shellcheck disable=SC2199
# shellcheck disable=SC2076
if [[ ! " ${MS_ENV[@]} " =~ " $2 " ]]; then
    echo "Error: $2 is not a valid input."
    echo "Valid inputs for \$2 are: ${MS_ENV[*]}"
    exit 1
fi

# Check if the input $3 is valid based on $2
if [[ "$2" == "dev" || "$2" == "int" ]]; then
    MS_DC=("sl" "gl" "cn" "pi")
elif [[ "$2" == "stguk" || "$2" == "produk" ]]; then
    MS_DC=("sl" "gl")
elif [[ "$2" == "stgus" || "$2" == "produs" ]]; then
    MS_DC=("cn" "pi")
else
    echo "Error: Invalid combination of \$2 ($2) and \$3 ($3)."
    exit 1
fi

# shellcheck disable=SC2199
# shellcheck disable=SC2076
if [[ ! " ${MS_DC[@]} " =~ " $3 " ]]; then
    echo "Error: $3 is not a valid input for \$2 ($2)."
    echo "Valid inputs for \$3 when \$2 is $2 are: ${MS_DC[*]}"
    exit 1
fi

# Check if exactly 3 parameters are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 SERVICE ENV DC"
    exit 1
fi

# Assign parameters to variables
SERVICE="$1"
ENV="$2"
DC="$3"

# Read the file line by line and process each line
while IFS=, read -r file_col1 file_col2 file_col3 file_col4 file_col5; do
    if [[ "$file_col1" == "$SERVICE" && "$file_col2" == "$ENV" && "$file_col3" == "$DC" ]]; then
        OCID="$file_col4"
        OCAPI="$file_col5"
        break  # Exit the loop after the first matching line
    fi
done < "service.txt"

# Print the local variables
echo "OC ID : $OCID"
echo "OC API Url : $OCAPI"
