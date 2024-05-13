#
#================================================================
# oasis_data_matchup.py
#================================================================
#
# Usage: python oasis_data_matchup.py --list1 <list1.csv> --list2 <list2.csv> --output_name <output_filename.csv>
#                                     --lower_bound <num_days_before> --upper_bound <num_days_after> 
# 
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
# <list1.csv> - A comma-separated spreadsheet file such as one downloaded from OASIS3 or OASIS4 on nitrc.org/ir. 
#       The first column should be the ID that ends in the number of days from entry, "d0000" (e.g. OAS30001_MR_d0129)
#       First column header MUST be 'ADRC_ADRCCLINICALDATA ID'
#       The second column should contain the subject ID, e.g. OAS30001.
#       Second column header MUST be 'Subject'
#        
# <list2.csv> - A comma-separated spreadsheet file such as one downloaded from OASIS3 or OASIS4 on nitrc.org/ir. 
#       The first column should be the ID that ends in the number of days from entry, "d0000" (e.g. OAS30001_MR_d0129)
#       The first column header MUST be 'MR ID'
#       The second column should contain the subject ID, e.g. OAS30001.
#       The second column header MUST be 'Subject'
#       *** Each element from list1 will be linked with a corresponding element in list2. ***
# <num_days_before> - The maximum number of days before the list2 element that a list1 element should occur 
#       in order to be considered "matched."
# <num_days_after> - The maximum number of days after the list2 element that a list1 element should occur 
#       in order to be considered "matched."
# <output_filename.csv> - A filename to use for the output spreadsheet file.
#
#
# Last Updated: 1/11/2023
# Author: Khaled Elmalawany
# Adapted from: Christopher Fleetwood
# Last Updated By: Sarah Keefe
#


import argparse
import pandas as pd
import numpy as np
import os

def main(list1, list2, output_name, lower_bound, upper_bound):
    # Create dataframes with provided CSV files
    list1 = pd.read_csv(list1)
    list2 = pd.read_csv(list2)
    
    # Create a Day column from ID
    # Use the "dXXXX" value from the ID/label in the first column
    # pandas extract will pull that based on a regular expression no matter where it is.
    list1['Day'] = list1.iloc[:, 0].str.extract(r'(d\d{4})', expand=False).str.strip().apply(lambda x: int(x.split('d')[1]))
    list2['Day'] = list2.iloc[:,0].str.extract(r'(d\d{4})', expand=False).str.strip().apply(lambda x: int(x.split('d')[1]))
    
    # Update list1 to only consider subjects that are in both lists
    list1 =list1.loc[list1['Subject'].isin(list2['Subject'])]
    
    # Create and populate the dataframe
    out_df = pd.DataFrame()
    for index, row in list2.iterrows():
        mask = (list1['Subject'] == row['Subject']) & ((list1['Day'] < row['Day'] + upper_bound) & (list1['Day'] > row['Day'] - lower_bound))   
        for name in row.index:
            list1.loc[mask, name +'_list2'] = row[name]
    
    # Drop rows of which a match was not found
    #list1.dropna(inplace=True)
    list2_firstcolumnname=list2.columns.values[0] + "_list2"
    list1.dropna(subset=[list2_firstcolumnname])
    #list2.dropna(subset=[list2_firstcolumnname])

    list1.to_csv(output_name, index=False)


def is_valid_file(parser, arg):
    if not os.path.exists(arg):
        parser.error("The file %s does not exist!" % arg)
    else:
        return open(arg, 'r')  # return an open file handle

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Python version of list1 matching to list2 of the OASIS database')

    parser.add_argument('--list1', required=True, type=lambda x: is_valid_file(parser, x), help="File containing OASIS list 1 data. Must feature column of respective ID as the first column and a Subject column. <list1.csv>")
    parser.add_argument('--list2', required=True, type=lambda x: is_valid_file(parser, x), help="File containing OASIS list2 data. Must feature column of respective ID as the first column and a Subject column. <list2.csv>")
    parser.add_argument('--output_name', required=True, type=str, help="File name of the output CSV <output.csv>")
    parser.add_argument('--lower_bound', type=int, default=180,  help="Number of days prior to list1 session that list2 session is included.")
    parser.add_argument('--upper_bound', type=int, default=180,  help="Number of days post list1 session that list2 session is included.")

    args = parser.parse_args()

    main(args.list1, args.list2, args.output_name, args.lower_bound, args.upper_bound)
