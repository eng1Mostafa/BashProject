#!/bin/bash

# Global variable to track the current database
current_db=""

# Function to check if the user clicked "Cancel"
check_cancel() {
    if [ $? -ne 0 ]; then
        exit 0
    fi
}

# Main Menu Functions

create_database() {
    dbname=$(zenity --entry --title="Create Database" --text="Enter database name:")
    check_cancel
    if [ -n "$dbname" ]; then
        mkdir -p ./databases/$dbname && zenity --info --text="Database $dbname created."
    else
        zenity --error --text="No database name entered."
    fi
}

list_databases() {
    databases=$(ls -1 ./databases 2>/dev/null)
    if [ -z "$databases" ]; then
        zenity --info --text="No databases found."
    else
        zenity --list --title="Available Databases" --column="Databases" $databases
    fi
    check_cancel
}

connect_database() {
    dbname=$(zenity --entry --title="Connect to Database" --text="Enter the database name:")
    check_cancel
    if [ -d "./databases/$dbname" ]; then
        current_db=$dbname
        zenity --info --text="Connected to $dbname"
        table_menu $dbname
    else
        zenity --error --text="Database $dbname does not exist."
    fi
}

drop_database() {
    dbname=$(zenity --entry --title="Drop Database" --text="Enter the database name:")
    check_cancel
    if [ -d "./databases/$dbname" ]; then
        rm -r ./databases/$dbname
        zenity --info --text="Database $dbname dropped."
        if [ "$current_db" == "$dbname" ]; then
            current_db=""
        fi
    else
        zenity --error --text="Database $dbname does not exist."
    fi
}

show_current_database() {
    if [ -n "$current_db" ]; then
        zenity --info --title="Current Database" --text="You are connected to database: $current_db"
    else
        zenity --info --title="Current Database" --text="You are not connected to any database."
    fi
    check_cancel
}

exit_program() {
    zenity --question --text="Are you sure you want to exit?" --title="Exit Confirmation"
    check_cancel
}

main_menu() {
    while true; do
        choice=$(zenity --list --title="Main Menu" --column="Options" \
            "Create Database" "List Databases" "Connect To Database" \
            "Drop Database" "Show Current Database" "Show All Databases" "Exit")
        check_cancel
        
        case $choice in
            "Create Database") create_database ;;
            "List Databases") list_databases ;;
            "Connect To Database") connect_database ;;
            "Drop Database") drop_database ;;
            "Show Current Database") show_current_database ;;
            "Show All Databases") list_databases ;;
            "Exit") exit_program ;;
            *) zenity --error --text="Invalid choice." ;;
        esac
    done
}

# Table Menu Functions

create_table() {
    dbname=$1
    tblname=$(zenity --entry --title="Create Table" --text="Enter table name:")
    check_cancel
    if [ -n "$tblname" ]; then
        touch ./databases/$dbname/$tblname && zenity --info --text="Table $tblname created in $dbname."
    else
        zenity --error --text="No table name entered."
    fi
}

list_tables() {
    dbname=$1
    tables=$(ls -1 ./databases/$dbname 2>/dev/null)
    if [ -z "$tables" ]; then
        zenity --info --text="No tables found in $dbname."
    else
        zenity --list --title="Tables in $dbname" --column="Tables" $tables
    fi
    check_cancel
}

drop_table() {
    dbname=$1
    tblname=$(zenity --entry --title="Drop Table" --text="Enter table name to drop:")
    check_cancel
    if [ -f "./databases/$dbname/$tblname" ]; then
        rm ./databases/$dbname/$tblname && zenity --info --text="Table $tblname dropped from $dbname."
    else
        zenity --error --text="Table $tblname does not exist in $dbname."
    fi
}

insert_into_table() {
    dbname=$1
    tblname=$(zenity --entry --title="Insert into Table" --text="Enter table name to insert into:")
    check_cancel
    if [ -f "./databases/$dbname/$tblname" ]; then
        data=$(zenity --entry --title="Insert Data" --text="Enter data (comma-separated):")
        check_cancel
        echo $data >> ./databases/$dbname/$tblname && zenity --info --text="Data inserted into $tblname."
    else
        zenity --error --text="Table $tblname does not exist in $dbname."
    fi
}

