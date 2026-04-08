#!/bin/bash
#
#================================================================
# download_genisis_scans.sh
#================================================================
#
# Usage: ./download_genisis_scans.sh <input_file.csv> <directory_name> <nitrc_ir_username> <project_id> <scan_type>
# 
# Download scans of a specified type from XNAT on NITRC IR and organize the files
#
# Required inputs:
# <input_file.csv> - A Unix formatted, comma-separated file containing a column for experiment_id 
#       (e.g. OAS30001_MR_d0129)
# <directory_name> - A directory path (relative or absolute) to save the scan files to
# <nitrc_ir_username> - Your NITRC IR username used for accessing OASIS data on nitrc.org/ir
#       (you will be prompted for your password before downloading)
# <project_id> - The Project ID (e.g. GENISIS, ERICH)
# <scan_type> - (Optional) The scan type of the scan you want to download. (e.g. T1w, angio, bold, fieldmap, FLAIR)
#       You can also enter multiple scan types separated by a comma with no whitespace (e.g. T2w,swi,bold)
#       Without this argument, all scans for the given experiment_id will be downloaded.
#
# This script organizes the files into folders like this:
# ./download_genisis_scans.sh /gscratch/stf/juampablo/icdkp_datasets/GENISIS_subjects.csv /gscratch/stf/juampablo/icdkp_datasets/GENISIS juampablo GENISIS
# directory_name/GENISIS_02_20115_1_CT/4/GENISIS_02_20115_1_CT_4.json
# directory_name/GENISIS_02_20115_1_CT/4/GENISIS_02_20115_1_CT_4.nii
# directory_name/GENISIS_02_20115_1_CT/4/GENISIS_02_20115_1_CT_4_<xxxxx>.dcm
#
# Last Updated: 7/10/2024
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
    if ! curl -f -k -s -u ${USERNAME}:${PASSWORD} --cookie-jar ${COOKIE_JAR} "https://strokeimaging.wustl.edu/data/JSESSION" > /dev/null; then
        return 1
    fi
    echo ${COOKIE_JAR}
    return 0
}

# Takes in a string intended as a value in a URL, returns that string with all illegal characters escaped with percent-encoding
# NOTE: When calling this function, make sure to feed the variable as a
# string, i.e. `escape_chars_for_URL "${variable}"` for correct text handling from bash and sed
escape_chars_for_URL() {
    local input=${1}
    
    # escape characters
    output=`echo "${input}" | sed -e 's/%/%25/g;' | sed -e 's/ /%20/g; s/</%3C/g; s/>/%3E/g; s/#/%23/g; s/+/%2B/g; s/{/%7B/g; s/}/%7D/g; s/|/%7C/g; s/\\\/%5C/g; s/\^/%5E/g; s/~/%7E/g; s/\[/%5B/g; s/\]/%5D/g; s/\`/%60/g; s/;/%3B/g; s/\//%2F/g; s/?/%3F/g; s/:/%3A/g; s/@/%40/g; s/=/%3D/g; s/&/%26/g; s/\\$/%24/g'`

    echo ${output}
}

# Downloads a resource from a URL and stores the results to the specified path. The first parameter
# should be the destination path and the second parameter should be the URL.
download() {
    local OUTPUT=${1}
    local URL=${2}
    curl -H 'Expect:' --keepalive-time 2 -k --cookie ${COOKIE_JAR} -C - -o ${OUTPUT} ${URL}
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
    curl -i -k --cookie ${COOKIE_JAR} -X DELETE "https://strokeimaging.wustl.edu/data/JSESSION"
    rm -f ${COOKIE_JAR}
}

