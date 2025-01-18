#!/bin/bash
source ./global


# Function: Validate empty input
is_empty_input() {
    if [ -z "$1" ]; then
        echo -e "${yellow}Warning: Input cannot be empty.${clear}"
        return 0
    else
        return 1
    fi
}

# Function: Check if directory already exists
is_already_exists_dir() {
    if [ -d "$1" ]; then
        echo -e "${yellow}Warning: Database already exists.${clear}"
        return 0
    else
        return 1
    fi
}

# Function: Check if file already exists
is_already_exists_file() {
    if [ -f "$1" ]; then
        echo -e "${yellow}Warning: Table already exists.${clear}"
        return 0
    else
        return 1
    fi
}

# Function: Validate name
is_valid_name() {
    if [[ $1 =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        return 0  # True: Valid name
    else
        echo -e "${yellow}Warning: Invalid name '$1'. Name must start with a letter or underscore and contain only letters, numbers, and underscores.${clear}"
        return 1  # False: Invalid name 
    fi
}


# Function: Validate column datatype
is_invalid_datatype() {
    declare -a arr=("int" "string")
    if [[ ! " ${arr[*]} " =~ " $1 " ]]; then
        echo -e "${yellow}Warning: Invalid datatype '$1'. Valid types are: ${arr[*]}.${clear}"
        return 0
    else
        return 1
    fi
}

# Function: Validate unique column name
is_duplicate_column() {
    if grep -q "^$1:" "$2"; then
        echo -e "${yellow}Warning: Column name '$1' already exists in $2.${clear}"
        return 0
    else
        return 1
    fi
}

# Function: Validate if value is greater than zero
is_less_than_zero() {
    if [[ "$1" -le 0 ]]; then
        echo -e "${yellow}Warning: Value must be greater than zero.${clear}"
        return 0
    else
        return 1
    fi
}


is_int () {
    if [[ $1 =~ ^[0-9]+$ ]]; then
        return 0
    else
        echo -e "${yellow}Warning: Value must be an integer.${clear}"
        return 1
    fi
}

is_string () {
    if [[ $1 =~ ^.+$ ]]; then
        return 0
    else
        echo -e "${yellow}Warning: Value must be a string.${clear}"
        return 1
    fi
}

function is_valid_table () {
    # Check if the table and its metadata exist
    if [ -e "$DB_DIR/$SELECTED_DB/$SELECTED_TABLE" ] && [ -e "$DB_DIR/$SELECTED_DB/$SELECTED_TABLE.metadata" ]; then
        # Check if columns are available
        if [ ${#COLUMNS[@]} -eq 0 ]; then
            sleep 0.5
            echo -e "${yellow}No columns found in metadata file for table '$table_name'.${clear}"
            sleep 0.5
            return -1
        else
            return 0
        fi
    else
        echo -e "${yellow}Warning: Table [ $SELECTED_TABLE ] does not exist or corrupted.${clear}"
        return -1
    fi
}

function is_array_empty() {
    array_name=("$@")  
    if [[ ${#array_name[@]} -eq 0 ]]; then
        return 0  # Return (0)(true) if the array is empty
    fi
    return 1  # Return (1)(false) if the array is not empty
}

is_already_exists_db_dir() {
    if [ -d "$1" ]; then
        return 0
    else
        return 1
    fi
}