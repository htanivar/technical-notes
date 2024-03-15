#!/bin/bash

# Default values
input_param=""
flag=false

# Function to display usage
usage() {
    echo "Usage: $0 [-f] -i <input>"
    echo "Options:"
    echo "  -f      Flag to enable special mode"
    echo "  -i      Input parameter (required)"
    exit 1
}

# Parse command-line options
while getopts ":fi:" opt; do
    case $opt in
        f)
            flag=true
            ;;
        i)
            input_param="$OPTARG"
            ;;
        :)
            echo "Error: Option -$OPTARG requires an argument."
            usage
            ;;
        ?)
            echo "Error: Invalid option -$OPTARG."
            usage
            ;;
    esac
done

# Check if input parameter is provided
if [ -z "$input_param" ]; then
    echo "Error: Input parameter is required."
    usage
fi

# Display input parameter and flag status
echo "Input parameter: $input_param"
echo "Flag status: $flag"
