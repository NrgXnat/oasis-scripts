# oasis-scripts

This repository contains scripts that can be used to download files from the OASIS3 project on XNAT Central. In order to access the OASIS data you must have signed the [OASIS Data Use Agreement](https://www.oasis-brains.org) and have access to the OASIS3 project on XNAT Central at [central.xnat.org](https://www.central.xnat.org). 


## download_oasis_scans.sh 

This script downloads scans of a specified type and organizes the files. 

Usage: 
```
./download_oasis_scans.sh <input_file.csv> <directory_name> <xnat_central_username> <scan_type>
```

Required inputs:

`<input_file.csv>` - A Unix formatted, comma-separated file containing a column for experiment_id (e.g. OAS30001_MR_d0129)

`<directory_name>` - A directory path (relative or absolute) to save the scan files to

`<xnat_central_username>` - Your XNAT Central username used for accessing OASIS data on central.xnat.org (you will be prompted for your password before downloading)

`<scan_type>` - The scan type of the scan you want to download. (e.g. T1w, angio, bold, fieldmap, FLAIR) You can also enter multiple scan types separated by a comma with no whitespace (e.g. T2w,swi,bold)


This script organizes the files into folders like this:

```
directory_name/OAS30001_MR_d0129/anat1/file.json
directory_name/OAS30001_MR_d0129/anat1/file.nii.gz
directory_name/OAS30001_MR_d0129/anat4/file.json
directory_name/OAS30001_MR_d0129/anat4/file.nii.gz
```