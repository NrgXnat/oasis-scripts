#! /usr/bin/env Rscript
#
#================================================================
# oasis_data_matchup.R
#================================================================
#
# Usage: ./oasis_data_matchup.R <list1.csv> <list2.csv> <num_days_before> <num_days_after> <output_filename.csv>
# 
#
# Requires the data.tables library.
#
# This script will select the closest element in list2 for each element in list1, based on the OASIS days from entry. 
# For example, if list1 contains OASIS MR sessions, and list2 contains OASIS ADRC Clinical Data entries, it will 
# choose the closest ADRC Clinical Data entry in time to each MR session, based on the "days from entry" d0000 value 
# in the OASIS ID for that element, which should be provided in the spreadsheet. 
#
# <num_days_before> is the maximum number of days before a list1 element that a "matched" list2 element should occur.
# <num_days_after> is the maximum number of days after a list1 element that a "matched" list2 element should occur.
#
# For example, the OASIS MR sessions/ADRC Clinical Data entries example could be run as follows:
#   1) if num_days_before is 365 and num_days_after is 0, it will only include data entries from list2 that are
#       0 to 365 days *before* the entry in list1.
#   2) if num_days_before is 0 and num_days_after is 365, it will only include data entries from list2 that are
#       0 to 365 days *after* the entry in list1.
#   3) if num_days_before is 80 and num_days_after is 365, it will only include data entries from list2 that are
#       between 80 days before and 365 days after the entry in list1. It will choose the closest in time entry
#       in either direction as the "matched" element.
#   4) if num_days_before is 0 and num_days_after is 0, it will only include list2 entries that have the exact same
#       number of days from entry as the corresponding element in list1. This only returns entries that occurred on 
#       the same day.
#
# Required inputs:
# <list1.csv> - A comma-separated spreadsheet file such as one downloaded from OASIS3 or OASIS 4on central.xnat.org. 
#       The first column should be the ID that ends in the number of days from entry, "d0000" (e.g. OAS30001_MR_d0129)
#       The second column should contain the subject ID, e.g. OAS30001.
# <list2.csv> - A comma-separated spreadsheet file such as one downloaded from OASIS3 or OASIS4 on central.xnat.org. 
#       The first column should be the ID that ends in the number of days from entry, "d0000" (e.g. OAS30001_MR_d0129)
#       The second column should contain the subject ID, e.g. OAS30001.
#       *** Each element from list1 will be linked with a corresponding element in list2. ***
# <num_days_before> - The maximum number of days before the list2 element that a list1 element should occur 
#       in order to be considered "matched."
# <num_days_after> - The maximum number of days after the list2 element that a list1 element should occur 
#       in order to be considered "matched."
# <output_filename.csv> - A filename to use for the output spreadsheet file.
#
#
# Last Updated: 1/22/2020
# Author: Sarah Keefe
#


# Libraries to include
library(data.table)

# Clear workspace
rm(list = ls())

# read in arguments to the script
args = commandArgs(trailingOnly=TRUE)
csv1_filename <- args[1]
csv2_filename <- args[2]
num_days_before <- as.numeric(args[3])
num_days_after <- as.numeric(args[4])
output_filename <- args[5]


# function to grab the last n characters of the values in column x
# used to grab the days from entry digits from the end of the ID
RIGHT = function(x,n){
  substring(x,nchar(x)-n+1)
}

# Read in all files
list1 <- read.csv(csv1_filename, header = TRUE, stringsAsFactors = FALSE, na.strings=c("","NA"))
list2 <- read.csv(csv2_filename, header = TRUE, stringsAsFactors = FALSE, na.strings=c("","NA"))

# extract days from entry for each list
list1$days_from_entry_list1 <- as.numeric(RIGHT(list1[,1], 4))
list1$days_from_entry <- as.numeric(RIGHT(list1[,1], 4))
list2$days_from_entry_list2 <- as.numeric(RIGHT(list2[,1], 4))
list2$days_from_entry <- as.numeric(RIGHT(list2[,1], 4))

