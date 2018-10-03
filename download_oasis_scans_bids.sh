#!/bin/bash
#
#================================================================
# download_oasis_scans_bids.sh
#================================================================
#
# Usage: ./download_oasis_scans_bids.sh <input_file.csv> <directory_name> <xnat_central_username> <scan_type> -b
# 
# Download scans of a specified type from OASIS3 on XNAT Central and organize the files into BIDS format
#
# Required inputs:
# <input_file.csv> - A Unix formatted, comma-separated file containing a column for experiment_id 
#       (e.g. OAS30001_MR_d0129)
# <directory_name> - A directory path (relative or absolute) to save the scan files to
# <xnat_central_username> - Your XNAT Central username used for accessing OASIS data on central.xnat.org
#       (you will be prompted for your password before downloading)
# 
# Optional inputs:
# <scan_type> - (Optional) The scan type of the scan you want to download. (e.g. T1w, angio, bold, fieldmap, FLAIR)
#       You can also enter multiple scan types separated by a comma with no whitespace (e.g. T2w,swi,bold)
#       Without this argument, all scans for the given experiment_id will be downloaded.
#
#
# By default this script organizes the files into folders like this:
#
# directory_name/sub-subjectname/ses-sessionname/anat/sub-subjectname_T1w.json
# directory_name/sub-subjectname/ses-sessionname/anat/sub-subjectname_T1w.nii.gz
# directory_name/sub-subjectname/ses-sessionname/anat/sub-subjectname_T2w.json
# directory_name/sub-subjectname/ses-sessionname/anat/sub-subjectname_T2w.nii.gz
# directory_name/sub-subjectname/ses-sessionname/func/sub-subjectname_bold.json
# directory_name/sub-subjectname/ses-sessionname/func/sub-subjectname_bold.nii.gz
# etc.
#
# Last Updated: 10/3/2018
# Author: Sarah Keefe
#
#
unset module


