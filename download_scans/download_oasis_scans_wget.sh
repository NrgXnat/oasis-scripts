#!/bin/bash
#
#================================================================
# download_oasis_scans_wget.sh
#================================================================
#
# Usage: ./download_oasis_scans.sh <input_file.csv> <directory_name> <nitrc_ir_username> <scan_type>
# 
# Download scans of a specified type from OASIS3 or OASIS4 on NITRC IR and organize the files - uses "wget" instead of "curl"
#
# Required inputs:
# <input_file.csv> - A Unix formatted, comma-separated file containing a column for experiment_id 
#       (e.g. OAS30001_MR_d0129)
# <directory_name> - A directory path (relative or absolute) to save the scan files to
# <nitrc_ir_username> - Your NITRC IR username used for accessing OASIS data on nitrc.org/ir
#       (you will be prompted for your password before downloading)
# <scan_type> - (Optional) The scan type of the scan you want to download. (e.g. T1w, angio, bold, fieldmap, FLAIR)
#       You can also enter multiple scan types separated by a comma with no whitespace (e.g. T2w,swi,bold)
#       Without this argument, all scans for the given experiment_id will be downloaded.
# <tau_project_id> - (optional) if you are downloading from OASIS3_AV1451 or OASIS3_AV1451L, 
#       specify which project to download from. Other OASIS projects will be chosen automatically based on session label.
#       If you want to use this option but not specify a particular <scan_type> option, you must specify scan_type as "ALL".
#
# This script organizes the files into folders like this:
#
# directory_name/OAS30001_MR_d0129/anat1/file.json
# directory_name/OAS30001_MR_d0129/anat1/file.nii.gz
# directory_name/OAS30001_MR_d0129/anat4/file.json
# directory_name/OAS30001_MR_d0129/anat4/file.nii.gz
#
#
# Last Updated: 7/12/2024
# Author: Sarah Keefe
#
#
unset module

