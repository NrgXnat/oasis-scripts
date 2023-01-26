#!/bin/bash
#
#================================================================
# download_oasis_freesurfer.sh
#================================================================
#
# Usage: ./download_oasis_freesurfer.sh <input_file.csv> <directory_name> <xnat_central_username>
# 
# Download Freesurfer files from OASIS3 or OASIS4 on XNAT Central and organize the files
#
# Required inputs:
# <input_file.csv> - A Unix formatted, comma-separated file containing a column for freesurfer_id 
#       (e.g. OAS30001_Freesurfer53_d0129)
# <directory_name> - A directory path (relative or absolute) to save the Freesurfer files to
# <xnat_central_username> - Your XNAT Central username used for accessing OASIS data on central.xnat.org
#       (you will be prompted for your password before downloading)
#
# This script organizes the files into folders like this:
#
# directory_name/OAS30001_MR_d0129/$FREESURFER_FOLDERS
#
#
# Last Updated: 1/26/2023
# Author: Sarah Keefe
#
#
unset module

# Authenticates credentials against Central and returns the cookie jar file name. USERNAME and
# PASSWORD must be set before calling this function.
#   USERNAME="foo"
#   PASSWORD="bar"
#   COOKIE_JAR=$(startSession)
startSession() {
    # Authentication to XNAT and store cookies in cookie jar file
    local COOKIE_JAR=.cookies-$(date +%Y%M%d%s).txt
    curl -k -s -u ${USERNAME}:${PASSWORD} --cookie-jar ${COOKIE_JAR} "https://central.xnat.org/data/JSESSION" > /dev/null
    echo ${COOKIE_JAR}
}

# Downloads a resource from a URL and stores the results to the specified path. The first parameter
# should be the destination path and the second parameter should be the URL.
download() {
    local OUTPUT=${1}
    local URL=${2}
    curl -H 'Expect:' --keepalive-time 2 -k --cookie ${COOKIE_JAR} -o ${OUTPUT} ${URL}
}

# Downloads a resource from a URL and stores the results to the specified path. The first parameter
# should be the destination path and the second parameter should be the URL. This function tries to
# resume a previously started but interrupted download.
continueDownload() {
    local OUTPUT=${1}
    local URL=${2}
    curl -H 'Expect:' --keepalive-time 2 -k --continue - --cookie ${COOKIE_JAR} -o ${OUTPUT} ${URL}
}

# Gets a resource from a URL.
get() {
    local URL=${1}
    curl -H 'Expect:' --keepalive-time 2 -k --cookie ${COOKIE_JAR} ${URL}
}

# Ends the user session.
endSession() {
    # Delete the JSESSION token - "log out"
    curl -i -k --cookie ${COOKIE_JAR} -X DELETE "https://central.xnat.org/data/JSESSION"
    rm -f ${COOKIE_JAR}
}

# usage instructions
if [ ${#@} == 0 ]; then
    echo ""
    echo "OASIS Freesurfer download script"
    echo ""
    echo "This script downloads Freesurfer files based on a list of session ids in a csv file. "
    echo ""   
    echo "Usage: $0 input_file.csv directory_name central_username scan_type"
    echo "<input_file>: A Unix formatted, comma separated file containing the following columns:"
    echo "    freesurfer_id (e.g. OAS30001_Freesurfer53_d0129)"
    echo "<directory_name>: Directory path to save Freesurfer files to"  
    echo "<xnat_central_username>: Your XNAT Central username used for accessing OASIS data (you will be prompted for your password)"  
else 
    # Get the input arguments
    INFILE=$1
    DIRNAME=$2
    USERNAME=$3

    # Create the directory if it doesn't exist yet
    if [ ! -d $DIRNAME ]
    then
        mkdir $DIRNAME
    fi

    # Read in password
    read -s -p "Enter your password for accessing OASIS data on XNAT Central:" PASSWORD

    echo ""

    COOKIE_JAR=$(startSession)

    # Read the file
    sed 1d $INFILE | while IFS=, read -r FREESURFER_ID; do

        # Get the subject ID from the first part of the experiment ID (OAS30001 from ID OAS30001_Freesurfer53_d0129)
        SUBJECT_ID=`echo $FREESURFER_ID | cut -d_ -f1`

        # Get the days from entry from the third part of the experiment ID (d0129 from ID OAS30001_Freesurfer53_d0129)
        DAYS_FROM_ENTRY=`echo $FREESURFER_ID | cut -d_ -f3`

        # combine to form the experiment label (OAS30001_MR_d0129)
        EXPERIMENT_LABEL=${SUBJECT_ID}_MR_${DAYS_FROM_ENTRY}


        # Set project in URL based on experiment ID
        # default to OASIS3
        PROJECT_ID=OASIS3
        # If the experiment ID provided starts with OASIS4 then use project=OASIS4 in the URL
        if [[ "${EXPERIMENT_ID}" == "OAS4"* ]]; then
            PROJECT_ID=OASIS4
        fi

        # Get a JSESSION for authentication to XNAT
        echo "Checking for Freesurfer ID ${FREESURFER_ID} associated with ${EXPERIMENT_LABEL}."

        # Set up the download URL and make a cURL call to download the requested scans in zip format
        download_url=https://central.xnat.org/data/archive/projects/${PROJECT_ID}/subjects/${SUBJECT_ID}/experiments/${EXPERIMENT_LABEL}/assessors/${FREESURFER_ID}/files?format=zip

        download $DIRNAME/$FREESURFER_ID.zip $download_url

        # Check the zip file to make sure we downloaded something
        # If the zip file is invalid, we didn't download a scan so there is probably no scan of that type
        # If the zip file is valid, unzip and rearrange the files
        if zip -Tq $DIRNAME/$FREESURFER_ID.zip > /dev/null; then
            # We found a successfully downloaded valid zip file

            echo "Downloaded a Freesurfer (${FREESURFER_ID}) from ${EXPERIMENT_LABEL}." 

            echo "Unzipping Freesurfer and rearranging files."

            # Unzip the downloaded file
            unzip $DIRNAME/$FREESURFER_ID.zip -d $DIRNAME

            # Rearrange the files so there are fewer subfolders
            # Move the main Freesurfer subfolder up 5 levels
            # Ends up like this:
            # directory_name/OAS30001_MR_d0129/freesurfer_folders
            # directory_name/OAS30001_MR_d0129/etc
            mv $DIRNAME/$FREESURFER_ID/out/resources/DATA/files/* $DIRNAME/.

            # Change permissions on the output files
            chmod -R u=rwX,g=rwX $DIRNAME/*

            # do this so we don't have to use rm -rf. 
            rmdir $DIRNAME/$FREESURFER_ID/out/resources/DATA/files
            rmdir $DIRNAME/$FREESURFER_ID/out/resources/DATA
            rmdir $DIRNAME/$FREESURFER_ID/out/resources
            rmdir $DIRNAME/$FREESURFER_ID/out
            rmdir $DIRNAME/$FREESURFER_ID

            # Remove the Freesurfer zip file that the files were moved from
            rm -r $DIRNAME/$FREESURFER_ID.zip
        else
            echo "Could not get Freesurfer ${FREESURFER_ID} in ${EXPERIMENT_LABEL}."           
        fi

    done < $INFILE

    endSession

fi