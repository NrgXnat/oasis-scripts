# Table of Contents

- [OASIS3 Scripts Overview](#oasis3-scripts-overview)
- [Downloading MR and PET Scan files](#downloading-mr-and-pet-scan-files)
  * [download_oasis_scans.sh](#download-oasis-scanssh)
    + [Detailed instructions on how to run this script](#detailed-instructions-on-how-to-run-this-script)
    + [List of available scan type names](#list-of-available-scan-type-names)
- [Downloading Freesurfer files](#downloading-freesurfer-files)
  * [freesurfer/download_oasis_freesurfer.sh](#freesurfer-download-oasis-freesurfersh)
- [Creating a CSV file for use with these scripts](#creating-a-csv-file-for-use-with-these-scripts)
    + [Note on Unix file formatting](#note-on-unix-file-formatting)
      - [Using Microsoft Notepad](#using-microsoft-notepad)
      - [Using `tr`](#using--tr-)
      - [Using `dos2unix`](#using--dos2unix-)


# OASIS3 Scripts Overview

This repository contains scripts that can be used to download files from the OASIS3 project on XNAT Central. In order to access the OASIS data you must have signed the [OASIS Data Use Agreement](https://www.oasis-brains.org) and have access to the OASIS3 project on XNAT Central at [central.xnat.org](https://www.central.xnat.org). 


# Downloading MR and PET Scan files

## download_oasis_scans.sh 

This script downloads scans of a specified type and organizes the files. 

Use `download_oasis_scans.sh` if you are on Linux or Mac and have the `zip` program installed. Use `download_oasis_scans_tar.sh` if you are using MobaXTerm on Windows or if you do not have the `zip` program installed on your machine (requires `tar` instead). If you have problems with using the `curl` program (If you see errors that say CURL in them), use `download_oasis_scans_wget.sh`.


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

### Detailed instructions on how to run this script

To run this script, follow the steps below.

1. Download the script from this Github repository by clicking "Clone or download" and choose Download ZIP. This will download a zip file containing all the scripts in the repository and this README file. 

2. Extract the .zip file onto your local computer and move the download_oasis_scripts.sh (or whichever script file you would like to use) into the folder you will be working from.

3. Download or create a CSV of OASIS experiment IDs to use as an input to the script. Instructions for this can be found in the "[Creating a CSV file](#creating-a-csv-file-for-use-with-these-scripts)" section of this README. 

Move the resulting csv file into the same folder as the script.

4. Create an empty directory in the same folder as your script and make a note of its name. This is the directory where your scan files will be downloaded to. 

5. Go into your command line. On Windows you can use a terminal system like [MobaXTerm](https://mobaxterm.mobatek.net/). If you're using a Mac you can use Terminal. Make sure you are **not** running the script while logged in as the root user. Change directories to the folder your scripts and empty folder are in using the `cd` command.

6. Run the download_oasis_scans script using the following command:

```
./download_oasis_scans.sh <input_file.csv> <directory_name> <xnat_central_username> <scan_type>
```

Where <input_file.csv> is the name of the file containing the list of OASIS experiment IDs, <directory_name> is the name of your empty directory, <xnat_central_username> is your XNAT Central username, and <scan_type> is the scan type you would like to download. Adding scan_type is optional, and without it all the scans will be downloaded. If you choose to include the scan type option, choose from the [list of available scan types](https://github.com/NrgXnat/oasis-scripts#list-of-available-scan-types) below. You can enter a single scan type such as `T1w`, a comma-separated list with no spaces such as `T1w,T2w,FLAIR`, or leave it out completely. A couple of example commands:

```
# Download T1w, T2w, and FLAIR scans from the sessions listed in myfile.csv
./download_oasis_scans.sh myfile.csv downloaded_files xnatuser T1w,T2w,FLAIR

# Download all scans from the sessions listed in myfile.csv
./download_oasis_scans.sh myfile.csv downloaded_files xnatuser

```

The files for the scans from each experiment ID in your list should begin downloading.


### List of available scan type names

When entering `scan_type` into your script, use any of the following names: `angio`, `asl`, `bold`, `dwi`, `fieldmap`, `FLAIR`, `GRE`, `minIP`, `swi`, `T1w`, `T2star`, `T2w`
For more information on these scan types, see the [OASIS Imaging Data Dictionary](https://www.oasis-brains.org/files/OASIS-3_Imaging_Data_Dictionary_v1.5.pdf). 


# Downloading Freesurfer files

## freesurfer/download_oasis_freesurfer.sh 

The scripts contained in the `freesurfer` folder can be used to download Freesurfer data and organize the files.

Use `download_oasis_freesurfer.sh` if you are on Linux or Mac and have the `zip` program installed. Use `download_oasis_freesurfer_tar.sh` if you are using MobaXTerm on Windows or if you do not have the `zip` program installed on your machine (requires `tar` instead). If you have problems with using the `curl` program (If you see errors that say CURL in them), use `download_oasis_freesurfer_wget.sh`. 


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


# Creating a CSV file for use with these scripts

When you run any of the scripts, you will need to download or create a CSV of OASIS experiment IDs or Freesurfer IDs to use as an input to the script. This can be created from a search result table on XNAT Central, described on the XNAT Wiki on the [OASIS on XNAT Central](https://wiki.xnat.org/central/oasis-on-xnat-central-60981641.html) page. 

- From an MR Session search, use **Options** then **Edit Columns** to include the "MR ID" column in your column view. If you are doing a PET Session search, include the "PET ID" column. If you are downloading Freesurfer files, use the Freesurfer tab from the OASIS project page, or do an Advanced Search for Freesurfers and specify the OASIS3 project. Then include the "Freesurfer ID" column in your column view.
- Download the resulting table by selecting **Options** then **Spreadsheet**. 
- Once you download a spreadsheet, remove all columns from it except for the "MR ID" column and save it as a .csv file. This can be done In Microsoft Excel by selecting Save As and choosing "CSV (Comma delimited) \*.csv" as the file type. 
- If you save a file using Microsoft Excel, you must convert it to Unix format before using it as input to a script. If the file is incorrectly formatted, you may experience errors or download failures when you run the script. Instructions for doing this conversion are below.


### Note on Unix file formatting

The comma-separated file you send to the script must be Unix-formatted - the file must not have Microsoft Windows line endings. If the file is incorrectly formatted, you may receive "Illegal character" errors when you run the script, or see "\\r" characters in the script output and experience download failures. To fix this, you can use one of the following options:


#### Using Microsoft Notepad

When saving a comma-separated file in Microsoft Excel, select "Save As" and choose "CSV (Comma Delimited) (\*.csv)". Then open the file using Microsoft Notepad, and in Notepad select "Save As", and under "Encoding" choose "UTF-8".

#### Using `tr`
```
tr -d '\r' < myfile.csv > myfile_unix.csv
```

#### Using `dos2unix`

Install `dos2unix` as follows:

On CentOS, Fedora, or RHEL, run `sudo yum install dos2unix`

On Ubuntu or Debian, run `sudo apt-get install tofrodos` and then `sudo ln -s /usr/bin/fromdos /usr/bin/dos2unix`

Once dos2unix is available, run 
```
dos2unix myfile.csv
```
