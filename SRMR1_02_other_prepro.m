% Author: Birgit Nierula 
% nierula@cbs.mpg.de

%% other preprocessing wrapper script
% --> ENG preprocessing

clear; clc
delete(gcp('nocreate')) % clear parallel pool

%% variables that need to be changed
% loop
loop_number = 1
% subject, condition, and block info
subject_idx = []; 
condition_idx = [];


%% define variables and paths
% experiment
srmr_nr = 1;
% conditions
conditions = 2:3;
if ~isempty(condition_idx)
    conditions = conditions(condition_idx);
end
conditions
% subjects
subjects = 1:36;
if ~isempty(subject_idx)
    subjects = subjects(subject_idx);
end
subjects
sampling_rate = 1000;


% set paths
datadir = '/data/p_02068/SRMR1_experiment/analyzed_data/';
anadir = '/data/pt_02068/analysis/final/';
bidsdir = '/data/p_02068/SRMR1_experiment/bids/';
setenv('CFGDIR', '/data/pt_02068/analysis/manuscript_sep/scripts/cfg_srmr1/')

setenv('RAWDIR', bidsdir) % here is the raw data
setenv('RPKDIR', [datadir 'Rpeak_detected/']) % here R-peak detected data (holds only ECG channel and trigger info)
setenv('ANADIR', [anadir 'tmp_data/']) % analysis directory
setenv('EEGDIR', [datadir 'prepro_eeg_icaclean/'])
setenv('ESGDIR', [datadir 'esg/']);
setenv('BSDIR', [datadir 'bs/']);
setenv('OTHERDIR', [datadir 'other/']);
setenv('ZIMDIR', '/data/pt_02068/doc/LabBook_SRMR1/SRMR1/EXPERIMENT/preprocessing_other/');


% settings for figures
set(0, 'DefaulttextInterpreter', 'none')

% add toolboxes and other sources for scripts
addpath('/data/pt_02068/toolboxes/eeglab2019_1/') % eeglab toolbox
eeglab  % start eeglab and close guiclear
close


% all scripts are  here (for both srmr experiments)
functions_path = '/data/pt_02068/analysis/manuscript_sep/scripts/functions/';
addpath(genpath(functions_path)) % scripts



other_preprocessing_loops(srmr_nr, loop_number, subjects, conditions, sampling_rate)

