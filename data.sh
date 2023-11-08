#!/bin/bash

# Run the command and capture its output in a variable
output=$(tutor local run lms ./manage.py lms dump_course_ids)

# Display the entire output for debugging
#echo "Full command output:"
#echo "$output"

# Extract the desired portion of the output
desired_output=$(echo "$output" | awk -F'course-v1:' '{print $2}' | awk -F'+' '{print $1}' | tr -d '[:space:]')

# Display the extracted portion for debugging
#echo "Extracted output: $desired_output"

# Optionally, display a message indicating where the extracted output is saved
#echo "Extracted output has been saved to extracted_output.txt"

# access docker tutor lms

docker cp tutor_local-lms-1:/openedx/media/$desired_output /home/$USER/.

# Define the path to your config.yml file
CONFIG_FILE="/home/$USER/.local/share/tutor/config.yml"

# Extract the MySQL root password from config.yml using grep and awk
DB_PASSWORD=$(grep 'MYSQL_ROOT_PASSWORD' "$CONFIG_FILE" | awk '{print $2}')
# Define the database credentials
DB_USER="root"
DB_NAME="openedx"  # Replace with your database name

# Define the path to the MySQL container
MYSQL_CONTAINER="tutor_local-mysql-1"

# remove old mysql-files dir
docker exec -u root $MYSQL_CONTAINER rm -rf /var/lib/mysql-files/*

# Specify the directory where MySQL will store output files within the container
OUTPUT_DIR="/var/lib/mysql-files"

# SQL queries
QUERY1="use $DB_NAME; select * INTO OUTFILE '$OUTPUT_DIR/1.csv' FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n' from submissions_studentitem;"
QUERY2="use $DB_NAME; select * INTO OUTFILE '$OUTPUT_DIR/2.csv' FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n' from student_anonymoususerid;"
QUERY3="use $DB_NAME; select * INTO OUTFILE '$OUTPUT_DIR/3.csv' FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n' from auth_user;"

# Execute the SQL queries directly inside the MySQL container
docker exec $MYSQL_CONTAINER mysql -u $DB_USER -p$DB_PASSWORD -e "$QUERY1"
docker exec $MYSQL_CONTAINER mysql -u $DB_USER -p$DB_PASSWORD -e "$QUERY2"
docker exec $MYSQL_CONTAINER mysql -u $DB_USER -p$DB_PASSWORD -e "$QUERY3"

mkdir /home/$USER/mysql-files

# Copy the SQL query results to your current directory
docker cp $MYSQL_CONTAINER:$OUTPUT_DIR/1.csv /home/$USER/mysql-files/
docker cp $MYSQL_CONTAINER:$OUTPUT_DIR/2.csv /home/$USER/mysql-files/
docker cp $MYSQL_CONTAINER:$OUTPUT_DIR/3.csv /home/$USER/mysql-files/

mkdir /home/$USER/data

sudo mv /home/$USER/$desired_output /home/$USER/data
sudo mv /home/$USER/mysql-files /home/$USER/data