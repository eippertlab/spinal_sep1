% Author: Birgit Nierula 
% nierula@cbs.mpg.de

%% SRMR1: ESG preprocessing - wrapper script

clear; clc

%% variables that need to be changed
% loop
loop_number = 8 
    
% subject index
subject_idx = [];


%% define variables and paths
% experiment
srmr_nr = 1;
% conditions
if loop_number < 3
    conditions = 1:3;
elseif loop_number == 10
    conditions = 1:3;
else
    conditions = 2:3;
end
% subjects
subjects = 2:36;
if ~isempty(subject_idx)
    new_subjects = subjects(subject_idx);
else
    new_subjects = subjects;
end
subjects = new_subjects
% sampling rate
sampling_rate = 1000;

% set paths
datadir = '/data/p_02068/SRMR1_experiment/analyzed_data/';
anadir = '/data/pt_02068/analysis/final/';
bidsdir = '/data/p_02068/SRMR1_experiment/bids/';
setenv('CFGDIR', '/data/pt_02068/analysis/manuscript_sep/scripts/cfg_srmr1/')

setenv('RAWDIR', bidsdir) % here is the raw data
setenv('RPKDIR', [datadir 'Rpeak_detected/']) % here R-peak detected data (holds only ECG channel and trigger info)
setenv('ANADIR', [anadir 'tmp_data/']) % analysis directory
setenv('ESGDIR', [datadir 'esg/']);
setenv('EEGDIR', [datadir 'prepro_eeg_icaclean/'])
setenv('BSDIR', [datadir 'bs/']);
setenv('OTHERDIR', [datadir 'other/']);
setenv('ZIMDIR', '/data/pt_02068/doc/LabBook_SRMR1/SRMR1/EXPERIMENT/preprocessing_ESG/');


% settings for figures
set(0, 'DefaulttextInterpreter', 'none')


% add toolboxes and other sources for scripts
addpath('/data/pt_02068/toolboxes/eeglab14_1_2b/') % eeglab toolbox
eeglab  % start eeglab and close gui
close


% scripts
functions_path = '/data/pt_02068/analysis/manuscript_sep/scripts/functions/';
addpath(genpath(functions_path)) % scripts

delete(gcp('nocreate')) % clear parallel pool

%% preprocessing loops
esg_preprocessing_loops(loop_number, subjects, conditions, srmr_nr, sampling_rate)