# usage instructions
if [ ${#@} == 0 ]; then
    echo ""
    echo "OASIS scan download script"
    echo ""
    echo "This script downloads scans of the specified scan type based on a list of session ids in a csv file. "
    echo ""   
    echo "Usage: $0 input_file.csv directory_name nitrc_username scan_type"
    echo "<input_file>: A Unix formatted, comma separated file containing the following columns:"
    echo "    experiment_id (e.g. OAS30001_MR_d0129)"
    echo "<directory_name>: Directory path to save scan files to"  
    echo "<nitrc_ir_username>: Your NITRC IR username used for accessing OASIS data (you will be prompted for your password)"   
    echo "<scan_type>: (Optional) scan type you would like to download (e.g. T1w). You can also enter multiple comma-separated scan types (e.g. swi,T2w). Without this argument, all scans for the given experiment_id will be downloaded. "  
    echo "<tau_project_id>: (optional) if you are downloading from OASIS3_AV1451 or OASIS3_AV1451L, specify which project to download from. Other OASIS projects will be chosen automatically based on session label. If you want to use this option but not specify a particular <scan_type> option, you must specify the <scan_type> input as \"ALL\"."  
else 

    # Get the input arguments
    INFILE=$1
    DIRNAME=$2
    USERNAME=$3

    if [ $# -ge 4 ]
    then
        SCANTYPE=$4
        AV1451_PROJ_ID=$5
    else
        SCANTYPE=ALL
    fi

    if [[ ${SCANTYPE} == "" ]]; then
        SCANTYPE=ALL
    fi

    # Create the directory if it doesn't exist yet
    if [ ! -d $DIRNAME ]
    then
        mkdir $DIRNAME
    fi

    # Read in password
    read -s -p "Enter your password for accessing OASIS data on NITRC IR:" PASSWORD

    echo ""

    COOKIES_FILE=.cookies-$(date +%Y%M%d%s).txt

    if ! wget --http-user=$USERNAME --http-password=$PASSWORD --auth-no-challenge --no-check-certificate --save-cookies ${COOKIES_FILE} --keep-session-cookies -O /dev/null https://www.nitrc.org/ir/data/JSESSION; then
        echo "Error starting session.  Maybe a bad username/password?"
        rm -f ${COOKIES_FILE}
        exit 1
    fi

    # Read the file
    sed 1d $INFILE | while IFS=, read -r EXPERIMENT_ID; do

        # Get the subject ID from the first part of the experiment ID (OAS30001 from ID OAS30001_MR_d0129)
        SUBJECT_ID=`echo $EXPERIMENT_ID | cut -d_ -f1`

        if ! [ $SCANTYPE = "ALL" ]
        then
            echo "Checking for a ${SCANTYPE} scan for ${EXPERIMENT_ID}."
        else
            echo "Downloading all scans for ${EXPERIMENT_ID}."
        fi

        # Set project in URL based on experiment ID
        # default to OASIS3
        PROJECT_ID=OASIS3
        # If the experiment ID provided starts with OASIS4 then use project=OASIS4 in the URL
        if [[ "${EXPERIMENT_ID}" == "OAS4"* ]]; then
            PROJECT_ID=OASIS4
        fi

        # If the experiment ID provided starts with OAS3XXXXX_AV1451 then check if "AV1451_PROJ_ID" is set
        # If so, use that as the project ID. Otherwise use project=OASIS3_AV1451 in the URL
        if [[ "${EXPERIMENT_ID}" == "OAS3"*"_AV1451"* ]]; then
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

        # Set up the download URL and make a cURL call to download the requested scans in tar.gz format
        download_url=https://www.nitrc.org/ir/data/archive/projects/${PROJECT_ID}/subjects/${SUBJECT_ID}/experiments/${EXPERIMENT_ID}/scans/${SCANTYPE}/files?format=tar.gz

        wget --load-cookies ${COOKIES_FILE} --no-check-certificate -O $DIRNAME/$EXPERIMENT_ID.tar.gz "$download_url"

        # Check the tar.gz file to make sure we downloaded something
        # If the tar.gz file is invalid, we didn't download a scan so there is probably no scan of that type
        # If the tar.gz file is valid, untar and rearrange the files        
        if ! tar tf $DIRNAME/$EXPERIMENT_ID.tar.gz &> /dev/null; then

            if ! [ $SCANTYPE = "ALL" ]
            then
                echo "Did not find a ${SCANTYPE} scan for ${EXPERIMENT_ID}."
            else
                echo "Could not download all scans for ${EXPERIMENT_ID}."
            fi  

        else

           # We found a successfully downloaded valid tar.gz file

            if ! [ $SCANTYPE = "ALL" ]
            then
                echo "Found a ${SCANTYPE} scan for ${EXPERIMENT_ID}."
            else
                echo "Downloaded all scans for ${EXPERIMENT_ID}."
            fi  

            echo "Decompressing scan(s) and rearranging files."

            # Untar the downloaded file
            tar -xzvC $DIRNAME -f $DIRNAME/$EXPERIMENT_ID.tar.gz

            # Rearrange the files so there are fewer subfolders
            # Ends up like this:
            # directory_name/OAS30001_MR_d0129/anat1/file.json
            # directory_name/OAS30001_MR_d0129/anat1/file.nii.gz
            for single_scan in $DIRNAME/$EXPERIMENT_ID/scans/*/ ; do
                if [ -d ${single_scan} ]; then
                    scan_name_all=`echo $single_scan | rev | cut -d/ -f2 | rev`
                    scan_name=`echo $scan_name_all | cut -d- -f1`

                    mkdir $DIRNAME/$EXPERIMENT_ID/$scan_name
                    mv $DIRNAME/$EXPERIMENT_ID/scans/$scan_name_all/resources/*/files/* $DIRNAME/$EXPERIMENT_ID/$scan_name/.

                    # Change permissions on the output files
                    chmod -R u=rwX,g=rwX $DIRNAME/$EXPERIMENT_ID/$scan_name/*                    
                fi
            done

            # Remove the empty scans folder that the files were moved from
            rm -rf $DIRNAME/$EXPERIMENT_ID/scans

        fi

        # # Remove the original tar.gz file
        rm -f $DIRNAME/$EXPERIMENT_ID.tar.gz

        echo "Done with ${EXPERIMENT_ID}."

    done < $INFILE

    wget -O /dev/null --method=DELETE --load-cookies ${COOKIES_FILE} --no-check-certificate https://www.nitrc.org/ir/data/JSESSION
    rm -f ${COOKIES_FILE}

fi
