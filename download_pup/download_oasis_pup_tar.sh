#!/bin/bash
#
#================================================================
# download_oasis_pup_tar.sh
#================================================================
#
# Usage: ./download_oasis_pup_tar.sh <input_file.csv> <directory_name> <nitrc_ir_username>
# 
# Download PET Unified Pipeline (PUP) files from OASIS3 or OASIS4 on NITRC IR and organize the files - uses "tar" instead of "zip"
#
# Required inputs:
# <input_file.csv> - A Unix formatted, comma-separated file containing a column for pup_id 
#       (e.g. OAS30001_AV45_PUPTIMECOURSE_d2430)
# <directory_name> - A directory path (relative or absolute) to save the PUP files to
# <nitrc_ir_username> - Your NITRC IR username used for accessing OASIS data on nitrc.org/ir
#       (you will be prompted for your password before downloading)
# <tau_project_id> - (optional) if you are downloading from OASIS3_AV1451 or OASIS3_AV1451L, 
#       specify which project to download from. Other OASIS projects will be chosen automatically based on session label."
#
# This script organizes the files into folders like this:
#
# directory_name/OAS30001_AV45_PUPTIMECOURSE_d2430/$PUP_FOLDERS
#
#
# Last Updated: 6/27/2024
# Author: Sarah Keefe
#
#
unset module

# Authenticates credentials against NITRC and returns the cookie jar file name. USERNAME and
# PASSWORD must be set before calling this function.
#   USERNAME="foo"
#   PASSWORD="bar"
#   COOKIE_JAR=$(startSession)
startSession() {
    # Authentication to XNAT and store cookies in cookie jar file
    local COOKIE_JAR=.cookies-$(date +%Y%M%d%s).txt
    curl -k -s -u ${USERNAME}:${PASSWORD} --cookie-jar ${COOKIE_JAR} "https://www.nitrc.org/ir/data/JSESSION" > /dev/null
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
    curl -i -k --cookie ${COOKIE_JAR} -X DELETE "https://www.nitrc.org/ir/data/JSESSION"
    rm -f ${COOKIE_JAR}
}

# usage instructions
if [ ${#@} == 0 ]; then
    echo ""
    echo "OASIS PUP download script (tar version)"
    echo ""
    echo "This script downloads PUP files based on a list of session ids in a csv file. "
    echo ""   
    echo "Usage: $0 input_file.csv directory_name nitrc_username scan_type"
    echo "<input_file>: A Unix formatted, comma separated file containing the following columns:"
    echo "    pup_id (e.g. OAS30001_AV45_PUPTIMECOURSE_d2430)"
    echo "<directory_name>: Directory path to save Freesurfer files to"  
    echo "<nitrc_ir_username>: Your NITRC IR username used for accessing OASIS data (you will be prompted for your password)"
    echo "<tau_project_id>: (optional) if you are downloading from OASIS3_AV1451 or OASIS3_AV1451L, specify which project to download from. Other OASIS projects will be chosen automatically based on session label."    
else 

    # Get the input arguments
    INFILE=$1
    DIRNAME=$2
    USERNAME=$3
    AV1451_PROJ_ID=$4

    # Create the directory if it doesn't exist yet
    if [ ! -d $DIRNAME ]
    then
        mkdir $DIRNAME
    fi

    # Read in password
    read -s -p "Enter your password for accessing OASIS data on NITRC IR:" PASSWORD

    echo ""

    COOKIE_JAR=$(startSession)

    # Read the file
    sed 1d $INFILE | while IFS=, read -r PUP_ID; do

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

        echo "Checking for PUP ID ${PUP_ID} associated with ${EXPERIMENT_LABEL}."

        # Set up the download URL and make a cURL call to download the requested scans in tar.gz format
        download_url=https://www.nitrc.org/ir/data/archive/projects/${PROJECT_ID}/subjects/${SUBJECT_ID}/experiments/${EXPERIMENT_LABEL}/assessors/${PUP_ID}/files?format=tar.gz

        download $DIRNAME/$PUP_ID.tar.gz $download_url

        # Check the tar.gz file to make sure we downloaded something
        # If the tar.gz file is invalid, we didn't download a scan so there is probably no scan of that type
        # If the tar.gz file is valid, untar and rearrange the files
        if tar tf $DIRNAME/$PUP_ID.tar.gz &> /dev/null; then
            # We found a successfully downloaded valid tar.gz file

            echo "Downloaded a PUP (${PUP_ID}) from ${EXPERIMENT_LABEL}." 

            echo "Unzipping PUP zip and rearranging files."

            # Untar the downloaded file
            tar -xzvC $DIRNAME -f $DIRNAME/$PUP_ID.tar.gz

            # Rearrange the files so there are fewer subfolders
            # Move the main PET folder contents up 5 levels
            # Ends up like this:
            # directory_name/OAS30001_AV45_PUPTIMECOURSE_d2430/pet_files
            # directory_name/OAS30001_AV45_PUPTIMECOURSE_d2430/etc
            mkdir -p $DIRNAME/$PUP_ID
            mv $DIRNAME/$PUP_ID/out/resources/DATA/files/pet_proc/* $DIRNAME/$PUP_ID

            # Change permissions on the output files
            chmod -R u=rwX,g=rwX $DIRNAME/$PUP_ID/*

            # Remove the unzipped directory structure
            rm -rf $DIRNAME/$PUP_ID/out

            # Remove the Freesurfer tar.gz file that the files were moved from
            rm -r $DIRNAME/$PUP_ID.tar.gz
        else
            echo "Could not download PUP ${PUP_ID} in ${EXPERIMENT_LABEL}."           
        fi

        echo "Done with ${PUP_ID}."

    done < $INFILE

    endSession

fi