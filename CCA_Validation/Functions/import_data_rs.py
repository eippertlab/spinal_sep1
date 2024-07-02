##########################################################################################
#                               This Script
# 1) imports the preprocessed resting state data
# 2) add stimulation trigger and remove the 'stimulus artifact' iv: -1.5 to 6 ms, for ESG use -7 to 7s
# 3) downsample the signal to 1000 Hz
# 4) Append mne raws of the same condition
# 6) saves the new raw structure
# Emma Bailey, June 2024
##########################################################################################

# Import necessary packages
import mne
from Functions.get_conditioninfo import *
from Functions.get_channels import *
from scipy.io import loadmat
import os
import glob
import numpy as np
import pandas as pd
from Functions.pchip_interpolation import PCHIP_interpolation


def import_data(subject, condition, srmr_nr, sampling_rate, esg_flag):
    subject_id = f'sub-{str(subject).zfill(3)}'
    cond_info = get_conditioninfo(condition, srmr_nr)

    if srmr_nr == 1:
        if esg_flag:
            save_path = "/data/p_02569/CCA_Validation/tmp_data/imported/" + subject_id
            input_path = f'/data/pt_02068/analysis/final/tmp_data/{subject_id}/esg/prepro/cnt_clean_controlAnalysis/'
        else:
            save_path = "/data/p_02569/CCA_Validation/tmp_data/imported_eeg/" + subject_id
            input_path = f'/data/pt_02068/analysis/final/tmp_data/{subject_id}/eeg/prepro/cnt_clean_controlAnalysis/'
        cond_names_trig = ['median', 'tibial']
        fnames_trig = ['cnt_antRef_cleanfiltered_median.set', 'cnt_antRef_cleanfiltered_tibial.set']
        trigger_names_trig = ['Median - Stimulation', 'Tibial - Stimulation']
        os.makedirs(save_path, exist_ok=True)
        cond_name = cond_info.cond_name

    elif srmr_nr == 2:
        if esg_flag:
            save_path = "/data/p_02569/CCA_Validation/tmp_data_2/imported/" + subject_id
            input_path = f'/data/pt_02151/analysis/final/tmp_data/{subject_id}/esg/prepro/cnt_clean_controlAnalysis/'
        else:
            save_path = "/data/p_02569/CCA_Validation/tmp_data_2/imported_eeg/" + subject_id
            input_path = f'/data/pt_02151/analysis/final/tmp_data/{subject_id}/eeg/prepro/cnt_clean_controlAnalysis/'
        os.makedirs(save_path, exist_ok=True)
        if condition == 1:
            cond_name = cond_info.cond_name
            cond_name2 = cond_info.cond_name  # rest
        else:
            cond_name = cond_info.cond_name   # med_digits/mixed and tib_digits/mixed
            cond_name2 = cond_info.cond_name2  # mediansensory/mixed or tibialsensory/mixed
        cond_names_trig = ['med_mixed', 'tib_mixed']
        fnames_trig = ['cnt_antRef_cleanfiltered_med_mixed.set', 'cnt_antRef_cleanfiltered_tib_mixed.set']
        trigger_names_trig = ['medMixed', 'tibMixed']
    else:
        print('Error: Experiment 1 or experiment 2 must be specified')
        exit()

    sampling_rate_og = 10000

    # Set interpolation window (different for eeg and esg data, both in seconds) - will still need to be done in resting
    # state data
    tstart_esg = -0.007
    tmax_esg = 0.007

    tstart_eeg = -0.0015
    tmax_eeg = 0.006
    nblocks = 1  # Only one resting state file ever, so fine to hardcode this

    # Find out which channels are which, include ECG, exclude EOG
    eeg_chans, esg_chans, bipolar_chans = get_channels(subject_nr=subject, includesEcg=False, includesEog=False,
                                                       study_nr=srmr_nr)

    # Repeat for median and tibial conditions
    # First run will add tibial triggers to resting state file and save
    # Second run will add median triggers to resting state file and save
    for fname_trig, cond_name_trig, trigger_name_trig in zip(fnames_trig, cond_names_trig, trigger_names_trig):
        if esg_flag and cond_name_trig in ['median', 'med_mixed']:
            fname_raw = 'cnt_antRef_cleanfiltered_rest_nerve1.set'
        elif esg_flag and cond_name_trig in ['tibial', 'tib_mixed']:
            fname_raw = 'cnt_antRef_cleanfiltered_rest_nerve2.set'
        elif not esg_flag:
            fname_raw = 'cnt_cleanfiltered_rest.set'

        ####################################################################
        # Read in raw rest, concatenate a few times, add triggers
        ####################################################################
        # load in resting state data - need to read in files from EEGLAB format in bids folder
        raw = mne.io.read_raw_eeglab(input_path+fname_raw, eog=(), preload=True, uint16_codec=None, verbose=None)

        # Drop channels of no interest
        if esg_flag:
            raw.pick_channels(esg_chans)
        else:
            raw.pick_channels(eeg_chans)

        # Downsample the data
        raw.resample(sampling_rate)  # resamples to desired

        raw_concat = raw  # Only one resting state file

        # Resting state files are WAY shorter than task-evoked files, going to replicate resting state *3
        # Repeat the resting state file 3 times before we add task-evoked triggers
        for i in np.arange(0, 3):
            mne.concatenate_raws([raw_concat, raw])

        # Load in task-evoked data
        raw_trig = mne.io.read_raw_eeglab(input_path + fname_trig, preload=True)
        # event_dict returns the event/trigger names with their corresponding event_id
        events, event_dict = mne.events_from_annotations(raw_trig)

        # Since the task-evoked files already have qrs triggers added, we need to be sure we isolate only the
        # stimulation triggers
        relevant_events = [list(event) for event in events if event[2] == event_dict[trigger_name_trig]]
        # Need to get indices of events linked to this trigger
        trigger_points = [event[0] for event in relevant_events]

        # Remove stimulus artefact and add identified triggers
        if esg_flag:
            interpol_window = [tstart_esg, tmax_esg]
            PCHIP_kwargs = dict(
                debug_mode=False, interpol_window_sec=interpol_window,
                trigger_indices=trigger_points, fs=sampling_rate
            )
            raw_concat.apply_function(PCHIP_interpolation, picks=esg_chans, **PCHIP_kwargs, n_jobs=len(esg_chans))
            raw_concat.annotations.append([x / sampling_rate for x in trigger_points], 0.0, trigger_name_trig,
                                          ch_names=[esg_chans] * len(trigger_points))  # Add annotation
            fname_save = f'{cond_name}_{cond_name_trig}.fif'

        elif not esg_flag:
            interpol_window = [tstart_eeg, tmax_eeg]
            PCHIP_kwargs = dict(
                debug_mode=False, interpol_window_sec=interpol_window,
                trigger_indices=trigger_points, fs=sampling_rate
            )
            raw_concat.apply_function(PCHIP_interpolation, picks=eeg_chans, **PCHIP_kwargs, n_jobs=len(eeg_chans))
            raw_concat.annotations.append([x / sampling_rate for x in trigger_points], 0.0, trigger_name_trig,
                                          ch_names=[eeg_chans] * len(trigger_points))  # Add annotation
            fname_save = f'{cond_name}_{cond_name_trig}.fif'

        else:
            raise RuntimeError('Flag has not been set - indicate if you are working with eeg or esg channels')

        ##############################################################################################
        # Add reference channel in case not in channel list
        ##############################################################################################
        # make sure recording reference is included
        mne.add_reference_channels(raw_concat, ref_channels=['TH6'], copy=False)  # Modifying in place,
        # adds the channel but doesn't do any actual re-referencing

        # Crop 5s after last relevant event
        # We do this just to avoid saving unnecessarily large files
        t_event = trigger_points[-1] / sampling_rate
        raw_concat.crop(tmin=0, tmax=t_event + 5)

        # Save data without stim artefact and down-sampled to 1000
        raw_concat.save(os.path.join(save_path, fname_save), fmt='double', overwrite=True)

        # Just deleting to be extra sure no crossover
        del raw, raw_concat
