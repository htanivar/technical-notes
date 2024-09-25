#!/bin/bash

# Source the validation functions
source /home/ravi/code/technical-notes/examples/linux/bash_scripts/functions/validate.sh

# Example usage of the functions
var1=""
var2="Hello"
unset var3
var4=ravi
var5=4

echo "var1: $var1" #Declared but empty
echo "var1: $var2" #Declared & assigned
echo "var1: $var3" #unset

echo "***Checking var1:with must_be_empty & must_be_null***"
must_be_empty "$var1"
must_be_null "var1"

echo "***Checking var2:with must_be_empty & must_be_null***"
must_be_empty "$var2"
must_be_null "var2"

echo "***Checking var3: with must_be_empty & must_be_null***"
must_be_empty "$var3"
must_be_null "var3"

echo "***Checking var4: with must_be_number***"
must_be_number "$var4"

echo "***Checking var5: with is_number***"
is_number "$var5"