# rename the second column in each dataframe to the same name (subject_id) for consistency 
colnames(list1)[2]<-"subject_id"
colnames(list2)[2]<-"subject_id"

# Get the closest list2 date to the list1 row
list1_dt <- data.table(list1, days_from_entry=list1$days_from_entry_list1, key=c("subject_id","days_from_entry"))
list2_dt <- data.table(list2, days_from_entry=list2$days_from_entry_list2, key=c("subject_id","days_from_entry"))

# copy over and give names to first columns (ID columns) for organizational use later
list1_dt[,('list1_id'):=list1[1]]
list2_dt[,('list2_id'):=list2[1]]

print(paste("Matching 1 list2 entry for each list1 entry."))

# Match up the values based on the criteria
if ((num_days_before == 0) && (num_days_after > 0)){
  # if num_days_before is 0, and num_days_after is greater than 0,
  # we want to get only list2 elements that occur after list1 within the range of 0 to num_days_after.
  print(paste("Getting only list2 entries that are 0 days before and maximum", num_days_after, "days after the list1 entry."), sep=" ")   
  closest_list2_to_list1 <- list2_dt[list1_dt, roll=-num_days_after]  
} else if ((num_days_before > 0) && (num_days_after == 0)) {
  # if num_days_after is 0, and num_days_before is greater than 0,
  # get only the list2 elements that occur before list1 within the range of 0 to num_days_before.
  print(paste("Getting only list2 entries that are maximum", num_days_before, "days before and 0 days after the list1 entry."), sep=" ")  
  closest_list2_to_list1 <- list2_dt[list1_dt, roll=num_days_before]    
} else if ((num_days_before > 0) && (num_days_after > 0)){
  # if num_days_after and num_days_before are both greater than 0,
  # get the closest element for list2 in list1 that occurs within that range (num_days_before to num_days_after).
  print(paste("Getting only list2 entries that are maximum", num_days_before, "days before and maximum", num_days_after, "days after the list1 entry."), sep=" ")
  closest_list2_to_list1_before <- list2_dt[list1_dt, roll=num_days_before]
  closest_list2_to_list1_before$date_difference_days <- closest_list2_to_list1_before$days_from_entry_list2 - closest_list2_to_list1_before$days_from_entry_list1
  closest_list2_to_list1_after <- list2_dt[list1_dt, roll=-num_days_after]
  closest_list2_to_list1_after$date_difference_days <- closest_list2_to_list1_after$days_from_entry_list2 - closest_list2_to_list1_after$days_from_entry_list1
  combined_list2_matched_to_list1_before_and_after <- rbind(closest_list2_to_list1_before, closest_list2_to_list1_after)
  # take one entry containing the minimum value of date_difference_days from the combined before and after list.
  closest_list2_to_list1 <- combined_list2_matched_to_list1_before_and_after[ , .SD[which.min(abs(date_difference_days))], by = list1_id]
} else {
  # if num_days_after and num_days_before are both 0,
  # get only entries in list2 that exactly match the number of days from entry in list1 (0 difference on both ends).
  print("Getting only list2 entries that occurred on the same day as each list1 entry.")
  closest_list2_to_list1 <- list2_dt[list1_dt, roll="nearest"] 
}

closest_list2_to_list1$date_difference_days <- closest_list2_to_list1$days_from_entry_list2 - closest_list2_to_list1$days_from_entry_list1

# if num_days_after and num_days_before are both 0,
# subset out the entries that have greater or less than 0 date difference.
if ((num_days_before == 0) && (num_days_after == 0)) {
  closest_list2_to_list1 <- subset(closest_list2_to_list1, date_difference_days == 0)
}

# add on the date difference in years as a column
closest_list2_to_list1$date_difference_years <- (closest_list2_to_list1$date_difference_days / 365)

# write the final output data frame to CSV
print(paste("Writing the output to",output_filename, sep=" "))
write.csv(closest_list2_to_list1, file = output_filename, row.names = FALSE, na = "")


