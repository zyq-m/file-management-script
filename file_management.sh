#!/bin/bash

organize_file() {
    source_dir="$1"
    target_dir="$2"

    # Create target directories for file types and age ranges
    mkdir -p "$target_dir/text/last_7_days"
    mkdir -p "$target_dir/text/last_30_days"
    mkdir -p "$target_dir/text/more_than_30_days"
    mkdir -p "$target_dir/image/last_7_days"
    mkdir -p "$target_dir/image/last_30_days"
    mkdir -p "$target_dir/image/more_than_30_days"
    mkdir -p "$target_dir/video/last_7_days"
    mkdir -p "$target_dir/video/last_30_days"
    mkdir -p "$target_dir/video/more_than_30_days"
    mkdir -p "$target_dir/others/last_7_days"
    mkdir -p "$target_dir/others/last_30_days"
    mkdir -p "$target_dir/others/more_than_30_days"

    # Iterate over source directory
    for file in "$source_dir"/*; do
        # Check if it's file
        if [ -f "$file" ]; then
            # Get file extension
            extension="${file##*.}"

            case "$extension" in
            txt)
                type="text"
                ;;

            jpg | jpeg | png | gif)
                type="image"
                ;;

            mp4 | mov | avi | mkv)
                type="video"
                ;;

            *)
                type="others"
                ;;
            esac

            # Calculate file age in days
            file_age=$((($(date +%s) - $(stat -c %Y "$file")) / 86400))

            # Determine age range
            if [ "$file_age" -le 7 ]; then
                age_range="last_7_days"
            elif [ "$file_age" -le 30 ]; then
                age_range="last_30_days"
            else
                age_range="more_than_30_days"
            fi

            move_file_path="$target_dir/$type/$age_range"

            # Move to suitable directory
            mv "$file" "$move_file_path"

            # Log file movement
            echo "$(date) - Moved file: $file -> $move_file_path" >>"$(pwd)/log/file.log"
        fi
    done

    echo "Operation done! Open $(pwd)/log/file.log to see log report"
}

rename_file() {
    directory="$1"

    # Prompt the user for the prefix
    printf "Enter the prefix for the new filenames: "
    read -r prefix

    # Prompt the user for the starting sequence number
    printf "Enter the starting sequence number: "
    read -r start_sequence

    # Initialize the sequence counter
    sequence=$start_sequence

    # Iterate over each file in the directory
    for file in "$directory"/*/*/*; do
        # Check if it's a file
        if [ -f "$file" ]; then
            # Get the file extension
            extension="${file##*.}"

            # Generate the new filename with prefix and sequence number
            new_filename="${prefix}${sequence}.${extension}"

            new_file_path="${file%/*}/$new_filename"

            # Rename the file
            mv "$file" "$new_file_path"

            # Increment the sequence counter
            ((sequence++))

            # Log the file rename
            echo "$(date) - Renamed file: $file -> $new_file_path" >>"$(pwd)/log/file.log"
        fi
    done

    echo "Operation done! Open $(pwd)/log/file.log to see log report"
}

share_file() {
    shared_dir="$(pwd)/share_files"

    # Create the shared directory if it doesn't exist
    mkdir -p "$shared_dir"

    # Allow users to add files to the shared directory
    printf "Enter the path to the file you want to add: "
    read -r file_path
    cp "$file_path" "$shared_dir/"

    # Automatically sync changes using Git
    cd "$shared_dir" || exit
    git init
    git add . && git commit -m "Add new file"

    # Manage permissions for the shared directory
    group_name="shared-group"
    sudo groupadd "$group_name"
    sudo chown -R :"$group_name" "$shared_dir"
    sudo chmod -R 770 "$shared_dir"
}

# main file
echo "Hey $(whoami), Welcome to File Management System. Choose your menu:"
echo "1.Organize files"
echo "2.Rename files"
echo "3.Share files"
echo "4.Exit"

exit=false

while ! $exit; do
    printf "\nEnter menu: "
    read -r option_input

    if [ "$option_input" -eq 4 ]; then
        exit=true
    elif [ "$option_input" -eq 1 ]; then
        organize_file "$(pwd)/files" "$(pwd)/managed_files"
    elif [ "$option_input" -eq 2 ]; then
        rename_file "$(pwd)/managed_files"
    elif [ "$option_input" -eq 3 ]; then
        share_file
    else
        exit=false
    fi
done
