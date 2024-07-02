% Author: Birgit Nierula
% nierula@cbs.mpg.de

function esg_prepro_loop1(subject, condition, srmr_nr, sampling_rate)

%% loop 1: downsample for ica and channel inspection (make plots for all subjects and conditions)

% set variables
subject_id = sprintf('sub-%03i', subject);
raw_path = [getenv('RAWDIR') subject_id '/eeg/'];
rpeak_path = [getenv('RPKDIR') subject_id '/'];
analysis_path = [getenv('ANADIR') subject_id '/esg/prepro/'];

if ~isfolder(analysis_path)
    mkdir(analysis_path);
end


% get condition info
[cond_info] = get_conditionInfo(condition, srmr_nr);
nblocks = cond_info.nblocks; 
cond_name = cond_info.cond_name;
cond_name2 = cond_info.cond_name2;
stimulation = cond_info.stimulation;
trigger_name = cond_info.trigger_name;


% get file names
cond_files = dir([raw_path '*' cond_name2 '*.set']);

if nblocks ~= size(cond_files, 1)
    error (['The number of files (' num2str(size(cond_files, 1)) ') does not equal the number of blocks (' num2str(nblocks) ') !!']) 
end

for iblock = 1:nblocks
    
    clearvars cnt 
    
    % load data
    cnt = pop_loadset('filename', cond_files(iblock).name , 'filepath', raw_path);
    % change event latencies to matlab convention
    if ~isempty(cnt.event)
        for ievent = 1:size(cnt.event, 2)
            cnt.event(ievent).latency = cnt.event(ievent).latency + 1;
        end
    end
    
    % select ESG channels
    [~, esg_chans, ~] = get_channels(subject, true, false, srmr_nr); % including ECG and excluding EOG channels
    idx_chans = find(ismember({cnt.chanlocs.labels}, esg_chans));
    cnt = pop_select(cnt, 'channel', idx_chans); 
    
    
    % remove stimulus artifact
    if stimulation ~= 0
        % interpolate stimulus artefact
        load([getenv('CFGDIR') 'interpolation_window.mat'], 'interpol_window')
        [brainstem_chans, cervical_chans, lumbar_chans, ref_chan] = get_esg_channels();
        cervical_idx = find(ismember({cnt.chanlocs.labels}, [brainstem_chans cervical_chans]));
        interpol_window_cervical = interpol_window.x(subject, 2:3);
        cnt = prepro_removeStimArtefact(cnt, trigger_name, ...
            interpol_window_cervical, cervical_idx, false);
        lumbar_idx = find(ismember({cnt.chanlocs.labels}, lumbar_chans));
        interpol_window_lumbar = interpol_window.x(subject, 4:5);
        cnt = prepro_removeStimArtefact(cnt, trigger_name, ...
            interpol_window_lumbar, lumbar_idx, false);
    end
    
    
    % downsample to r-peak detection sampling rate
    load([getenv('CFGDIR') 'cfg.mat'], 'srate_rpeak')
    cnt = pop_resample( cnt, srate_rpeak );
    cnt = eeg_checkset(cnt);
    
    
    % add R-peak info
    if srmr_nr == 1
        fname = ['noStimart_sr' num2str(srate_rpeak) '_rpeak_autocorrect_' cond_name '_' num2str(iblock) '_mancorr.set'];
    else
        fname = ['noStimart_sr' num2str(srate_rpeak) '_rpeak_autocorrect_ecgChan_' cond_name '_' num2str(iblock) '_mancorr.set'];
    end
    rpk = pop_loadset('filename', fname, 'filepath', rpeak_path);
    idx = find(ismember({rpk.event.type}, 'qrs'));
    tt_start = size(cnt.event, 2) + 1;
    tt_end = size(cnt.event, 2) + length(idx);
    counter = 0;
    for ievent = tt_start:tt_end
        counter = counter + 1;
        cnt.event(ievent).latency = rpk.event(idx(counter)).latency;
        cnt.event(ievent).type = rpk.event(idx(counter)).type;
        cnt.event(ievent).urevent = [];
        cnt.event(ievent).trial_type = 'rpeak';
        cnt.event(ievent).duration = [];
    end
    cnt = eeg_checkset(cnt);
    clear rpk
    
    
    % downsample to sampling_rate
    cnt = pop_resample( cnt, sampling_rate); 
    cnt = find_exactRpeaks(cnt, 'qrs', 'ECG', false);
    cnt = eeg_checkset(cnt);
    
    
    % append data sets 
    if iblock == 1
        cnt_all = cnt;
        cnt_all.block_info(iblock).condition = cnt.condition;
        cnt_all.block_info(iblock).session = cnt.session;
        cnt_all.block_info(iblock).start = 1;
        cnt_all.block_info(iblock).end = cnt.pnts;
    elseif iblock > 1
        start_idx = cnt_all.pnts + 1;
        cnt_all = pop_mergeset( cnt_all, cnt);
        cnt_all.block_info(iblock).condition = cnt.condition;
        cnt_all.block_info(iblock).session = cnt.session;
        cnt_all.block_info(iblock).start = start_idx;
        cnt_all.block_info(iblock).end = cnt_all.pnts;
    end
    
    clear cnt
    
end

% prepare variables for ECG removal 
[cnt, QRSevents, fwts] = prepro_prepare4ecgCleaning(cnt_all, esg_chans); % esg_chans need to include ECG!


% save  
fname = ['raw_' num2str(sampling_rate) '_spinal_' cond_name];
cnt = pop_saveset(cnt, 'filename', [fname '.set'], 'filepath', analysis_path);
save([analysis_path fname '.mat'], 'QRSevents', 'fwts');