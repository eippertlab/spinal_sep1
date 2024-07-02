###############################################################################################
# Emma Bailey, 17/06/2024
###############################################################################################

import numpy as np
from Functions.import_data_rs import import_data


if __name__ == '__main__':
    srmr_nr = 1  # Set the experiment number

    if srmr_nr == 1:
        n_subjects = 36  # Number of subjects
        subjects = np.arange(1, 37)  # 1 through 36 to access subject data
        conditions = [1]  # Conditions of interest
        sampling_rate = 1000  # Frequency to downsample to from original of 10kHz

    elif srmr_nr == 2:
        n_subjects = 24  # Number of subjects
        subjects = np.arange(1, 25)
        conditions = [1]  # Conditions of interest
        sampling_rate = 1000  # Frequency to downsample to from original of 10kHz

    ######## 1. Import ############
    import_d = True  # Prep work

    ############################################
    # Import preprocessed resting state data
    # Select channels to analyse
    # Remove 'stimulus artefact' by PCHIP interpolation
    # Downsample and concatenate blocks of the same conditions
    ############################################
    if import_d:
        for subject in subjects:
            for condition in conditions:
                import_data(subject, condition, srmr_nr, sampling_rate, esg_flag=True)