function move_to_bids () {

    DIRNAME=$1
    EXPERIMENT_ID=$2

    # BIDSifying
    # example scan id name: sub-OAS30001_ses-d0129_run-01_T1w.json
    # another example: sub-OAS30001_­ses-d0757_­acq-TSE_­T2w.­json
    # and: sub-OAS30001_­ses-d0757_­task-rest_­run-02_­bold.­nii.­gz 

    # set up destination folders by scan type
    # map the scan types to bids types
    dest_T2w=anat
    dest_T1w=anat
    dest_FLAIR=anat
    dest_T2star=anat
    dest_angio=anat
    dest_minIP=swi
    dest_GRE=swi
    dest_swi=swi
    dest_asl=func
    dest_bold=func
    dest_fieldmap=fmap
    dest_dti=dti
    dest_pet=pet
    dest_dwi=dwi


    for SCAN_FOLDER_PATH in $DIRNAME/$EXPERIMENT_ID/scans/*; do

        # anat1-T1w
        SCAN_FOLDERNAME=`echo $SCAN_FOLDER_PATH | rev | cut -d/ -f1`
        SCAN_FOLDERNAME=`echo $SCAN_FOLDERNAME | rev`

        for SCAN_FILE_PATH in $DIRNAME/$EXPERIMENT_ID/scans/$SCAN_FOLDERNAME/resources/*/files/*; do

            # anat1
            SCAN_NAME=`echo $SCAN_FOLDERNAME | cut -d- -f1`
            # T1w
            SCAN_TYPE=`echo $SCAN_FOLDERNAME | cut -d- -f2`

            # sub-OAS30001_ses-d0757_minIP.json
            SCAN_FILENAME=`echo $SCAN_FILE_PATH | rev | cut -d/ -f1`
            SCAN_FILENAME=`echo $SCAN_FILENAME | rev`

            # sub-OAS30001
            scan_subject_sub=`echo $SCAN_FILENAME | cut -d_ -f1`
            # get just OAS30001
            scan_subject=`echo $scan_subject_sub | cut -d- -f2`

            # ses-d0129
            scan_session_ses=`echo $SCAN_FILENAME | cut -d_ -f2`
            # d0129
            scan_session=`echo $scan_session_ses | cut -d- -f2`

            # Create the folder structure based on the labels gathered
            subject_folder=sub-${scan_subject}
            session_folder=ses-${scan_session}

            mkdir -p $DIRNAME/$subject_folder/$session_folder

            new_path=
            new_basepath=$DIRNAME/$subject_folder/$session_folder

            if [ $SCAN_TYPE = "T1w" ]
            then
                new_path=$new_basepath/$dest_T1w
                mkdir -p $new_path
                mv $SCAN_FILE_PATH $new_path/.
            elif [ $SCAN_TYPE = "T2w" ]
            then                        
                new_path=$new_basepath/$dest_T2w
                mkdir -p $new_path
                mv $SCAN_FILE_PATH $new_path/.
            elif [ $SCAN_TYPE = "FLAIR" ]
            then                        
                new_path=$new_basepath/$dest_FLAIR
                mkdir -p $new_path
                mv $SCAN_FILE_PATH $new_path/.
            elif [ $SCAN_TYPE = "T2star" ]
            then                        
                new_path=$new_basepath/$dest_T2star
                mkdir -p $new_path
                mv $SCAN_FILE_PATH $new_path/.
            elif [ $SCAN_TYPE = "angio" ]
            then                        
                new_path=$new_basepath/$dest_angio
                mkdir -p $new_path
                mv $SCAN_FILE_PATH $new_path/.
            elif [ $SCAN_TYPE = "minIP" ]
            then                        
                new_path=$new_basepath/$dest_minIP
                mkdir -p $new_path
                mv $SCAN_FILE_PATH $new_path/.
            elif [ $SCAN_TYPE = "GRE" ]
            then                        
                new_path=$new_basepath/$dest_GRE
                mkdir -p $new_path
                mv $SCAN_FILE_PATH $new_path/.
            elif [ $SCAN_TYPE = "swi" ]
            then                        
                new_path=$new_basepath/$dest_swi
                mkdir -p $new_path
                mv $SCAN_FILE_PATH $new_path/.
            elif [ $SCAN_TYPE = "asl" ]
            then                        
                new_path=$new_basepath/$dest_asl
                mkdir -p $new_path
                mv $SCAN_FILE_PATH $new_path/.
            elif [ $SCAN_TYPE = "bold" ]
            then                        
                new_path=$new_basepath/$dest_bold
                mkdir -p $new_path
                mv $SCAN_FILE_PATH $new_path/.
            elif [ $SCAN_TYPE = "fieldmap" ]
            then                        
                new_path=$new_basepath/$dest_fieldmap
                mkdir -p $new_path
                mv $SCAN_FILE_PATH $new_path/.
            elif [ $SCAN_TYPE = "dti" ]
            then                        
                new_path=$new_basepath/$dest_dti
                mkdir -p $new_path
                mv $SCAN_FILE_PATH $new_path/.
            elif [ $SCAN_TYPE = "pet" ]
            then                        
                new_path=$new_basepath/$dest_pet
                mkdir -p $new_path
                mv $SCAN_FILE_PATH $new_path/.
            elif [ $SCAN_TYPE = "dwi" ]
            then                        
                new_path=$new_basepath/$dest_dwi
                mkdir -p $new_path
                mv $SCAN_FILE_PATH $new_path/.                        
            fi

        done


    done
}

function do_unzip () {

    SCANTYPE=$1
    EXPERIMENT_ID=$2
    DIRNAME=$3
    SUBJECT_ID=$4

    echo "Got a complete file for ${EXPERIMENT_ID}. Unzipping and organizing the files."

    # We found a successfully downloaded valid tar.gz file
    if ! [ $SCANTYPE = "ALL" ]
    then
        echo "Found a ${SCANTYPE} scan for ${EXPERIMENT_ID}."
    else
        echo "Downloaded all scans for ${EXPERIMENT_ID}."
    fi  

    echo "Unzipping scan(s) and rearranging files."

    # Untar the downloaded file
    tar -xzvC $DIRNAME -f $DIRNAME/$EXPERIMENT_ID.tar.gz

}


# usage instructions
if [ ${#@} == 0 ]; then
    echo ""
    echo "OASIS scan download script - BIDS format"
    echo ""
    echo "This script downloads scans of the specified scan type based on a list of session ids in a csv file. Uses the BIDS file format."
    echo ""   
    echo "Usage: $0 input_file.csv directory_name central_username scan_type"
    echo "<input_file>: A Unix formatted, comma separated file containing the following columns:"
    echo "    experiment_id (e.g. OAS30001_MR_d0129)"
    echo "<directory_name>: Directory path to save scan files to"  
    echo "<xnat_central_username>: Your XNAT Central username used for accessing OASIS data (you will be prompted for your password)"   
    echo "<scan_type>: (Optional) scan type you would like to download (e.g. T1w). You can also enter multiple comma-separated scan types (e.g. swi,T2w). Without this argument, all scans for the given experiment_id will be downloaded. "   
else 

    # Get the input arguments
    INFILE=$1
    DIRNAME=$2
    USERNAME=$3

    # set a number of times to re-try the download
    retry_count=1

    if [ $# -ge 4 ]
    then
        SCANTYPE=$4
    else
        SCANTYPE=ALL
    fi

    # Create the directory if it doesn't exist yet
    if [ ! -d $DIRNAME ]
    then
        mkdir $DIRNAME
    fi

    # Read in password
    read -s -p "Enter your password for accessing OASIS data on XNAT Central:" PASSWORD

    echo ""

    # Read the file
    sed 1d $INFILE | while IFS=, read -r EXPERIMENT_ID; do

        # Get the subject ID from the first part of the experiment ID (OAS30001 from ID OAS30001_MR_d0129)
        SUBJECT_ID=`echo $EXPERIMENT_ID | cut -d_ -f1`

        if [ ! $SCANTYPE = "ALL" ]
        then
            echo "Checking for a ${SCANTYPE} scan for ${EXPERIMENT_ID}."
        else
            echo "Downloading all scans for ${EXPERIMENT_ID}."
        fi

        # Set up the download URL and make a wget call to download the requested scans in tar.gz format
        download_url=https://central.xnat.org/data/archive/projects/OASIS3/subjects/${SUBJECT_ID}/experiments/${EXPERIMENT_ID}/scans/${SCANTYPE}/files?format=tar.gz

        wget -S --http-user=$USERNAME --http-password=$PASSWORD --auth-no-challenge --no-check-certificate -O $DIRNAME/$EXPERIMENT_ID.tar.gz "$download_url"

        # Check the tar.gz file to make sure we downloaded something
        # If the tar.gz file is invalid, we didn't download a scan so there is probably no scan of that type
        # If the tar.gz file is valid, untar and rearrange the files
        if tar tf $DIRNAME/$EXPERIMENT_ID.tar.gz &> /dev/null; then

            do_unzip $SCANTYPE $EXPERIMENT_ID $DIRNAME $SUBJECT_ID

            move_to_bids $DIRNAME $EXPERIMENT_ID

            # Remove the empty scans folder that the files were moved from
            rm -r $DIRNAME/$EXPERIMENT_ID

            # Grab the dataset_description file and put it in the session directory
            # Set up the URL and make a wget call to download the dataset_description file
            dataset_description_url=https://central.xnat.org/data/archive/projects/OASIS3/subjects/${SUBJECT_ID}/experiments/${EXPERIMENT_ID}/resources/BIDS/files/dataset_description.json

            wget -S --http-user=$USERNAME --http-password=$PASSWORD --auth-no-challenge --no-check-certificate -O $DIRNAME/$subject_folder/$session_folder/dataset_description.json "$dataset_description_url"

        else
            # retry loop
            # first retry - use wget --continue to continue a broken download

            echo "Downloaded an incomplete file for ${EXPERIMENT_ID}. Retrying (${retry_count} of 5 retries)."

            wget -S --continue --http-user=$USERNAME --http-password=$PASSWORD --auth-no-challenge --no-check-certificate -O $DIRNAME/$EXPERIMENT_ID.tar.gz "$download_url"

            while ! tar tf $DIRNAME/$EXPERIMENT_ID.tar.gz &> /dev/null; do
                
                if [ $retry_count -lt 6 ]; then

                    echo "Downloaded an incomplete file for ${EXPERIMENT_ID}. Retrying (${retry_count} of 5 retries)."

                    retry_count=$retry_count+1

                    wget --continue --http-user=$USERNAME --http-password=$PASSWORD --auth-no-challenge --no-check-certificate -O $DIRNAME/$EXPERIMENT_ID.tar.gz "$download_url"

                else
                    break
                fi

                if tar tf $DIRNAME/$EXPERIMENT_ID.tar.gz &> /dev/null; then
                    break
                fi

            done

            if tar tf $DIRNAME/$EXPERIMENT_ID.tar.gz &> /dev/null; then

                do_unzip $SCANTYPE $EXPERIMENT_ID $DIRNAME $SUBJECT_ID

                move_to_bids $DIRNAME $EXPERIMENT_ID

                # Remove the empty scans folder that the files were moved from
                rm -r $DIRNAME/$EXPERIMENT_ID

                # Grab the dataset_description file and put it in the session directory
                # Set up the URL and make a wget call to download the dataset_description file
                dataset_description_url=https://central.xnat.org/data/archive/projects/OASIS3/subjects/${SUBJECT_ID}/experiments/${EXPERIMENT_ID}/resources/BIDS/files/dataset_description.json

                wget --http-user=$USERNAME --http-password=$PASSWORD --auth-no-challenge --no-check-certificate -O $DIRNAME/$subject_folder/$session_folder/dataset_description.json "$dataset_description_url"
            else
                if [ ! $SCANTYPE = "ALL" ]
                then
                    echo "Could not complete the scan download. Either did not find a ${SCANTYPE} scan for ${EXPERIMENT_ID}, or the download failed."
                else
                    echo "Could not complete the scan download. Either could not find any scans for ${EXPERIMENT_ID}, or the download failed."
                fi  
            fi
        fi

        # Remove the original tar.gz file
        rm $DIRNAME/$EXPERIMENT_ID.tar.gz

        echo "Done with ${EXPERIMENT_ID}."
        echo ""

    done < $INFILE
fi