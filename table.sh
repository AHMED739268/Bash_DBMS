#! /bin/bash
source ./global
source ./valid

columns=()
flag=1


function create_table() {
    echo -e "###############Table Creation in $SELECTED_DB###############${clear}"

    echo -e ">> Enter table name: ${clear}" 
    read tblName
    
    if ! is_empty_input "$tblName" && ! is_already_exists_file "$DB_DIR/$SELECTED_DB/$tblName" && is_valid_name "$tblName"; then
    echo -e "${blue}Table name [ $tblName ] is valid ###############"
    sleep 0.5
    echo -e "Continuing ###############${clear}" 
    flag=1
    else
        echo -e "${yellow}Warning: Invalid table name. Please try again. ${clear}" 
        flag=0
        create_table
    fi

    if [ $flag -eq 1 ]; then
        # Input number of columns-------------------------------
        echo -e ">> Enter the number of columns in your table: ${clear}"
        read colNum
        
    if ! is_empty_input "$colNum" && is_int "$colNum" && ! is_less_than_zero "$colNum"; then
            echo -e "${blue}Number of columns [ $colNum ] is valid."
            sleep 0.5
            echo -e "Continuing ###############${clear}" 
            
            touch "$DB_DIR/$SELECTED_DB/$tblName"  
            touch "$DB_DIR/$SELECTED_DB/$tblName.metadata"
            
            if [[ -f "$DB_DIR/$SELECTED_DB/$tblName" && -f "$DB_DIR/$SELECTED_DB/$tblName.metadata" ]]; then
                echo -e "${green}Files '$tblName' and '$tblName.metadata' created successfully for table creation.${clear}"
            else
                echo -e "${yellow}Warning: Failed to create files '$tblName' and/or '$tblName.metadata'.${clear}"
                flag=0  # Set the flag to indicate failure
                create_table  # Retry table creation or handle the error
            fi

            flag=1
            create_columns
        else
            echo -e "${yellow}Failed validation checks. Please try again...${clear}"
            flag=0
            create_table
        fi  
    fi
}

function create_columns() {
    # Adding PK column
    if [ $flag -eq 1 ]; then
        echo -e "Enter PK column followed by datatype: e.g.[ id int ] ${clear}"
        read colName colType
        #backslash \ is used to split the command into multiple lines for better readability 
        if ! is_empty_input "$colName" &&  is_valid_name "$colName" &&  \
        ! is_empty_input "$colType" && ! is_invalid_datatype "$colType" && \
        ! is_duplicate_column "$colName" "$DB_DIR/$SELECTED_DB/$tblName.metadata" ; then
            #adding metadata PK row
            echo  "$colName:$colType:PK" >> "$DB_DIR/$SELECTED_DB/$tblName.metadata"
            echo -e "${green}$colName:$colType:PK is added to $tblName.metadata ${clear}"
            flag=1
        else
            echo -e "${yellow}Failed validation checks. Aborting table creation...${clear}"
            sleep 0.5
            echo -e "Deleting files '$tblName' and '$tblName.metadata'${clear}"
            rm "$DB_DIR/$SELECTED_DB/$tblName" "$DB_DIR/$SELECTED_DB/$tblName.metadata"
            flag=0
            sleep 0.5
            tablesMenu
        fi
    fi

    if [ $flag -eq 1 ]; then
    #IT STRAT FROM 2 TO SKIP THE PK COLUMN AND end of $colNum+1 to include the last column 
        for ((i=2; i<$colNum+1; i++)) # Loop through the number of columns -1 
        do
            echo -e "Enter column $i followed by datatype: e.g.[ name string ] ${clear}"
            read colName colType
            if ! is_empty_input "$colName" &&  is_valid_name "$colName" &&  \
            ! is_empty_input "$colType" && ! is_invalid_datatype "$colType" && \
            ! is_duplicate_column "$colName" "$DB_DIR/$SELECTED_DB/$tblName.metadata" ; then
                echo "$colName:$colType" >> "$DB_DIR/$SELECTED_DB/$tblName.metadata"
                sleep 0.5
                echo -e "${green}$colName:$colType is added to $tblName.metadata ${clear}"
                flag=1
            else
                echo -e "${yellow}Failed validation checks. Aborting table creation...${clear}"
                rm "$DB_DIR/$SELECTED_DB/$tblName" "$DB_DIR/$SELECTED_DB/$tblName.metadata"
                 flag=0
                tablesMenu
            fi
        done
    fi
    if [ $flag -eq 1 ]; then
        sleep 0.5
        echo -e "${green}------TABLE [ $tblName ] CREATED SUCCESSFULLY-------${clear}"
        tablesMenu
    fi
}


