% Author: Birgit Nierula (Feb, 2020)
% nierula@cbs.mpg.de

%% SRMR1: Import data from BIDS folder
% This script 
% 1) imports the median and tibial stimulation blocks from the bids folder
% 2) removes the stimulus artifact iv: -1.5 to 1.5 ms
% 3) downsamples the signal to 5000 Hz

%% Prep
srmr_nr = 1;
ana_dir = '/data/pt_02068/';
cfg_path =  [ana_dir 'analysis/manuscript_sep/scripts/cfg_srmr1/']; % here is important info for the analysis
% Add paths
addpath('/data/pt_02068/toolboxes/eeglab14_1_2b/')
addpath(genpath([ana_dir 'analysis/manuscript_sep/scripts/functions/']))
bids_dir = '/data/p_02068/SRMR1_experiment/bids/';
% Start EEGLab
eeglab; 
close

n_subjects = 36;

for subject = 1:n_subjects
    
    % set environment variables and add paths
    subject_id = sprintf('sub-%03i', subject);
    raw_path = [bids_dir subject_id '/eeg/']; % here is the raw data for this subject in eeglab format   
    analysis_path = [ana_dir 'analysis/final/tmp_data/' subject_id '/'];
    if ~exist(analysis_path, 'dir')
        mkdir(analysis_path)
    end

    
    %% ===== 1) load data =============
    % define different endings for each block
    for condition = 1:3
        
        % get file names and number of blocks
        [cond_info] = get_conditionInfo(condition, srmr_nr);
        cond_name = cond_info.cond_name;
        stimulation = condition - 1;
        trigger_name = cond_info.trigger_name;

        % get file names
        cond_files = dir([raw_path '*' cond_name '*.set']);
        nblocks = size(cond_files, 1);
        
        for iblock = 1:nblocks
            
            % load data
            fname = cond_files(iblock).name;
            cnt = pop_loadset('filename', fname, 'filepath', raw_path);
            
             % change event latencies to matlab convention
             if ~isempty(cnt.event)
                 for ievent = 1:size(cnt.event, 2)
                     cnt.event(ievent).latency = cnt.event(ievent).latency + 1;
                 end
             end
        
            %% ===== 2) remove stimulus artefact =============
            remove_stimart = true;
            
            if remove_stimart
                if stimulation ~= 0
                    % interpolate stimulus artefact
                    load([cfg_path 'cfg.mat'], 'interpol_window_rpeak')
                    cnt = prepro_removeStimArtefact(cnt, trigger_name, interpol_window_rpeak, 1:size({cnt.chanlocs.labels}, 2), 1);
                    close
                end
            end

            %% ===== 3) downsample =============
            % new sampling rate
            load([cfg_path 'cfg.mat'], 'srate_rpeak') % 5000 Hz
            cnt = pop_resample(cnt, srate_rpeak);
            cnt = eeg_checkset(cnt);

            %% ===== 4) save =============
            fname_new = ['noStimart_sr' num2str(srate_rpeak) '_' cond_name '_' num2str(iblock) '.set'];
            cnt = pop_saveset(cnt, 'filename', fname_new, 'filepath', analysis_path);
            clear cnt
        end
    end

end

    
    
