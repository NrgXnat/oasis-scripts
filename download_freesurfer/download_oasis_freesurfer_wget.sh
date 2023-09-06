#!/bin/bash
#
#================================================================
# download_oasis_freesurfer_wget.sh
#================================================================
#
# Usage: ./download_oasis_freesurfer_tar.sh <input_file.csv> <directory_name> <xnat_central_username>
# 
# Download Freesurfer files from OASIS3 or OASIS4 on XNAT Central and organize the files - uses "wget" instead of "curl"
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
        if [[ "${EXPERIMENT_LABEL}" == "OAS4"* ]]; then
            PROJECT_ID=OASIS4
        fi

        echo "Checking for Freesurfer ID ${FREESURFER_ID} associated with ${EXPERIMENT_LABEL}."

        # Set up the download URL and make a wget call to download the requested scans in tar.gz format
        download_url=https://central.xnat.org/data/archive/projects/${PROJECT_ID}/subjects/${SUBJECT_ID}/experiments/${EXPERIMENT_LABEL}/assessors/${FREESURFER_ID}/files?format=tar.gz

        wget --http-user=$USERNAME --http-password=$PASSWORD --auth-no-challenge --no-check-certificate -O $DIRNAME/$FREESURFER_ID.tar.gz "$download_url"

        # Check the tar.gz file to make sure we downloaded something
        # If the tar.gz file is invalid, we didn't download a scan so there is probably no scan of that type
        # If the tar.gz file is valid, untar and rearrange the files
        if tar tf $DIRNAME/$FREESURFER_ID.tar.gz &> /dev/null; then
            # We found a successfully downloaded valid tar.gz  file

            echo "Downloaded a Freesurfer (${FREESURFER_ID}) from ${EXPERIMENT_LABEL}." 

            echo "Unzipping Freesurfer and rearranging files."

            # Untar the downloaded file
            tar -xzvC $DIRNAME -f $DIRNAME/$FREESURFER_ID.tar.gz

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

            # Remove the Freesurfer tar.gz file that the files were moved from
            rm -r $DIRNAME/$FREESURFER_ID.tar.gz
        else
            echo "Could not get Freesurfer ${FREESURFER_ID} in ${EXPERIMENT_LABEL}."           
        fi

        echo "Done with ${FREESURFER_ID}."

    done < $INFILE
fi