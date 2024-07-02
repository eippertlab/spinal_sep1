% Author: Birgit Nierula (May, 2020)
% nierula@cbs.mpg.de

%% Define individual interpolation windows

% This script follows SRMR1_01_prepro_3_removeDoubleDetections.m

srmr_nr = 1;
ana_dir = '/data/pt_02068/';
cfg_path =  [ana_dir 'analysis/manuscript_sep/scripts/cfg_srmr1/']; % here is important info for the analysis
bids_dir = '/data/p_02068/SRMR1_experiment/bids/';
% Add paths
addpath('/data/pt_02068/toolboxes/eeglab14_1_2b/')
addpath(genpath([ana_dir 'analysis/manuscript_sep/scripts/functions/']))
% Start EEGLab
eeglab; 
close 

n_subjects = 36;

for subject = 1:n_subjects
    out  = prepro_defineInterpolWindow(subject, srmr_nr, bids_dir);
    interpol_window.columNames = {'subject_id' 'cervical_start' 'cervical_end' 'lumbar_start' 'lumbar_end'};
    interpol_window.x(subject, :) = out;
end

save([cfg_path 'interpolation_window.mat'], 'interpol_window')