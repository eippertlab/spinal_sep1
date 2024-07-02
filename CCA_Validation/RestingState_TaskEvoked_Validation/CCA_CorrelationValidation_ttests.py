###################################################################################
# We have average correlation per participant, condition (median/tibial), and task (task/resting state), and CNS level
# (cortical, subcortical, spinal)
# We want to test:
# i.e. do median, task differ from median, rest in the spinal data
####################################################################################


import pandas as pd
import numpy as np
pd.set_option('display.max_rows', 500)
pd.set_option('display.max_columns', 500)
pd.set_option('display.width', 1000)
import pingouin as pg

if __name__ == '__main__':
    srmr_nr = 1
    type = 'cca'  # Can be long, shorter or cca

    if srmr_nr == 1:
        subjects = np.arange(1, 37)
        cond_names = ['median', 'tibial']
        if type == 'long':
            excel_fname = f'/data/p_02569/CCA_Validation/tmp_data/Correlation_Long.xlsx'
        elif type == 'shorter':
            excel_fname = f'/data/p_02569/CCA_Validation/tmp_data/Correlation_Shorter.xlsx'
        elif type == 'cca':
            excel_fname = f'/data/p_02569/CCA_Validation/tmp_data/Correlation_CCAWin.xlsx'

    elif srmr_nr == 2:
        subjects = np.arange(1, 25)
        cond_names = ['med_mixed', 'tib_mixed']
        if type == 'long':
            excel_fname = f'/data/p_02569/CCA_Validation/tmp_data_2/Correlation_Long.xlsx'
        elif type == 'shorter':
            excel_fname = f'/data/p_02569/CCA_Validation/tmp_data_2/Correlation_Shorter.xlsx'
        elif type == 'cca':
            excel_fname = f'/data/p_02569/CCA_Validation/tmp_data_2/Correlation_CCAWin.xlsx'

    data_types = ['spinal']  # , 'cortical'
    sheetname = 'Correlation'
    df = pd.read_excel(excel_fname, sheetname)
    df.drop('Subject', axis=1, inplace=True)
    print('mean')
    print(df.mean())
    print('min')
    print(df.min())
    print('max')
    print(df.max())

    # Test just the relationships of interest to us (i.e. whether for spinal, median task-evoked correlations are
    # greater than resting state correlations
    dict_pvals = {}
    dict_tvals = {}
    for data_type in data_types:
        for cond_name in cond_names:
            df_totest = df[[f'{data_type}_{cond_name}_task', f'{data_type}_{cond_name}_rest']]
            # print(df_totest)
            stats = df_totest.ptests(paired=True, stars=False, decimals=30, alternative='greater')
            # print(stats)
            p_val = stats.loc[f'{data_type}_{cond_name}_task', f'{data_type}_{cond_name}_rest']
            t_val = stats.loc[f'{data_type}_{cond_name}_rest', f'{data_type}_{cond_name}_task']
            dict_pvals[f'{data_type}_{cond_name}'] = float(p_val)
            dict_tvals[f'{data_type}_{cond_name}'] = float(t_val)

    print('p-vals')
    for key in dict_pvals.keys():
        print(f'{key}: {dict_pvals[key]}')

    print('t-vals')
    for key in dict_tvals.keys():
        print(f'{key}: {dict_tvals[key]}')
