#!/bin/bash
#
#================================================================
# download_oasis_scans_bids.sh
#================================================================
#
# Usage: ./download_oasis_scans_bids.sh <input_file.csv> <directory_name> <nitrc_ir_username> <scan_type>
# 
# Download scans of a specified type from OASIS3 or OASIS4 on NITRC IR and organize the files into BIDS format
#
# Required inputs:
# <input_file.csv> - A Unix formatted, comma-separated file containing a column for experiment_id 
#       (e.g. OAS30001_MR_d0129)
# <directory_name> - A directory path (relative or absolute) to save the scan files to
# <nitrc_ir_username> - Your NITRC IR username used for accessing OASIS data on nitrc.org/ir
#       (you will be prompted for your password before downloading)
# 
# Optional inputs:
# <scan_type> - (Optional) The scan type of the scan you want to download. (e.g. T1w, angio, bold, fieldmap, FLAIR)
#       You can also enter multiple scan types separated by a comma with no whitespace (e.g. T2w,swi,bold)
#       Without this argument, all scans for the given experiment_id will be downloaded.
# <tau_project_id> - (optional) if you are downloading from OASIS3_AV1451 or OASIS3_AV1451L, 
#       specify which project to download from. Other OASIS projects will be chosen automatically based on session label.
#       If you want to use this option but not specify a particular <scan_type> option, you must specify scan_type as "ALL".
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
# Last Updated: 5/13/2024
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
    curl -k -s -u ${USERNAME}:${PASSWORD} --cookie-jar ${COOKIE_JAR} "https://nitrc.org/ir/data/JSESSION" > /dev/null
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
    curl -i -k --cookie ${COOKIE_JAR} -X DELETE "https://nitrc.org/ir/data/JSESSION"
    rm -f ${COOKIE_JAR}
}


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

            echo "scan filename is: ${SCAN_FILENAME}"
            echo "scan type is: ${SCAN_TYPE}"

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

                # Fix for https://github.com/NrgXnat/oasis-scripts/issues/11 part 2
                # Replace "_echo" in dataset_description with BIDS-compliant "acq-echo"
                if [[ "${SCAN_FILENAME}" == "${scan_subject_sub}_${scan_session_ses}_echo"* ]]
                then
                    echo "Updating echo fieldmap file name for BIDS compliance."
                    UPDATED_SCAN_FILENAME=`echo ${SCAN_FILENAME} | sed 's/echo/acq-echo/g'`
                    UPDATED_SCAN_FILENAME=`echo ${UPDATED_SCAN_FILENAME} | sed 's/echo-/echo/g'`
                    echo "Updated scan filename is ${UPDATED_SCAN_FILENAME}"
                    mv $new_path/${SCAN_FILENAME} $new_path/${UPDATED_SCAN_FILENAME}
                fi

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

            # Change permissions on the output folder
            chmod -R u=rwX,g=rwX $new_path

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

    COOKIE_JAR=$(startSession)

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

        # Set up the download URL and make a call to download the requested scans in tar.gz format
        download_url=https://nitrc.org/ir/data/archive/projects/${PROJECT_ID}/subjects/${SUBJECT_ID}/experiments/${EXPERIMENT_ID}/scans/${SCANTYPE}/files?format=tar.gz

        echo $download_url

        download $DIRNAME/$EXPERIMENT_ID.tar.gz $download_url

        # Check the tar.gz file to make sure we downloaded something
        # If the tar.gz file is invalid, we didn't download a scan so there is probably no scan of that type
        # If the tar.gz file is valid, untar and rearrange the files
        if tar tf $DIRNAME/$EXPERIMENT_ID.tar.gz &> /dev/null; then

            do_unzip $SCANTYPE $EXPERIMENT_ID $DIRNAME $SUBJECT_ID

            move_to_bids $DIRNAME $EXPERIMENT_ID

            # Remove the empty scans folder that the files were moved from
            rm -r $DIRNAME/$EXPERIMENT_ID

            # Grab the dataset_description file and put it in the session directory
            # Set up the URL and make a call to download the dataset_description file
            dataset_description_url=https://nitrc.org/ir/data/archive/projects/${PROJECT_ID}/subjects/${SUBJECT_ID}/experiments/${EXPERIMENT_ID}/resources/BIDS/files/dataset_description.json
            download $DIRNAME/$subject_folder/$session_folder/dataset_description.json "$dataset_description_url"

            # Fix for https://github.com/NrgXnat/oasis-scripts/issues/11 part 1
            # Replace "BidsVersion" in dataset_description with BIDS-compliant "BIDSVersion"
            sed -i 's/BidsVersion/BIDSVersion/g' $DIRNAME/$subject_folder/$session_folder/dataset_description.json

        else
            if [ ! $SCANTYPE = "ALL" ]
            then
                echo "Could not complete the scan download. Either did not find a ${SCANTYPE} scan for ${EXPERIMENT_ID}, or the download failed."
            else
                echo "Could not complete the scan download. Either could not find any scans for ${EXPERIMENT_ID}, or the download failed."
            fi  
        fi

        # Remove the original tar.gz file
        rm $DIRNAME/$EXPERIMENT_ID.tar.gz

        echo "Done with ${EXPERIMENT_ID}."
        echo ""

    done < $INFILE

    endSession

fi
