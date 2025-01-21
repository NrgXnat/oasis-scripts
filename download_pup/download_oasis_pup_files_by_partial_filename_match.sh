#!/bin/bash
#
#================================================================
# download_pup_files_by_partial_match.sh
#================================================================
#
# Usage: ./download_pup_files_by_partial_match.sh <input_file.csv> <directory_name> <xnat_username> <site> "string_to_match" <av1451_project_id_optional>
# 
# Download PUP output files that match a specific string 
# from an XNAT site based on a list of PUP CSVs and an input matching string.
#
# Required inputs:
# <input_file.csv> - A Unix formatted, comma-separated file containing the following columns:
#       FreeSurfer ID
# <directory_name> - A directory path (relative or absolute) to save the scan files to
# <xnat_username> - Your username used for accessing data on the given site
#       (you will be prompted for your password before downloading)
# <filename_to_match> - The string you want to match with the partial file name.
# <tau_project_id> - (optional) if you are downloading from OASIS3_AV1451 or OASIS3_AV1451L, 
#       specify which project to download from. Other OASIS projects will be chosen
#       automatically based on session label."
#
#
# Last Updated: 1/21/2024
# Author: Sarah Keefe
#

# Authenticates credentials against XNAT and returns the cookie jar file name. USERNAME and
# PASSWORD must be set before calling this function.
#   USERNAME="foo"
#   PASSWORD="bar"
#   COOKIE_JAR=$(startSession)
startSession() {
    # Authentication to XNAT and store cookies in cookie jar file
    local COOKIE_JAR=.cookies-$(date +%Y%M%d%s).txt
    curl -k -s -u ${USERNAME}:${PASSWORD} --cookie-jar ${COOKIE_JAR} "${SITE}/data/JSESSION" > /dev/null
    echo ${COOKIE_JAR}
}

# Downloads a resource from a URL and stores the results to the specified path. The first parameter
# should be the destination path and the second parameter should be the URL.
download() {
    local OUTPUT=${1}
    local URL=${2}
    curl -H 'Expect:' --keepalive-time 2 -k --cookie ${COOKIE_JAR} -o ${OUTPUT} ${URL}
}

# Gets a resource from a URL.
get() {
    local URL=${1}
    curl -H 'Expect:' --keepalive-time 2 -k --cookie ${COOKIE_JAR} ${URL}
}

# Ends the user session.
endSession() {
    # Delete the JSESSION token - "log out"
    curl -i -k --cookie ${COOKIE_JAR} -X DELETE "${SITE}/data/JSESSION"
    rm -f ${COOKIE_JAR}
}