select_all_columns() {
    dbname=$1
    tblname=$2
    data=$(cat ./databases/$dbname/$tblname)
    zenity --text-info --title="All Columns from $tblname" --filename=<(echo "$data")
    check_cancel
}

select_specific_column() {
    dbname=$1
    tblname=$2
    colnum=$(zenity --entry --title="Select Column" --text="Enter column number to select:")
    check_cancel
    data=$(awk -F"," -v col=$colnum '{print $col}' ./databases/$dbname/$tblname)
    zenity --text-info --title="Column $colnum from $tblname" --filename=<(echo "$data")
    check_cancel
}

select_with_condition() {
    dbname=$1
    tblname=$2
    colnum=$(zenity --entry --title="Select with Condition" --text="Enter column number for condition:")
    check_cancel
    value=$(zenity --entry --title="Condition" --text="Enter value to match:")
    check_cancel
    data=$(awk -F"," -v col=$colnum -v val=$value '$col == val' ./databases/$dbname/$tblname)
    zenity --text-info --title="Rows matching condition in $tblname" --filename=<(echo "$data")
    check_cancel
}

delete_from_table() {
    dbname=$1
    tblname=$2
    condition=$(zenity --entry --title="Delete From Table" --text="Enter condition to delete row (column=value):")
    check_cancel
    colnum=$(echo $condition | cut -d'=' -f1)
    value=$(echo $condition | cut -d'=' -f2)
    awk -F"," -v col=$colnum -v val=$value '$col != val' ./databases/$dbname/$tblname > temp && mv temp ./databases/$dbname/$tblname
    zenity --info --text="Row(s) deleted from $tblname."
}

update_table() {
    dbname=$1
    tblname=$2
    condition=$(zenity --entry --title="Update Table" --text="Enter condition to update row (column=value):")
    check_cancel
    new_value=$(zenity --entry --title="New Value" --text="Enter new value (comma-separated):")
    check_cancel
    colnum=$(echo $condition | cut -d'=' -f1)
    value=$(echo $condition | cut -d'=' -f2)
    awk -F"," -v col=$colnum -v val=$value -v new_val=$new_value '$col == val {$0=new_val}1' ./databases/$dbname/$tblname > temp && mv temp ./databases/$dbname/$tblname
    zenity --info --text="Row(s) updated in $tblname."
}

table_menu() {
    dbname=$1
    while true; do
        choice=$(zenity --list --title="Table Menu" --column="Options" \
            "Create Table" "List Tables" "Drop Table" "Insert into Table" \
            "Select From Table" "Delete From Table" "Update Table" "Back to Main Menu")
        check_cancel
        
        case $choice in
            "Create Table") create_table $dbname ;;
            "List Tables") list_tables $dbname ;;
            "Drop Table") drop_table $dbname ;;
            "Insert into Table") insert_into_table $dbname ;;
            "Select From Table")
                tblname=$(zenity --entry --title="Select From Table" --text="Enter table name:")
                check_cancel
                subchoice=$(zenity --list --title="Select Options" --column="Options" \
                    "Select All Columns" "Select Specific Column" "Select with Condition")
                check_cancel
                case $subchoice in
                    "Select All Columns") select_all_columns $dbname $tblname ;;
                    "Select Specific Column") select_specific_column $dbname $tblname ;;
                    "Select with Condition") select_with_condition $dbname $tblname ;;
                esac
            ;;
            "Delete From Table")
                tblname=$(zenity --entry --title="Delete From Table" --text="Enter table name:")
                check_cancel
                delete_from_table $dbname $tblname ;;
            "Update Table")
                tblname=$(zenity --entry --title="Update Table" --text="Enter table name:")
                check_cancel
                update_table $dbname $tblname ;;
            "Back to Main Menu") break ;;
            *) zenity --error --text="Invalid choice." ;;
        esac
    done
}

# Start Application
main_menu

