#! /bin/bash
source ./global
source ./valid
source ./table

# create database

flag=1

function create_database() {
    echo -e "***Enter the name of the database you want to create: ${clear}"
    read dbName
   
    if ! is_empty_input "$dbName" && ! is_already_exists_dir "$DB_DIR/$dbName" &&  is_valid_name "$dbName"; then
        sleep 0.5
        echo -e "Database name [ $dbName ] is valid to create.${clear}"
        flag=1
    else
        flag=0
        create_database
    fi

    if [ "$flag" -eq 1 ]; then
        if mkdir "$DB_DIR/$dbName"; then
            echo -e "###############DATABASE [ $dbName ] CREATED SUCCESSFULLY###############"
            DATABASES_ARR+=("$dbName")
        else
            echo -e    ${red}"Could not create database [ $dbName ]."
        fi
    fi
    navigate_menu
}

#list database 
function list_database() {
    
   
    if [ ${#DATABASES_ARR[@]} -eq 0 ]; then
        #echo  -e it will print the message in the new line and escape sequence \n is not needed and -e is used to enable the interpretation of backslash escapes
        echo -e "############### No Databases Found! ############### ${clear}"
        navigate_menu
    else
        echo -e "############### Databases Lists available ###############${clear}"

       
         #dont need this line we used it in global file
        #databases_arr=($(ls -l "$DB_DIR" | grep '^d' | awk '{print $NF}'))

        # Loop through the array and print each item on a new line
        for database in "${DATABASES_ARR[@]}"; do
            echo -e "$database${clear} "
        done
        navigate_menu
    fi
}

# connect database 
function connect_to_database() {

  #get only folders in the directory
  #awk '{print $NF}': Prints the last field (the name of the directory) from each line of the output.
  if is_array_empty "${DATABASES_ARR[@]}"; then
      echo -e "############### No Databases Found! ###############${clear}"
      navigate_menu
  else
      echo -e "###############Connect to a Database###############${clear}"
    


      PS3=$(echo -e "*** Select a database from the following list: ${clear}")
      select database_name in "${DATABASES_ARR[@]}"; do
          if [[ -n "$database_name" ]]; then #-n checks if choice is not null
              SELECTED_DB=$database_name
              echo -e "CONNECTED TO DATABASE: $database_name${clear}"
              break
          else
              echo -e "${yellow}Warning: Invalid choice. Please select a valid number.${clear}"
          fi
      done
      tablesMenu
  fi
}

#drop database
drop_database () {
  if is_array_empty "${DATABASES_ARR[@]}"; then
      echo -e "############### No Databases Found! ############### ${clear}"
      navigate_menu
  else
      echo -e "###############Drop a Database###############"
      PS3=$(echo -e ">> Select a database from the above list: ${clear}")
      select database_name in "${DATABASES_ARR[@]}"; do
          if [[ -n "$database_name" ]]; then
              echo -e "Are you sure you want to drop $database_name?."
              echo -e "${yellow}Warrning: This action cannot be undone. (yes/no) ${clear}"
              read user_choice
              if [[ "yes"  =~ "$user_choice" ]]; then
                  rm -r "$DB_DIR/$database_name"
                  # Update the DATABASES_ARR
                  DATABASES_ARR=($(ls -l "$DB_DIR" | grep '^d' | awk '{print $NF}'))
                  echo -e "DATABASE: $database_name DROPPED SUCCESSFULLY.${clear}"
                  break
              else
                  echo -e "Aborting database drop.${clear}"
                  break
              fi
          else
              echo -e "${yellow}Warning: Invalid choice. Please select a valid number.${clear}"
          fi
      done
      navigate_menu
  fi 
}

# main menu 
function main_menu() {
    #check if the directory exists
    if ! is_already_exists_db_dir "$DB_DIR" ;then
  
        mkdir -p "$DB_DIR"
    fi
    echo "###############################################################################"
    echo -e "############### Welcome to the Database Management System ###############"
    echo "###############################################################################"

    PS3=$(echo -e "*** Choose an option: ${clear}") # Colorize the prompt

    select option in "Create Database"  "List Database"   "Connect Database" "Drop Database"  "Exit"; do
        case $option in
            "Create Database")
                create_database # Call the function from CreateDatabase
                ;;
            "List Database")
                list_database  # Call the function from ListDatabase
                ;;
            "Connect Database")
                connect_to_database  
                break  
                ;;
            "Drop Database")
                drop_database  # Call the function from DropDatabase
                break
                ;;
            "Exit")
                echo -e "Exiting. Goodbye!${clear}"
                exit 0  # Exit the script
                ;;
            *)
                echo -e "${yellow}Warning: Invalid option. Please try again.${clear}" 
                ;;
        esac
    done
}

navigate_menu() {
    echo -e "*** Do you want to go back to the main menu? (yes/no) ${clear}"
    read  user_choice
    if [[ "yes"  =~ "$user_choice" ]]; then
         main_menu
    elif [[ "no"  =~ "$user_choice"  ]]; then
        echo -e "Exiting. Goodbye!"
        exit 0
    else
        echo -e "${yellow} Warrning: Invalid option! Please try again. ${clear}"
        navigate_menu
    fi
}

main_menu