function insert_into_table() {
    echo -e "-- -- -- --Table Insertion in $SELECTED_DB-- -- -- --${clear}"

   
    tables=($(ls "$DB_DIR/$SELECTED_DB" | grep -v ".metadata"))

   
  
    if [ ${#tables[@]} -eq 0 ]; then
        echo -e "${blue}No tables found in ${SELECTED_DB} ...${clear}"
        sleep 0.5
        echo -e "${blue}Aborting insertion......${clear}"
        sleep 0.5
        tablesMenu
    else
        echo -e "Select a table from the following list:${clear}"
        select table_name in "${tables[@]}"; do
            if [ -n "$table_name" ]; then
                echo -e "${blue}You selected table: $table_name ${clear}"
                SELECTED_TABLE="$table_name"
                sleep 0.5
                break
            else
                echo -e "${yellow} Warrning: Invalid choice. ${clear}"
                flag=0
            fi
        done
    fi

    # Check if the table and its metadata exist
    if is_valid_table; then
        echo -e "${blue}Table [ $table_name ] ${blue}exists and valid.${clear}"
        sleep 0.5
        insert_table_data
    else
        echo -e "${yellow}Warning: Table '$table_name' does not exist.${clear}"
        flag=0
        tablesMenu
    fi
}

function listTables(){
  echo -e "############### Table Listing in $SELECTED_DB ###############${clear}"

  #ensure user is connected to db
  if [ -z "$SELECTED_DB" ]; then
    echo -e "${yellow}Warrning: No database selected. Please connect to a database first.${clear}"
    return
  fi

 
  dbDirPath="$DB_DIR/$SELECTED_DB"

  tableCount=$(find "$dbDirPath" -type f ! -name "*.metadata" | wc -l)
  if [[ "$tableCount" -eq 0 ]]; then
    echo -e "${blue}No tables found in ${SELECTED_DB} ...${clear}"
    sleep 0.5
    echo -e "${blue}Aborting Listing.${clear}"
    sleep 0.5
    tablesMenu
  fi
  
  echo -e "############### Available Tables in $SELECTED_DB ############### ${clear}"
  
  #check if the file is not metadata file and print the name of the table USING BASENAME 
  #to get the name    of the file without the path

  for file in "$dbDirPath"/*; do
    if [[ "$file" != *.metadata ]]; then
      tableName=$(basename "$file")
      echo -e "${blue}$tableName${clear}"
    fi
  done

  tablesMenu
}

function insert_table_data() {
   
    column_names=($(cut -d ':' -f 1 "$DB_DIR/$SELECTED_DB/$table_name.metadata"))
    data_types=($(cut -d ':' -f 2 "$DB_DIR/$SELECTED_DB/$table_name.metadata"))

    # Check if table has no columns 
    if [ ${#column_names[@]} -eq 0 ]; then
        echo -e "${blue}Table [ $table_name ]${blue} has no columns.${clear}"
        sleep 0.5
        echo -e "${blue}Aborting insertion.${clear}"
        flag=0
        tablesMenu
    fi
    columns_with_types=""
    #displaying columns with types
    for i in "${!column_names[@]}"; do
        columns_with_types+="${column_names[i]} ${blue}(${data_types[i]})${clear} "
    done

    echo -e "*** Insert data in the order of columns (space-separated):"
    echo -e "${columns_with_types}${clear}"
    read -a values  # Array to store user input values
    #####################################################################

    # Check if the number of input values matches the number of columns

    #ne is not equal to
    if [ ${#values[@]} -ne ${#column_names[@]} ]; then
        echo -e "${yellow}Warning: The number of values does not match the number of columns.${clear}"
        flag=0
        insert_table_data
    else
        flag=1
    fi

    if [ $flag -eq 1 ]; then
        # Validate primary key and data types

        for i in "${!values[@]}"; do
            if [ $i -eq 0 ]; then  # First column is the primary key
              

    
                if [ $(awk -F':' -v val="${values[$i]}" '$1 == val {print $1}' "$DB_DIR/$SELECTED_DB/$table_name" | wc -l) -gt 0 ]; then
                    echo -e "${yellow}Warning: Value '${values[$i]}' already exists as a primary key.${clear}"
                    flag=0
                    insert_table_data # Try again
                fi
            fi
        
          
            if { [ "${data_types[$i]}" == "int" ] && ! is_int "${values[$i]}"; } || { [ "${data_types[$i]}" == "string" ] && ! is_string "${values[$i]}"; }; then
                echo -e "${yellow}Warning: Invalid data type for column '${column_names[$i]}'.${clear}"
                flag=0
                insert_table_data # Try again
            fi
        done
        
                if [ $flag -eq 1 ]; then
                    #s/ /:/g: Substitutes all spaces with (:)
                    echo "${values[@]}" | sed 's/ /:/g' >> "$DB_DIR/$SELECTED_DB/$table_name"
                    #checking the exit status of the previous command. If the exit status is equal to 0, it means the previous command was successful.
                   # $? is a special variable that holds the exit status of the last command executed and 0 means success
                    if [ $? -eq 0 ]; then
                        echo -e "${green}DATA INSERTED INTO TABLE '$table_name' SUCCESSFULLY.${clear}"
                        echo -e "Do you want to insert another row (y/n)? ${clear}"
                        read choice
                        if [ "$choice" == "y" ]; then
                            insert_table_data
                        else
                            tablesMenu
                        fi
                    else
                        echo -e "${yellow}Warning: Failed to insert data into the table.${clear}"
                        insert_table_data
                    fi
                fi
    fi
}

function select_from_table() {
    echo -e "############### Table Selection in $SELECTED_DB ###############${clear}"
    columns=()
   
    tables_arr=($(ls "$DB_DIR/$SELECTED_DB" | grep -v ".metadata")) #-v invert matches [select all files except .metadata]

    if is_array_empty "${tables_arr[@]}"; then
        echo -e "${blue}No tables found in the ${SELECTED_DB}.${clear}"
        sleep 0.5
        echo -e "${blue}Aborting selection.......${clear}"
        sleep 0.5
        flag=0
        tablesMenu
    fi

    PS3=$(echo -e "*** Select a table from the above list: ${clear}")
    select table_name in "${tables_arr[@]}"; do
        if [[ -n "$table_name" ]]; then #-n checks if choice is not null
            SELECTED_TABLE=$table_name
            echo -e "${blue}You selected table: $table_name${clear}"
            if is_valid_table; then
                columns=($(cut -d: -f1 "$DB_DIR/$SELECTED_DB/$table_name.metadata"))
                COLUMNS=$columns
                select_table_menu "$table_name"
            else
                flag=0
                tablesMenu
            fi
        else
            echo -e "${yellow}Warning: Invalid choice.${clear}"
            select_from_table
        fi
    done
}

# Function to handle table data options
function select_table_menu() {
    local table_name="$1"
    PS3=$(echo -e "*** Choose a select option for table [ $table_name ] ${clear}")
    select option in "Select all rows" "Select specific row" "Go back"; do
        case $option in
            "Select all rows")
                select_all "$table_name"
                select_table_menu $1
                ;;
            "Select specific row")
                select_where "$table_name"
                break
                ;;
            "Go back")
                tablesMenu
                break
                ;;
            *)
                echo -e "${yellow}Warning: Invalid option.${clear}"
                ;;
        esac
    done
}

# Function to read all rows from a table
function select_all() {
    #internal field separator (IFS) to a tab (\t) so that elements of the array are joined with tabs instead of spaces.
    echo -e "$(IFS=$'\t'; echo "${columns[*]}")${clear}"
    echo -e "$(cat "$DB_DIR/$SELECTED_DB/$1" | tr ':' '\t')${clear}"
}

# Function to read rows by specific column value
function select_where() {
    column_name=""
    PS3=$(echo -e "*** Enter the column number to search by ${clear}")
    
    # Display column names as choices
    select column_name in "${columns[@]}"; do
        if [[ -n "$column_name" ]]; then
            echo -e "${blue}Enter the value for column: $column_name${clear}"
            break  # Exit the loop when a valid column is selected
        else
            echo -e "${yellow}Invalid choice. Please select a valid column.${clear}"
            # Re-prompt the user to select a valid column
            select_where "$1"
        fi
    done

    # Check if the column name is not null
    if [[ -z "$column_name" ]]; then
        echo -e "${yellow}Column name is null. Please try again.${clear}"
        select_where
    fi

    
    PS3=$(echo -e ">>Enter the value for $column_name ${clear}")
    read value
    
    echo -e "${blue}Getting records where  $column_name ${blue} = ${red}'$value' ${clear}"


    # Find the column index
    column_index=$(grep -n "^$column_name:" "$DB_DIR/$SELECTED_DB/$1.metadata" | cut -d: -f1)

    # If column index is found, proceed to search for the value in that column
    if [[ -n "$column_index" ]]; then
       
        data=$(awk -F: -v col=$column_index -v val="$value" '$col == val' "$DB_DIR/$SELECTED_DB/$1")
        
        if [[ -n "$data" ]]; then
            # Count the number of matching rows and handle empty data
            num_rows=$(echo "$data" | awk 'END {print NR}') # NR is the number of rows
            echo -e "[ $num_rows ]${green} matching rows found!${clear}"
            sleep 0.5

            # Display the matching rows
            echo -e "${green}THE MATCHING ROWS:${clear}"
            sleep 0.5
            echo -e "$(IFS=$'\t'; echo "${columns[*]}")${clear}"
            echo -e "$(echo "$data" | tr ':' '\t')${clear}"
        else
            echo -e "${yellow}No matching rows found!${clear}"
        fi
        
    else
        echo -e "${yellow}Warning: Column '$column_name' not found in metadata.${clear}"
    fi
    
    tablesMenu
}

function update_table() {
    echo -e "############### Table Update in $SELECTED_DB ###############${clear}"

    # List available tables in the selected database
    tables=($(ls "$DB_DIR/$SELECTED_DB" | grep -v ".metadata"))

    if [ ${#tables[@]} -eq 0 ]; then
        echo -e "${blue}No tables found in ${SELECTED_DB} ...${clear}"
        sleep 0.5
        echo -e "${blue}Aborting update......${clear}"
        sleep 0.5
        tablesMenu
    fi

    echo -e "Select a table from the following list:${clear}"
    select table_name in "${tables[@]}"; do
        if [ -n "$table_name" ]; then
            echo -e "${blue}You selected table: $table_name ${clear}"
            sleep 0.5
            SELECTED_TABLE="$table_name"
            break
        else
            echo -e "${yellow}Warning: Invalid choice. ${clear}"
        fi
    done

    table_file="$DB_DIR/$SELECTED_DB/$SELECTED_TABLE"
    metadata_file="${table_file}.metadata"

    if [ ! -f "$metadata_file" ]; then
        echo -e "${red}Error: Metadata file not found for table $SELECTED_TABLE.${clear}"
        tablesMenu
    fi

    columns=($(awk -F':' '{print $1}' "$metadata_file"))
    echo -e "Table structure:${clear}"
    awk -F':' '{print NR ". " $1}' "$metadata_file"

    # Prompt for filter condition
    echo -e ">>Enter the filter condition (e.g. name=Ahmed):${clear}"
    read filter_condition
    filter_column=$(echo "$filter_condition" | cut -d= -f1)
    filter_value=$(echo "$filter_condition" | cut -d= -f2)

    filter_col_index=$(awk -F':' -v col="$filter_column" '$1 == col {print NR}' "$metadata_file")
    if [ -z "$filter_col_index" ]; then
        echo -e "${yellow}Warning: Column '$filter_column' not found in metadata.${clear}"
        update_table  # Abort if the filter column doesn't exist
    fi

    echo -e "Filter Column found: [ $filter_column ] at index: $filter_col_index"
    sleep 0.5

    # Prompt for update condition
    echo -e ">>Enter the update condition (e.g. age=30):${clear}"
    read update_condition
    change_column=$(echo "$update_condition" | cut -d= -f1)
    new_value=$(echo "$update_condition" | cut -d= -f2)

    change_col_index=$(awk -F':' -v col="$change_column" '$1 == col {print NR}' "$metadata_file")
    if [ -z "$change_col_index" ]; then
        echo -e "${yellow}Warning: Column '$change_column' not found in metadata.${clear}"
        update_table  # Abort if the update column doesn't exist
    fi

    echo -e "Update Column found: [ $change_column ] at index: $change_col_index"

    # Proceed with the update if no duplicates are found
    awk -F':' -v filter_col="$filter_col_index" -v filter_val="$filter_value" \
        -v update_col="$change_col_index" -v new_val="$new_value" \
        'BEGIN {OFS=FS} 
        $filter_col == filter_val { $update_col = new_val } 
        { print $0 }' "$table_file" > tmp && mv tmp "$table_file"

    if [ $? -eq 0 ]; then
        echo -e "${green}RECORDS UPDATED SUCCESSFULLY!${clear}"
        sleep 0.5
    else
        echo -e "${red}Error: Update Failed.${clear}"
    fi

    tablesMenu
}

function drop_table(){
  echo -e "###############Table Drop in $SELECTED_DB###############${clear}"
  # Ensure user is connected to db
  if [ -z "$SELECTED_DB" ]; then
    echo -e "${yellow}Warrning: No database selected. Please connect to a database first.${clear}"
    return
  fi

  # List tables in the selected database (excluding metadata files)
  tables_arr=($(ls "$DB_DIR/$SELECTED_DB" | grep -v ".metadata"))

  # Check if there are any tables
  if [ ${#tables_arr[@]} -eq 0 ]; then
      echo -e "${blue}No tables found in ${SELECTED_DB} ...${clear}"
      sleep 0.5
      echo -e "${blue}Aborting table drop......${clear}"
      sleep 0.5
      tablesMenu
  else
  
  PS3=$(echo -e ">> Select a table from the above list: ${clear}")
  select table_name in "${tables_arr[@]}"; do
      if [[ -n "$table_name" ]]; then
          echo -e "${blue}Are you sure you want to drop $table_name${blue}?"
          echo -e "${yellow}Warrning: This action cannot be undone. (yes/no) ${clear}"
          read user_choice
          if [[ "yes"  =~ "$user_choice" ]]; then
              rm -r "$DB_DIR/$SELECTED_DB/$table_name"
              rm -r "$DB_DIR/$SELECTED_DB/$table_name.metadata"
              # Update the tables_arr
              tables_arr=($(ls -l "$DB_DIR/$SELECTED_DB" | grep -v ".metadata" | awk '{print $NF}'))
              echo -e "${green}TABLE $table_name ${green}DROPPED SUCCESSFULLY.${clear}"
              sleep 0.5
              tablesMenu
          else
              echo -e "${blue}Aborting table drop.${clear}"
              sleep 0.5
              tablesMenu
          fi
      else
          echo -e "${yellow}Warning: Invalid choice. Please select a valid number.${clear}"
      fi
  done
  
  tablesMenu
  fi
}

function delete_from_table() {
    echo -e "###############Table Deletion in $SELECTED_DB###############${clear}"

    # Get the list of tables in the database
    tables=($(ls "$DB_DIR/$SELECTED_DB" | grep -v ".metadata"))
    if [[ ${#tables[@]} -eq 0 ]]; then
        echo -e "${blue}No tables found in ${SELECTED_DB} ...${clear}"
        sleep 0.5
        echo -e "${blue}Aborting deletion......${clear}"
        sleep 0.5
        tablesMenu
    fi

    # Display the table selection menu
    echo -e ">> Select a table from the following list: ${clear}"
    select table_name in "${tables[@]}"; do
        if [[ -n "$table_name" ]]; then
            echo -e "${blue}You selected table: $table_name${clear}"
            sleep 0.5
            # Check if the table and its metadata exist
            SELECTED_TABLE=$table_name
            if is_valid_table; then
                echo -e "${blue}Table $table_name ${blue}exists and valid.${clear}"
                sleep 0.5
            fi
            delete_from_table_menu "$table_name"
            break
        else
            echo -e "${yellow}Invalid choice. Please select a valid number.${clear}"
        fi
    done

    tablesMenu
}

# Function to display delete options
function delete_from_table_menu() {
    echo -e "Choose a delete option for table '$1'?${clear}"
    select option in "Delete row by column value" "Delete all rows" "Go back"; do
        case $option in
            "Delete row by column value")
                delete_row_by_id "$1"
                ;;
            "Delete all rows")
                delete_all_rows "$1"
                ;;
            "Go back")
                return
                ;;
            *)
                echo -e "${yellow}Warning: Invalid option. Please try again.${clear}"
                ;;
        esac
    done
}

# Function to delete a row based on ID or specific column value
function delete_row_by_id() {
    table_file="$DB_DIR/$SELECTED_DB/$1" 
    metadata_file="${table_file}.metadata"
   
   
    if [[ ! -s "$table_file" ]]; then
        echo -e "${blue}Table $1 ${blue}has no data."
        sleep 0.5
        echo -e "${blue}Aborting deletion.${clear}"
        sleep 0.5
        tablesMenu
    fi

  

    pk_column=$(awk -F':' '$3 == "PK" {print $1}' "$metadata_file")
    #and this line to get the index of the primary key it get the number of line (NR) that contain PK
    pk_index=$(awk -F':' '$3 == "PK" {print NR}' "$metadata_file")
    # -z checks if the string is empty 
    if [[ -z "$pk_column" || -z "$pk_index" ]]; then
        echo -e "${yellow}Warning: Primary key not found in metadata.${clear}"
        tablesMenu
    fi

    echo -e "Your Primary Key is: ${red}$pk_column ${clear}"

    # Display the table
    select_all $1
    sleep 0.5
    # Prompt for the value of the primary key
    echo -e "Enter the value of the primary key to delete:${clear}"
    read id_value

    
    awk -F':' -v id="$id_value" -v pk_idx="$pk_index" '{
             if ($pk_idx != id) 
                print $0 
             }' "$table_file" > tmp

    # Move the updated table data back to the original table file
    mv tmp "$table_file"


    echo -e "${green}Row with PK $id_value deleted successfully.${clear}"
    sleep 0.5
    tablesMenu
}

function delete_all_rows() {
    table_file="$DB_DIR/$SELECTED_DB/$1"    
  
       # -s checks if the file is not empty and when add ! it checks if the file is empty 
    if [[ ! -s "$table_file" ]]; then
        echo -e "${blue}Table $1 ${blue}has no data."
        sleep 0.5
        echo -e "${blue}Aborting deletion.${clear}"
        sleep 0.5
        tablesMenu
    fi
    #echo -n > "$table_file" : clears the content of the file
    echo -n > "$table_file"
    echo -e "${green}ALL ROWS DELETED SUCCESSFULLY.${clear}"
    sleep 0.5
    tablesMenu
}


#menu
function tablesMenu(){
    echo -e "###############Welcome to $SELECTED_DB###############${clear}"
    PS3=$(echo -e "*** Choose an option: ${clear}") # Colorize the prompt

    select option in "Create Table" "Insert into Table" "List Tables" "Select from Table" "Update Table" "Drop Table" "Delete from Table" "Back to Main Menu" "Exit"; do
        case $option in
            "Create Table")
                create_table
                ;;
            "Insert into Table")
                insert_into_table
                ;;
            "List Tables")
                listTables
                ;;
            "Select from Table")
                select_from_table
                ;;
            "Update Table") 
                update_table
                ;;
            "Drop Table")
                drop_table
                break
                ;;
            "Delete from Table")
                delete_from_table
                ;;
            "Back to Main Menu")
                main_menu
                ;;
            "Exit")
                echo -e "${blue}Exiting. Goodbye!${clear}"
                exit 0
                ;;
            *)
                echo -e "${yellow}Warning: Invalid option. Please try again.${clear}" 
                ;;
        esac
    done
}