# usage instructions
if [ ${#@} == 0 ]; then
    echo ""
    echo "Download PUP files by filename partial match"
    echo ""
    echo "This script downloads files from PUP output from a specified XNAT site, "
    echo "based on a list of PUP IDs in a csv file and a string to match in the filename. "
    echo ""   
    echo "Usage: $0 input_file.csv filename_list.csv directory_name xnat_username filename_string_to_match tau_project_id_optional"
    echo "<input_file>: A Unix formatted, comma separated file containing the following columns:"
    echo "    OASIS pup_id (e.g. OAS30001_AV45_PUPTIMECOURSE_d2430)"  
    echo "<directory_name>: Directory path to save scan files to"  
    echo "<xnat_username>: Your username used for accessing the requested XNAT site (you will be prompted for your password)"    
    echo "<filename_string_to_match>: String to match within the PUP filename. Must be in double quotes, no special characters or spaces"   
    echo "<tau_project_id> - (optional) if you are downloading from OASIS3_AV1451 or OASIS3_AV1451L, specify which project to download from. Other OASIS projects will be chosen automatically based on session label."      
else 

    # Get the input arguments
    INFILE=$1
    DIRNAME=$2
    USERNAME=$3
    SITE="https://nitrc.org/ir"
    STRING_TO_MATCH=$4    
    AV1451_PROJ_ID=$5   

    # Create the directory if it doesn't exist yet
    if [ ! -d $DIRNAME ]
    then
        mkdir -p $DIRNAME
    fi

    # Read in password
    read -s -p "Enter your password for accessing data on ${SITE}:" PASSWORD

    echo ""

    COOKIE_JAR=$(startSession)

    # Read the file
    cat $INFILE | while IFS=, read -r PUP_ID; do

        # Get the subject ID from the first part of the PUP ID (OAS30001 from ID OAS30001_AV45_PUPTIMECOURSE_d2430)
        SUBJECT_ID=`echo $PUP_ID | cut -d_ -f1`

        # Get the tracer from the second  part of the PUP ID (AV45 from ID OAS30001_AV45_PUPTIMECOURSE_d2430)
        TRACER=`echo $PUP_ID | cut -d_ -f2`

        # Get the days from entry from the fourth part of the PUP ID (d2430 from ID OAS30001_AV45_PUPTIMECOURSE_d2430)
        DAYS_FROM_ENTRY=`echo $PUP_ID | cut -d_ -f4`

        # combine to form the PET experiment label (OAS30001_AV45_d2430)
        EXPERIMENT_LABEL=${SUBJECT_ID}_${TRACER}_${DAYS_FROM_ENTRY}

        # Set project in URL based on experiment ID
        # default to OASIS3
        PROJECT_ID=OASIS3
        # If the experiment ID provided starts with OASIS4 then use project=OASIS4 in the URL
        if [[ "${EXPERIMENT_LABEL}" == "OAS4"* ]]; then
            PROJECT_ID=OASIS4
        fi

        echo "Downloading specified files for ${EXPERIMENT_LABEL} PUP output, PUP label=${PUP_ID}."        

        # If the experiment ID provided starts with OAS3XXXXX_AV1451 then check if "AV1451_PROJ_ID" is set
        # If so, use that as the project ID. Otherwise use project=OASIS3_AV1451 in the URL
        if [[ "${EXPERIMENT_LABEL}" == "OAS3"*"_AV1451"* ]]; then
            if [[ "${AV1451_PROJ_ID}" == "OASIS3_AV1451" ]] || [[ "${AV1451_PROJ_ID}" == "OASIS3_AV1451L" ]]; then
                echo "Tau project ID ${AV1451_PROJ_ID} was specified. Downloading from ${AV1451_PROJ_ID}."
                PROJECT_ID=${AV1451_PROJ_ID}
            else
                PROJECT_ID=OASIS3_AV1451
                # You can also uncomment the line below if you are downloading longitudinal AV1451 data
                # and don't want to send AV1451_PROJ_ID as an input to this script.
                #PROJECT_ID=OASIS3_AV1451L
            fi
        fi

        # Set up the download URL and make a cURL call to download the requested PUP file list
        FILES_INFO_URL=${SITE}/data/archive/projects/${PROJECT_ID}/subjects/${SUBJECT_ID}/experiments/${EXPERIMENT_LABEL}/assessors/${PUP_ID}/files?format=csv

        echo "Checking files info url: ${SCAN_INFO_URL}"

        FILES_FROM_SESSION_CSV_OUTPUT=$(get $FILES_INFO_URL)

        echo -e "$FILES_FROM_SESSION_CSV_OUTPUT" | while read -r line; do
            # get file info
            FILENAME=`echo $line | cut -d, -f1`
            FILE_URI=`echo $line | cut -d, -f3`
            FILE_RESOURCE=`echo $line | cut -d, -f4`
            #echo "Found a file: ${FILENAME}. Checking if the filename matches the input string."

            FILENAME_LOWER=`echo ${FILENAME} | awk '{print tolower($0)}'`         
            STRING_TO_MATCH_LOWER=`echo ${STRING_TO_MATCH} | awk '{print tolower($0)}'`

            echo "Checking for string ${STRING_TO_MATCH_LOWER} in filename ${FILENAME_LOWER}."

            if [[ "${FILENAME_LOWER}" == *"${STRING_TO_MATCH_LOWER}"* ]]; then

                echo "Filename ${FILENAME} contains input string ${STRING_TO_MATCH_LOWER}. Downloading it."

                FILE_DOWNLOAD_URL="${SITE}${FILE_URI}"

                echo "Downloading from file download url: ${FILE_DOWNLOAD_URL}"

                download ${DIRNAME}/${FILENAME} ${FILE_DOWNLOAD_URL}

                FILE_URI_NEWDELIM=${FILE_URI/files\//#}

                FOLDER_AND_FILENAME=`echo ${FILE_URI_NEWDELIM} | cut -d# -f2`

                echo $FOLDER_AND_FILENAME

                FILES_SUBFOLDER_ONLY=${FOLDER_AND_FILENAME/\/$FILENAME/}
                OUTPUT_FOLDERNAME=${DIRNAME}/${EXPERIMENT_LABEL}/${PUP_ID}/${FILES_SUBFOLDER_ONLY}

                mkdir -p ${OUTPUT_FOLDERNAME}

                mv ${DIRNAME}/${FILENAME} ${OUTPUT_FOLDERNAME}/.

            fi

        done

        echo "Done with ${PUP_ID}."

    done

    endSession

fi

