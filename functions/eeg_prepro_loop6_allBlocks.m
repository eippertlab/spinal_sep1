% Author: Birgit Nierula
% nierula@cbs.mpg.de

function eeg_prepro_loop6_allBlocks(subjects, conditions, srmr_nr)

%% loop(s) 6: run ICA on pre-cleaned, sub-sampled, filtered data

% prepare data set for parfor loop
all_EEG = {};
sbj_counter = 0;
cds_matrix = zeros(9, 64);
for subject = subjects % pre-loop to load in data (in order to make parfor work)
    sbj_counter = sbj_counter + 1;
    subject_id = sprintf('sub-%03i', subject);
    analysis_path = [getenv('ANADIR') subject_id '/eeg/prepro/'];
    save_path = [getenv('EEGDIR') subject_id '/'];
    load([getenv('ANADIR') 'included_blocks.mat'], 'blocks')    
    blk_counter = 0;
    
    for condition = conditions
        % define stimulation conditions
        [cond_info] = get_conditionInfo(condition, srmr_nr);
        nblocks = blocks{subject}{condition};
        cond_name = cond_info.cond_name;
        
        
        % load previous preprocessing step
        load([getenv('CFGDIR') 'cfg.mat'], 'srate_ica')
        for iblock = nblocks
            % load data
            load([analysis_path cond_name '_' num2str(iblock) '_artifacts.mat'], 'bad_channels')
            blk_counter = blk_counter + 1;
            EEG = pop_loadset([analysis_path cond_name '_' num2str(iblock) '_clean_beforeICA.set']);
            
            % index with channels that were interpolated 
            if ~isempty(bad_channels)
                chan_idx = find(ismember({EEG.chanlocs.labels}, bad_channels));
                cds_matrix(blk_counter, chan_idx) = 1;
            end
            
            % merge EEG
            if blk_counter == 1
                EEG_merged = EEG;
            else
                EEG_merged = pop_mergeset(EEG_merged, EEG);
            end
            clear EEG
            
        end
    end
    EEG = EEG_merged; clear EEG_merged
    
    % write data into structured variable
    all_EEG{sbj_counter} = EEG; % put single datasets in one big variable
    
    % define rank for pca
    if srmr_nr == 1
        other_chans = 1; % only ECG
    elseif srmr_nr == 2
        other_chans = 3; % ECG + EOG
    end
    inpol_chans = find(mean(cds_matrix, 1) > 0);
    
    if ~isempty(inpol_chans)
        orig_chans = rank(double(EEG.data')) - length(inpol_chans); % number of original channels
    else
        orig_chans = rank(double(EEG.data')); % number of original channels
    end
    % write rank, file name, and path into structured variable
    data_rank{sbj_counter} = orig_chans - other_chans;
    file_name{sbj_counter} = ['allConditions_sr' num2str(srate_ica) 'Hz_ICA.set'];
    file_path{sbj_counter} = analysis_path;
    savefile_path{sbj_counter} = save_path;
    clear EEG
    
end



% run ica
tic
parfor s = 1:length(all_EEG) % or choose other dataset indices from [1 80]
    EEG = all_EEG{s}; % get dataset from group variable
    
    % select channel indexes
    includesEcg = false; includesEog = false;
    [eeg_chans, ~, ~] = get_channels(subject, includesEcg, includesEog, srmr_nr); % select channels
    idx_chans = find(ismember({EEG.chanlocs.labels}, eeg_chans));
    
    
    % run ICA
    dataRank = data_rank{s};
    EEG = pop_runica(EEG, 'icatype', 'runica', 'pca', dataRank , 'dataset', 1, 'options', {'extended' 1}, 'chanind', idx_chans); % run Infomax ICA
    
    
    % put dataset, now containing ICA weights, back to group variable
    all_EEG{s} = EEG;     
    tokens = regexp( EEG.filename, '_(\d+)_', 'tokens' );
    block = cat( 1, tokens{:} ) ;

    disp('######')
    disp(['ICA COMPLETED FOR:    ' EEG.subject '_' EEG.condition '_' block{1}])
    disp('######')
end
toc

clear tokens


% separate data sets and save
for s = 1:length(all_EEG) % loop for saving ICA weights (pop_saveset does not work inside parfor loop)
    EEG = all_EEG{s};
    subject_name = EEG.subject;
    
    if ~isempty(EEG.icaweights)   
        EEG = pop_saveset(EEG, 'filename', file_name{s}, 'filepath', file_path{s});
        EEG = pop_saveset(EEG, 'filename', file_name{s}, 'filepath', savefile_path{s});
        disp([subject_name '_allBlocks: dataset with ICA saved.'])
    else
        disp([subject_name '_allBlocks: no ICA in this dataset.'])
    end
end