# usage instructions
if [ ${#@} == 0 ]; then
    echo ""
    echo "OASIS scan download script"
    echo ""
    echo "This script downloads scans of the specified scan type based on a list of session ids in a csv file. "
    echo ""   
    echo "Usage: $0 input_file.csv directory_name nitrc_username project_id scan_type"
    echo "<input_file>: A Unix formatted, comma separated file containing the following columns:"
    echo "    experiment_id (e.g. OAS30001_MR_d0129)"
    echo "<directory_name>: Directory path to save scan files to"  
    echo "<nitrc_ir_username>: Your NITRC IR username used for accessing OASIS data (you will be prompted for your password)"   
    echo "<project_id>: The Project ID (e.g. GENISIS, ERICH)"
    echo "<scan_type>: (Optional) scan type you would like to download (e.g. T1w). You can also enter multiple comma-separated scan types (e.g. swi,T2w). Without this argument, all scans for the given experiment_id will be downloaded. "      
else 

    # Get the input arguments
    INFILE=$1
    DIRNAME=$2
    USERNAME=`echo $3 | tr 'A-Z' 'a-z'`
    PROJECT_ID=$4

    if [ $# -ge 5 ]
    then
        SCANTYPE=$5
    else
        SCANTYPE=ALL
    fi

    if [[ ${SCANTYPE} == "" ]]; then
        SCANTYPE=ALL
    fi

    # Create the directory if it doesn't exist yet
    if [ ! -d $DIRNAME ]
    then
        mkdir -p $DIRNAME
    fi

    # Read in password
    read -s -p "Enter your password for accessing OASIS data on NITRC IR:" PASSWORD

    echo ""

    # escape username and password
    USERNAME=`escape_chars_for_URL "${USERNAME}"`
    PASSWORD=`escape_chars_for_URL "${PASSWORD}"`

    if ! COOKIE_JAR=$(startSession); then
        echo "Error starting session.  Maybe a bad username/password?"
        exit 1
    fi

    # Read the file
    sed 1d $INFILE | while IFS=, read -r EXPERIMENT_ID; do

        # Clean Windows carriage returns
        EXPERIMENT_ID=$(echo $EXPERIMENT_ID | tr -d '\r')

        # Get the subject ID from the first part of the experiment ID (OAS30001 from ID OAS30001_MR_d0129)
        # SUBJECT_ID=`echo $EXPERIMENT_ID | cut -d_ -f1`
        SUBJECT_ID=`echo $EXPERIMENT_ID | cut -d_ -f1,2,3`

        if ! [ $SCANTYPE = "ALL" ]
        then
            echo "Checking for a ${SCANTYPE} scan for ${EXPERIMENT_ID}."
        else
            echo "Downloading all scans for ${EXPERIMENT_ID}."
        fi

        # Set up the download URL and make a cURL call to download the requested scans in zip format
        download_url=https://strokeimaging.wustl.edu/data/archive/projects/${PROJECT_ID}/subjects/${SUBJECT_ID}/experiments/${EXPERIMENT_ID}/scans/${SCANTYPE}/files?format=zip
        echo $download_url
        download $DIRNAME/$EXPERIMENT_ID.zip $download_url

        # Check the zip file to make sure we downloaded something
        # If the zip file is invalid, we didn't download a scan so there is probably no scan of that type
        # If the zip file is valid, unzip and rearrange the files
        if zip -Tq $DIRNAME/$EXPERIMENT_ID.zip > /dev/null; then
            # We found a successfully downloaded valid zip file

            if ! [ $SCANTYPE = "ALL" ]
            then
                echo "Found a ${SCANTYPE} scan for ${EXPERIMENT_ID}."
            else
                echo "Downloaded all scans for ${EXPERIMENT_ID}."
            fi  

            echo "Unzipping scan(s) and rearranging files."

            # Unzip the downloaded file
            unzip -o $DIRNAME/$EXPERIMENT_ID.zip -d $DIRNAME

            # Rearrange the files so there are fewer subfolders
            # Ends up like this:
            # directory_name/OAS30001_MR_d0129/anat1/file.json
            # directory_name/OAS30001_MR_d0129/anat1/file.nii.gz
            for single_scan in $DIRNAME/$EXPERIMENT_ID/scans/*/ ; do
                if [ -d ${single_scan} ]; then
                    scan_name_all=`echo $single_scan | rev | cut -d/ -f2 | rev`
                    scan_name=`echo $scan_name_all | cut -d- -f1`

                    mkdir -p $DIRNAME/$EXPERIMENT_ID/$scan_name
                    mv $DIRNAME/$EXPERIMENT_ID/scans/$scan_name_all/resources/*/files/* $DIRNAME/$EXPERIMENT_ID/$scan_name/. 2>/dev/null

                    # Change permissions on the output files
                    chmod -R u=rwX,g=rwX $DIRNAME/$EXPERIMENT_ID/$scan_name/* 2>/dev/null
                fi
            done

            # Remove the empty scans folder that the files were moved from
            rm -r $DIRNAME/$EXPERIMENT_ID/scans 2>/dev/null
        else
            if ! [ $SCANTYPE = "ALL" ]
            then
                echo "Did not find a ${SCANTYPE} scan for ${EXPERIMENT_ID}."
            else
                echo "Could not download all scans for ${EXPERIMENT_ID}."
            fi            
        fi

        # Remove the original zip file
        rm -f $DIRNAME/$EXPERIMENT_ID.zip

        echo "Done with ${EXPERIMENT_ID}."

    done < $INFILE

    endSession
fi