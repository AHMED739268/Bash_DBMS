#!/bin/bash
#global path to database directory
DB_DIR="$(pwd)/Databases"
SELECTED_DB=""
SELECTED_TABLE=""
COLUMNS=""

DATABASES_ARR=($(ls -l "$DB_DIR" | grep '^d' | awk '{print $NF}'))

# Color variables

#LIKE THIS: echo -e "${red}Hello World${clear}"  IT CALLED ANSI ESCAPE CODES

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;93m'
blue='\033[0;94m'


# Clear the color after that
clear='\033[0m'


