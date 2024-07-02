% Author: Birgit Nierula (Feb, 2020)
% nierula@cbs.mpg.de

%% SRMR1: Manual R-peak detection
% --> to use after automatic detection steps (SRMR1_01_prepro_1_automatic_Rpeakdetection.m)
% Adapted from Ulrike

% Usage of manual r-peak selection tool:
% Input: some eeglab data (set file) with peaks as additional events
% Output: new file with old file name and _mancorr 

ana_dir = '/data/pt_02068/';
cfg_path =  [ana_dir 'analysis/final/scripts/cfg_srmr1/']; % here is important info for the analysis
% Add paths
addpath('/data/pt_02068/toolboxes/eeglab14_1_2b/')
addpath(genpath([ana_dir 'analysis/manuscript_sep/scripts/functions/']))
% Start EEGLab
eeglab; 
close 

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
            file_path = [analysis_path 'noStimart_sr5000_rpeak_autocorrect_' cond_name '_' num2str(iblock) '.set'];
            
            %% ===== manual peak detection =============
            % author: Ulrike Horn, uhorn@cbs.mpg.de
            setappdata(0, 'data_path', file_path);
            manual_rpeak_selection 
            uiwait(manual_rpeak_selection); 
            
        end
    end
end