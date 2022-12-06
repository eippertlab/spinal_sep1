% Author: Birgit Nierula
% nierula@cbs.mpg.de

%% EEG preprocessing wrapper script

clear; clc
delete(gcp('nocreate')) % clear parallel pool

%% variables that need to be changed
% loop
loop_number = 1
disp(['loop number = ' num2str(loop_number)])
% subject, condition, and block info
subject_idx = 1:36; 
condition_idx = 2:3;
% ica info
chan_name = 'C4';
iso_latency = [20 39]; % latency of isopotnetial plots to stimulus
display_time = 2; % duration (in seconds) the continuous raw and ica data of one channel are displayed on the screen



%% define variables and paths
% experiment
srmr_nr = 1;
% conditions
conditions = 1:3;
% subjects
subjects = 1:36;

% set paths
datadir = '/data/p_02068/SRMR1_experiment/analyzed_data/';
anadir = '/data/pt_02068/analysis/';
bidsdir = '/data/p_02068/SRMR1_experiment/bids/';
setenv('CFGDIR', [anadir 'manuscript_sep/scripts/cfg_srmr1/'])

setenv('RAWDIR', bidsdir) % here is the raw data
setenv('RPKDIR', [datadir 'Rpeak_detected/']) % here R-peak detected data (holds only ECG channel and trigger info)
setenv('ANADIR', [anadir 'final/tmp_data/']) % analysis directory
setenv('EEGDIR', [datadir 'prepro_eeg_icaclean/'])
setenv('ZIMDIR', '/data/pt_02068/doc/LabBook_SRMR1/SRMR1/EXPERIMENT/preprocessing_EEG/');


% settings for figures
set(0, 'DefaulttextInterpreter', 'none')

% add toolboxes and other sources for scripts
addpath('/data/pt_02068/toolboxes/eeglab2019_1/') % eeglab toolbox
eeglab  % start eeglab and close guiclear
close


% all scripts for shks are lying here (for both srmr experiments)
functions_path = '/data/pt_02068/analysis/manuscript_sep/scripts/functions/';
addpath(genpath(functions_path)) % scripts


eeg_preprocessing_loops(srmr_nr, loop_number, subjects, conditions, ...
    subject_idx, condition_idx, chan_name, display_time, iso_latency)
