#
#================================================================
# oasis_data_matchup.py
#================================================================
#
# Usage: python oasis_data_matchup.py --adrc <adrc.csv> --sessions <sessions.csv> --output_name <output_filename.csv>
#                                     --lower_bound <num_days_before> --upper_bound <num_days_after> 
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
# <list1.csv> - A comma-separated spreadsheet file such as one downloaded from OASIS3 on central.xnat.org. 
#       The first column should be the ID that ends in the number of days from entry, "d0000" (e.g. OAS30001_MR_d0129)
#       First column header MUST be 'ADRC_ADRCCLINICALDATA ID'
#       The second column should contain the subject ID, e.g. OAS30001.
#       Second column header MUST be 'Subject'
#        
# <list2.csv> - A comma-separated spreadsheet file such as one downloaded from OASIS3 on central.xnat.org. 
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
# Last Updated: 29/08/2020
# Author: Christopher Fleetwood
#



import argparse
import pandas as pd
import numpy as np
import os

def main(adrc, sessions, output_name, lower_bound, upper_bound):
    adrc = pd.read_csv(adrc)
    sessions = pd.read_csv(sessions)
    adrc['Day'] = adrc['ADRC_ADRCCLINICALDATA ID'].apply(lambda x: int(x.split('_')[2][1:]))

    sessions['Day'] = sessions['MR ID'].apply(lambda x: int(x.split('_')[2][1:]))

    adrc =adrc.loc[adrc['Subject'].isin(sessions['Subject'])]

    out_df = pd.DataFrame()
    for index, row in sessions.iterrows():
        mask = (adrc['Subject'] == row['Subject']) & ((adrc['Day'] < row['Day'] + upper_bound) & (adrc['Day'] > row['Day'] - lower_bound))   
        for name in row.index:
            adrc.loc[mask, name +'_MR'] = row[name]
    
    adrc.dropna(subset=['MR ID_MR'], inplace=True)

    adrc.to_csv(output_name)


def is_valid_file(parser, arg):
    if not os.path.exists(arg):
        parser.error("The file %s does not exist!" % arg)
    else:
        return open(arg, 'r')  # return an open file handle

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Python version of ADRC Clinical Data matching to OASIS MR Sessions')

    parser.add_argument('--adrc', required=True, type=lambda x: is_valid_file(parser, x), help="File containing ADRC clinical data. Must feature column ADRC_ADRCCLINICALDATA ID and a Subject column. <adrc.csv>")
    parser.add_argument('--sessions', required=True, type=lambda x: is_valid_file(parser, x), help="File containing OASIS MR Sessions. Must feature column MR ID and a Subject column. <sessions.csv>")
    parser.add_argument('--output_name', required=True, type=str, help="File name of the output CSV <output.csv>")
    parser.add_argument('--lower_bound', type=int, default=180,  help="Number of days prior MR session that Clinical Data is included.")
    parser.add_argument('--upper_bound', type=int, default=180,  help="Number of days post MR session that Clinical Data is included.")

    args = parser.parse_args()

    main(args.adrc, args.sessions, args.output_name, args.lower_bound, args.upper_bound)