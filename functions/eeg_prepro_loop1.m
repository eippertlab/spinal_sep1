% Author: Birgit Nierula
% nierula@cbs.mpg.de

function eeg_prepro_loop1(subject, condition, srmr_nr)

%% loop 1: downsample for ica and channel inspection (make plots for all subjects and conditions)


% set variables
subject_id = sprintf('sub-%03i', subject);
raw_path = [getenv('RAWDIR') subject_id '/eeg/'];
rpeak_path = [getenv('RPKDIR') subject_id '/'];
analysis_path = [getenv('ANADIR') subject_id '/eeg/prepro/'];
save_path = [getenv('EEGDIR') subject_id '/'];

if ~isfolder(analysis_path)
    mkdir(analysis_path);
end

% get condition info
[cond_info] = get_conditionInfo(condition, srmr_nr);
nblocks = cond_info.nblocks; 
cond_name = cond_info.cond_name;
stimulation = cond_info.stimulation;
trigger_name = cond_info.trigger_name;

% get file names
cond_files = dir([raw_path '*' cond_name '*.set']);

if nblocks ~= size(cond_files, 1)
    error (['The number of files (' num2str(size(cond_files, 1)) ') does not equal the number of blocks (' num2str(nblocks) ') !!']) 
end

for iblock = 1:nblocks
    
    clearvars cnt 
    
    % load data
    cnt = pop_loadset('filename', cond_files(iblock).name , 'filepath', raw_path);
    
    % select EEG channels
    [eeg_chans, ~, ~] = get_channels(subject, true, true, srmr_nr); % including ECG and EOG channels
    idx_chans = find(ismember({cnt.chanlocs.labels}, eeg_chans));
    cnt = pop_select(cnt, 'channel', idx_chans);
    
    % add channel locations (will not give locations to ECG and EOG channels)
    chanloc_file = '/data/pt_02296/cfg/standard-10-5-cap385_added_mastoids.elp';
    cnt = pop_chanedit(cnt, 'lookup', chanloc_file, 'eval', 'chans = pop_chancenter(chans, [], []);');
      
    
    % remove stimulus artifact
    if stimulation ~= 0
        % interpolate stimulus artefact
        load([getenv('CFGDIR') 'cfg.mat'], 'interpol_window') %[-1.5 4]
        cnt = prepro_removeStimArtefact(cnt, trigger_name, interpol_window, 1:size({cnt.chanlocs.labels}, 2), 1);
        close
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
    cnt.event = rpk.event;
    cnt.urevent = rpk.urevent;
    cnt.eventdescription = rpk.eventdescription;
    cnt = eeg_checkset(cnt);
    
   
    % save
    fname = ['noStimart_sr' num2str(srate_rpeak) '_' cond_name '_' num2str(iblock) '.set'];
    cnt = pop_saveset(cnt, 'filename', fname , 'filepath', analysis_path);
    
    
    % downsample to ica sampling rate
    load([getenv('CFGDIR') 'cfg.mat'], 'srate_ica')
    cnt = pop_resample( cnt, srate_ica );
    cnt = eeg_checkset(cnt);
    
    
    % identify bad channels
    % -------------------------
    % exclude ecg
    idx = find(ismember({cnt.chanlocs.labels}, {'ECG' 'EOGH' 'EOGV'}));
    cnt1 = pop_select(cnt, 'nochannel', idx);
    
    % 1) using the spectrum
    h = figure('units','normalized','outerposition',[0 0 1 1]);
    pop_spectopo(cnt1, 1, [], 'EEG' , 'percent', 100, 'freqrange',[1 100],'electrodes','off'); % spectrogram
    title([subject_id ' ' cond_name ' ' num2str(iblock)])
    % save plots of all subjects
    export_fig([getenv('ANADIR') 'Channel_inspection_powerSpectrum.pdf'], '-pdf', '-append', h)
    close

    % 2) using log-RMS
    wait4input = false; % do not wait for user input!
    bad_channels = prepro_check4badChannels(cnt1, trigger_name, wait4input, []);
    title([subject_id ' ' cond_name ' ' num2str(iblock)])
    % save plots for all subjects
    export_fig([getenv('ANADIR') 'Channel_inspection_check4badChannels.pdf'], '-pdf', '-append')
    close

    % save data
    fname = ['noStimart_sr' num2str(srate_ica) '_' cond_name '_' num2str(iblock) '.set'];
    cnt = pop_saveset(cnt, 'filename', fname, 'filepath', analysis_path);
    
    % save empty variable for bad channels 
    % (will be later changed for those subjects where channels are removed)
    save([analysis_path cond_name '_' num2str(iblock) '_artifacts.mat'], 'bad_channels')
    save([save_path cond_name '_' num2str(iblock) '_artifacts.mat'], 'bad_channels')
       
end

