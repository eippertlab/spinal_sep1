% Author: Birgit Nierula (Feb, 2020)
% nierula@cbs.mpg.de

%% SRMR_01: automatic R-peak detection
% This script was run after the sript SRMR1_00_importData.m and 
% 1) performs an automatic R-peak detection on the ECG channel

ana_dir = '/data/pt_02068/';
cfg_path =  [ana_dir 'analysis/manuscript_sep/scripts/cfg_srmr1/']; % here is important info for the analysis
% Add paths
addpath('/data/pt_02068/toolboxes/eeglab14_1_2b/');
addpath(genpath([ana_dir 'analysis/manuscript_sep/scripts/functions/']))
% Start EEGLab
eeglab; 

srmr_nr = 1;
n_subjects = 36;

for subject = 1:n_subjects
    
    % set path
    analysis_path = [ana_dir 'analysis/final/tmp_data/' sprintf('sub-%03i', subject) '/'];
    
    % define different endings for each block
    for condition = 1:3
        [cond_info] = get_conditionInfo(condition, srmr_nr);
        cond_name = cond_info.cond_name;
        nblocks = cond_info.nblocks;
        
        for iblock = 1:nblocks
            
            
            %% ===== load data =============
            load([cfg_path 'cfg.mat'], 'srate_rpeak')
            fname = ['noStimart_sr' num2str(srate_rpeak) '_' cond_name '_' num2str(iblock) '.set'];
            cnt = pop_loadset('filename', fname, 'filepath', analysis_path);
            
            
            %% ===== R-peak detection =============
            % select ECG channel
            [~, idx] = ismember({cnt.chanlocs.labels}, {'ECG'});
            ecg_channel = find(idx);
            cnt = pop_select(cnt, 'channel', ecg_channel);

            % run qrs detection plugin from fmrib toolbox
            ecg_channel = 1;
            cnt_qrs = pop_myfmrib_qrsdetect(cnt, ecg_channel, 'qrs', 'no');
            cnt = cnt_qrs; 
            
            
            %% ===== save =============
            fname_new = ['noStimart_sr' num2str(srate_rpeak) '_rpeak_autocorrect_' cond_name '_' num2str(iblock) '.set'];
            cnt = pop_saveset(cnt, 'filename', fname_new, 'filepath', analysis_path);
            
            % clear unnecessary variables
            clearvars -except subjects subject condition cond_name iblock cfg_path srmr_nr analysis_path
        end
    end
end