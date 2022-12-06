% Author: Birgit Nierula (Mai, 2020)
% nierula@cbs.mpg.de

%% Remove double detections of R-peaks
%% --> to use after manual detection steps

% This script follows SRMR1_01_prepro_2_manualPeakDetection.m
% The script removes double detected qrs triggers

ana_dir = '/data/pt_02068/';
sav_dir = '/data/p_02068/SRMR1_experiment/analyzed_data/Rpeak_detected/';
cfg_path =  [ana_dir 'analysis/manuscript_sep/scripts/cfg_srmr1/']; % here is important info for the analysis
% Add paths
addpath('/data/pt_02068/toolboxes/eeglab14_1_2b/')
addpath(genpath([ana_dir 'analysis/manuscript_sep/scripts/functions/']))
save_dir = 'analyzed_data/Rpeak_detected/';
% Start EEGLab
eeglab; 
close 

srmr_nr = 1;
n_subjects = 36;

for subject = 1:n_subjects
    
    % set path
    subject_id = sprintf('sub-%03i', subject);
    analysis_path = [ana_dir 'analysis/final/tmp_data/' subject_id '/'];
    save_path = [sav_dir subject_id '/'];
    
    % define different endings for each block
    for condition = 1:3
        [cond_info] = get_conditionInfo(condition, srmr_nr);
        cond_name = cond_info.cond_name;
        nblocks = cond_info.nblocks;
        
        for iblock = 1:nblocks
            
            
            %% ===== load data =============
            file_name = ['noStimart_sr5000_rpeak_autocorrect_' cond_name '_' num2str(iblock) '_mancorr.set'];
            cnt = pop_loadset('filename', file_name, 'filepath', analysis_path);
            
            %% ===== remove double-detections =============
            cnt = ecg_removeDoubleDetections(cnt);
            
            %% ===== save data =============
            cnt = pop_saveset(cnt, 'filename', file_name, 'filepath', save_path);
            
        end
    end
    ff = dir([analysis_path 'noStimart_*']);
    for ifile = 1:size(ff,1)
        delete([analysis_path ff(ifile).name])
    end
end