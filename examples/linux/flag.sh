#!/bin/bash

# Default values
flag=false
optional_param="default_value"

# Function to display usage
usage() {
    echo "Usage: $0 [-f] [-o <optional_param>] -i <input>"
    echo "Options:"
    echo "  -f              Flag to enable special mode"
    echo "  -o <value>      Optional parameter (default: default_value)"
    echo "  -i <input>      Input parameter (required)"
    exit 1
}

# Parse command-line options
while getopts ":fo:i:" opt; do
    case $opt in
        f)
            flag=true
            ;;
        o)
            optional_param="$OPTARG"
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

# Display input parameter, optional parameter, and flag status
echo "Input parameter: $input_param"
echo "Optional parameter: $optional_param"
echo "Flag status: $flag"
