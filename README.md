# Table of Contents

- [OASIS3 and OASIS4 Scripts Overview](#oasis3-and-oasis4-scripts-overview)
- [Downloading MR and PET Scan files](#downloading-mr-and-pet-scan-files)
  * [download_scans/download_oasis_scans.sh](#download_scansdownload_oasis_scanssh)
- [Downloading MR and PET Scan files in BIDS format](#downloading-mr-and-pet-scan-files-in-bids-format)
  * [download_scans/download_oasis_scans_bids.sh](#download_scansdownload_oasis_scans_bidssh)
  * [Notes on OASIS3 and OASIS4 BIDS formatting](#notes-on-oasis3-and-oasis4-bids-formatting)
- [Downloading Freesurfer files](#downloading-freesurfer-files)
  * [download_freesurfer/download_oasis_freesurfer.sh](#download_freesurferdownload_oasis_freesurfersh)
- [Downloading PET Unified Pipeline (PUP) files](#downloading-pet-unified-pipeline-pup-files)
  * [download_pup/download_oasis_pup.sh](#download_pupdownload_oasis_pupsh)
- [Matching Up Session Data by Days From Entry](#matching-up-session-data-by-days-from-entry)
  * [session_matchup/oasis_data_matchup.R](#session_matchupoasis_data_matchupr)
- [Detailed instructions on how to run these scripts](#detailed-instructions-on-how-to-run-these-scripts)
  * [Downloading](#downloading)
  * [List of available scan type names for downloading](#list-of-available-scan-type-names-for-downloading)
  * [Matching Up](#matching-up)
- [Creating a CSV file for use with these scripts](#creating-a-csv-file-for-use-with-these-scripts)
    + [Note on Unix file formatting](#note-on-unix-file-formatting)
      - [Using Microsoft Notepad](#using-microsoft-notepad)
      - [Using `tr`](#using-tr)
      - [Using `dos2unix`](#using-dos2unix)


# OASIS3 and OASIS4 Scripts Overview

This repository contains scripts that can be used to download files from the OASIS3 or OASIS4 projects on XNAT Central. In order to access the OASIS data you must have signed the [OASIS Data Use Agreement](https://www.oasis-brains.org) and have access to the OASIS3 or OASIS4 project on XNAT Central at [central.xnat.org](https://central.xnat.org). 


# Downloading MR and PET Scan files

## download_scans/download_oasis_scans.sh 

This script downloads scans of a specified type and organizes the files. 

Use `download_oasis_scans.sh` if you are on Linux or Mac and have the `zip` program installed. Use `download_oasis_scans_tar.sh` if you are using MobaXTerm on Windows or if you do not have the `zip` program installed on your machine (requires `tar` instead). If you have problems with using the `curl` program (For example, if you see errors that say CURL in them), use `download_oasis_scans_wget.sh`. To download in BIDS format, see the section below.


Usage: 
```
./download_oasis_scans.sh <input_file.csv> <directory_name> <xnat_central_username> <scan_type>
```

Required inputs:

`<input_file.csv>` - A Unix formatted, comma-separated file containing a column for experiment_id (e.g. OAS30001_MR_d0129)

`<directory_name>` - A directory path (relative or absolute) to save the scan files to. If this directory doesn't exist when you run the script, it will be created automatically.

`<xnat_central_username>` - Your XNAT Central username used for accessing OASIS data on central.xnat.org (you will be prompted for your password before downloading)

`<scan_type>` - (Optional) The scan type of the scan you want to download. (e.g. T1w, angio, bold, fieldmap, FLAIR) You can also enter multiple scan types separated by a comma with no whitespace (e.g. T2w,swi,bold). Without this argument, all scans for the given experiment_id will be downloaded.


This script organizes the files into folders like this:

```
directory_name/OAS30001_MR_d0129/anat1/file.json
directory_name/OAS30001_MR_d0129/anat1/file.nii.gz
directory_name/OAS30001_MR_d0129/anat4/file.json
directory_name/OAS30001_MR_d0129/anat4/file.nii.gz
```

# Downloading MR and PET Scan files in BIDS format

## download_scans/download_oasis_scans_bids.sh 

This script downloads scans from OASIS and organizes the files into Brain Imaging Data Structure (BIDS) format (See the [BIDS website](https://bids.neuroimaging.io/) and the [BIDS file specification](https://bids.neuroimaging.io/bids_spec.pdf) for more details on the BIDS format). 

The `download_oasis_scans_bids.sh` will work as-is if you are able to use `wget` and `tar`.

This script organizes the files into folders like this:

```
directory_name/sub-subjectname/ses-sessionname/anat/sub-subjectname_T1w.json
directory_name/sub-subjectname/ses-sessionname/anat/sub-subjectname_T1w.nii.gz
directory_name/sub-subjectname/ses-sessionname/anat/sub-subjectname_T2w.json
directory_name/sub-subjectname/ses-sessionname/anat/sub-subjectname_T2w.nii.gz
directory_name/sub-subjectname/ses-sessionname/func/sub-subjectname_bold.json
directory_name/sub-subjectname/ses-sessionname/func/sub-subjectname_bold.nii.gz
```

See [Detailed instructions on how to run these scripts](https://github.com/NrgXnat/oasis-scripts#detailed-instructions-on-how-to-run-these-scripts) for more details on how to run the script.

### Notes on OASIS3 and OASIS4 BIDS formatting

The OASIS3 and OASIS4 BIDS files use version 1.0.1 of the BIDS specification, so if you plan to use a BIDS validator on downloaded OASIS data, make sure your validator software can validate to that version. This is an older version of the BIDS specification and there may be formatting that does not match current specifications or fields that were not incorporated into the BIDS specification until later in its development. _The OASIS3 and OASIS4 BIDS files will not be updated to newer BIDS specifications._ 

One specific conflict that has been found with newer BIDS specifications is the labeling of the task name for OASIS BOLD scans. For any OASIS3 and OASIS4 BOLD data the task name should be "rest". If you require OASIS JSON files to match a newer BIDS specification, you can modify your downloaded copy of any BOLD scan JSON files to meet the specification version you require.

Details on the BIDS specification number and citation details for the OASIS datasets can be found in the dataset description files which are located at the MR and PET session level, under "Manage Files", in the "resources" folder (first folder in the Manage Files list), "BIDS" subfolder, in the `dataset_description.json` file for each session. 

Our original scan DICOM files were converted to BIDS format using [dcm2niix](https://github.com/rordenlab/dcm2niix) version 17-October-2017. This information is also listed in each individual scan BIDS JSON file.

# Downloading Freesurfer files

## download_freesurfer/download_oasis_freesurfer.sh 

The scripts contained in the `freesurfer` folder can be used to download Freesurfer data and organize the files.

Use `download_oasis_freesurfer.sh` if you are on Linux or Mac and have the `zip` program installed. Use `download_oasis_freesurfer_tar.sh` if you are using MobaXTerm on Windows or if you do not have the `zip` program installed on your machine (requires `tar` instead). If you have problems with using the `curl` program (If you see errors that say CURL in them, for example), use `download_oasis_freesurfer_wget.sh`. 


Usage: 
```
./download_oasis_freesurfer.sh <input_file.csv> <directory_name> <xnat_central_username>
```

Required inputs:

`<input_file.csv>` - A Unix formatted, comma-separated file containing a column for freesurfer_id (e.g. OAS30001_Freesurfer53_d0129)

`<directory_name>` - A directory path (relative or absolute) to save the scan files to. If this directory doesn't exist when you run the script, it will be created automatically.

`<xnat_central_username>` - Your XNAT Central username used for accessing OASIS data on central.xnat.org (you will be prompted for your password before downloading)


This script organizes the files into folders such that the directory `directory name/OAS30001_MR_d0129/` will contain all the Freesurfer data folders. 

**NOTES:** Since the Freesurfer is linked with the MR ID, saving a Freesurfer and MR Scan folder in the same directory will cause both to be saved in a folder named (for example) OAS30001_MR_d0129. Make sure that you save your Freesurfer folders in a separate directory from the MR scans to prevent confusion and errors. Additionally, this Freesurfer download script will not differentiate between versions of Freesurfer. You will need to keep track of Freesurfer version when you create your ID list (whether the ID contains Freesurfer53, Freesurfer51, or Freesurfer50). 

# Downloading PET Unified Pipeline (PUP) files

## download_pup/download_oasis_pup.sh 

The scripts contained in the `pup` folder can be used to download PUP data and organize the files.

Use `download_oasis_pup.sh` if you are on Linux or Mac and have the `zip` program installed. Use `download_oasis_pup_tar.sh` if you are using MobaXTerm on Windows or if you do not have the `zip` program installed on your machine (requires `tar` instead). If you have problems with using the `curl` program (If you see errors that say CURL in them, for example), use `download_oasis_pup_wget.sh`. 


Usage: 
```
./download_oasis_pup.sh <input_file.csv> <directory_name> <xnat_central_username>
```

Required inputs:

`<input_file.csv>` - A Unix formatted, comma-separated file containing a column for pup_id (e.g. OAS30001_AV45_PUPTIMECOURSE_d2430)

`<directory_name>` - A directory path (relative or absolute) to save the scan files to. If this directory doesn't exist when you run the script, it will be created automatically.

`<xnat_central_username>` - Your XNAT Central username used for accessing OASIS data on central.xnat.org (you will be prompted for your password before downloading)


This script organizes the files into folders such that the directory `directory_name/OAS30001_AV45_PUPTIMECOURSE_d2430/` will contain all the PUP files. 


# Matching Up Session Data by Days From Entry

## session_matchup/oasis_data_matchup.R 

This script takes in two OASIS3 or OASIS4 .csv formatted spreadsheets and matches up the sessions based on your requested days from entry distance requirements. This script requires R at least version 3.3.0 and the R data.table library minimum version 1.12.8. See the [R-project website](https://www.r-project.org/) for more details on the R language and visit the [R data.table library website](https://rdatatable.gitlab.io/data.table/) for more details on the data.table library. 

OASIS3 or OASIS4 data has been anonymized and dates have been eliminated from the data sets. OASIS3 and OASIS4 instead use "days from entry" to note when scan sessions and questionnaire sessions happen relative to each other. The "days from entry" variable is seen in OASIS3 or OASIS4 IDs for MR sessions, PET sessions, Freesurfer assessors, PUP assessors, and questionnaire sessions (such as ADRC Clinical Data entries or UDS form entries). At the end of each ID is a string `d0000` where 0000 is the days since the subject's entry date into the study. A days from entry value of 0 means that this is the subject's first visit.

Scan sessions and questionnaire sessions do not always happen at the same visit. If for example you are trying to find a corresponding ADRC Clinical Data entry for a given MR session, you must first choose a criteria for how long from a particular MR session you will consider a corresponding ADRC Clinical Data entry to be "valid". A common criteria is to consider all ADRC Clinical Data entries within 1 year before or after the MR session date to be valid. In this case you would consider the closest ADRC Clinical Data entry to the MR session to be a "match" as long as its days from entry value is within 365 days before or within 365 days after the MR session's days from entry value. 

A script has been created to help match up the data values. It takes as required input two CSV files of data that you must download from OASIS3 or OASIS4. For more information on that, see the "[Creating a CSV file](#creating-a-csv-file-for-use-with-these-scripts)" section of this README. 

When you set up your CSV files, the first two columns must contain specific IDs and be in a specific order. The first column in each spreadsheet MUST be the OASIS ID that contains a days-from-entry value at the end of it (e.g. `OAS30001_MR_d0000` in the MR session spreadsheet, and `OAS30003_ClinicalData_d0123`, etc.). The second column MUST be the OASIS subject ID (e.g. `OAS30001` in the MR session spreadsheet, and `OAS30003` in the ADRC Clinical Data entry spreadsheet). You can select these columns using the Edit Columns feature of an XNAT search. For more details on searching, modifying which columns are displayed, and downloading spreadsheets, see the [OASIS on XNAT Central](https://wiki.xnat.org/central/oasis-on-xnat-central-60981641.html) page of the XNAT wiki. 

You must also determine which order you want to match in. In the script, each entry in "list1" will receive one matched entry from "list2" if a "list2" entry meets your days from entry distance criteria. 

Usage: 
```
Rscript oasis_data_matchup.R <list1.csv> <list2.csv> <num_days_before> <num_days_after> <output_filename.csv>
```

Required inputs:

`<list1.csv>` - A Unix formatted, comma-separated file containing your "list 1" entry data. This can also include other columns of data, but the first column MUST be the OASIS3 or OASIS4 type ID that contains the "days from entry" at the end as described above. The second column MUST be the subject ID as described above.

`<list2.csv>` - A Unix formatted, comma-separated file containing your "list 2" entry data. This can also include other columns of data, but the first column MUST be the OASIS3 or OASIS4 type ID that contains the "days from entry" at the end as described above. The second column MUST be the subject ID as described above.

`<num_days_before>` - A positive integer value. This should be the maximum number of days before a list1 element that a "matched" list2 element should occur.

`<num_days_after>` - A positive integer value. This should be the maximum number of days after a list1 element that a "matched" list2 element should occur.

`<output_filename.csv>` - A filename to use for the output spreadsheet file.


An example:

The OASIS MR sessions/ADRC Clinical Data entries example could be run as follows:
1. if `num_days_before` is 365 and `num_days_after` is 0, it will only include data entries from list2 that are 0 to 365 days *before* the entry in list1.
2. if `num_days_before` is 0 and `num_days_after` is 365, it will only include data entries from list2 that are 0 to 365 days *after* the entry in list1.
3. if `num_days_before` is 80 and `num_days_after` is 365, it will only include data entries from list2 that are between 80 days before and 365 days after the entry in list1. It will choose the closest in time entry in either direction as the "matched" element.
4. if num_days_before is 0 and num_days_after is 0, it will only include list2 entries that have the *exact same* number of days from entry as the corresponding element in list1. This only returns entries that occurred on the same day.


# Detailed instructions on how to run these scripts

To run any of these scripts, follow the steps below.

1. Download the script from this Github repository by clicking "Clone or download" and choose Download ZIP. This will download a zip file containing all the scripts in the repository and this README file. 

2. Extract the .zip file onto your local computer and move the download_oasis_scripts.sh (or whichever script file you would like to use) into the folder you will be working from. 

3. Download or create a CSV of OASIS experiment IDs to use as an input to the script, or multiple CSVs of data if you are using the matchup script. Instructions for this can be found in the "[Creating a CSV file](#creating-a-csv-file-for-use-with-these-scripts)" section of this README. 

Move the resulting csv file(s) into the same folder as the script.

4. If you are running a download script, create an empty directory in the same folder as your script and make a note of its name. This is the directory where your scan files will be downloaded to. 

5. Go into your command line. On Windows you can use a terminal system like [MobaXTerm](https://mobaxterm.mobatek.net/). If you're using a Mac you can use Terminal. Make sure you are **not** running the script while logged in as the root user. Change directories to the folder your scripts and empty folder are in using the `cd` command.

## Downloading

If you are **downloading**, run the download_oasis_scans script using the following command:

```
./download_oasis_scans.sh <input_file.csv> <directory_name> <xnat_central_username> <scan_type>
```

Where `<input_file.csv>` is the name of the file containing the list of OASIS experiment IDs, `<directory_name>` is the name of your empty directory, `<xnat_central_username>` is your XNAT Central username, and `<scan_type>` is the scan type you would like to download. Adding scan_type is optional, and without it all the scans will be downloaded. If you choose to include the scan type option, choose from the [list of available scan types](https://github.com/NrgXnat/oasis-scripts#list-of-available-scan-types) below. You can enter a single scan type such as `T1w`, a comma-separated list with no spaces such as `T1w,T2w,FLAIR`, or leave it out completely. A couple of example commands:

```
# Download T1w, T2w, and FLAIR scans from the sessions listed in myfile.csv
./download_oasis_scans.sh myfile.csv downloaded_files xnatuser T1w,T2w,FLAIR

# Download all scans from the sessions listed in myfile.csv
./download_oasis_scans.sh myfile.csv downloaded_files xnatuser

```

The files for the scans from each experiment ID in your list should begin downloading.


## List of available scan type names for downloading

When downloading, if you are entering `scan_type` into your script, use any of the following names: `angio`, `asl`, `bold`, `dwi`, `fieldmap`, `FLAIR`, `GRE`, `minIP`, `swi`, `T1w`, `T2star`, `T2w`
For more information on these scan types, see the [OASIS Imaging Data Dictionary](https://www.oasis-brains.org/files/OASIS-3_Imaging_Data_Dictionary_v1.5.pdf). 


## Matching Up

If you are running the **matchup script**, run the oasis_data_matchup.R script using the following command:

```
Rscript oasis_data_matchup.R <list1.csv> <list2.csv> <num_days_before> <num_days_after> <output_filename.csv>
```

Where `<list1.csv>` is the name of your first list file, `<list2.csv>` is the name of your second list file, `<num_days_before>` is your maximum allowable number of days before to consider an entry valid, `<num_days_after>` is your maximum allowable number of days after to consider an entry valid, and `<output_file.csv>` is a name of an output file (any file name you wish to save your resulting merged file as). A couple of example commands are below:

```
# Get a ADRC Clinical Data entry for every MR session entry. Get the closest ADRC Clinical Data 
# entry as long as the ADRC Clinical Data entry is within 1 year of the MR Session entry, either before or after.
Rscript oasis_data_matchup.R oasis_mr_sessions.csv oasis_adrc_clinical_data.csv 365 365 oasis_mr_sessions_and_adrc_clinical_data_matched_1year.csv

# Get a ADRC Clinical Data entry for every MR session entry. Get the closest ADRC Clinical Data
# entry as long as the ADRC Clinical Data entry is within 1 year BEFORE the MR Session entry only.
Rscript oasis_data_matchup.R oasis_mr_sessions.csv oasis_adrc_clinical_data.csv 365 0 oasis_mr_sessions_and_adrc_clinical_data_matched_1year_before.csv

```

After running the matchup script, the output file you specify should then contain your matched data.


# Creating a CSV file for use with these scripts

When you run any of the scripts, you will need to download or create a CSV of OASIS experiment IDs or Freesurfer IDs to use as an input to the script. This can be created from a search result table on XNAT Central, described on the XNAT Wiki on the [OASIS on XNAT Central](https://wiki.xnat.org/central/oasis-on-xnat-central-60981641.html) page. 

- From an MR Session search, use **Options** then **Edit Columns** to include the "MR ID" column in your column view. If you are doing a PET Session search, include the "PET ID" column. If you are downloading Freesurfer files, use the Freesurfer tab from the OASIS project page, or do an Advanced Search for Freesurfers and specify the OASIS3 or OASIS4 project. Then include the "Freesurfer ID" column in your column view.
- Download the resulting table by selecting **Options** then **Spreadsheet**. 
- Once you download a spreadsheet, remove all columns from it except for the "MR ID" column and save it as a .csv file. This can be done In Microsoft Excel by selecting Save As and choosing "CSV (Comma delimited) \*.csv" as the file type. 
- If you save a file using Microsoft Excel, you must convert it to Unix format before using it as input to a script. If the file is incorrectly formatted, you may experience errors or download failures when you run the script. Instructions for doing this conversion are below.


### Note on Unix file formatting

The comma-separated file you send to the script must be Unix-formatted - the file must not have Microsoft Windows line endings. If the file is incorrectly formatted, you may receive "Illegal character" errors when you run the script, or see "\\r" characters in the script output and experience download failures. To fix this, you can use one of the following options:


#### Using Microsoft Notepad

When saving a comma-separated file in Microsoft Excel, select "Save As" and choose "CSV (Comma Delimited) (\*.csv)". Then open the file using Microsoft Notepad, and in Notepad select "Save As", and under "Encoding" choose "UTF-8".

#### Using tr
```
tr -d '\r' < myfile.csv > myfile_unix.csv
```

#### Using dos2unix

Install `dos2unix` as follows:

On CentOS, Fedora, or RHEL, run `sudo yum install dos2unix`

On Ubuntu or Debian, run `sudo apt-get install tofrodos` and then `sudo ln -s /usr/bin/fromdos /usr/bin/dos2unix`

Once dos2unix is available, run 
```
dos2unix myfile.csv
```
