% Author: Birgit Nierula
% nierula@cbs.mpg.de

function eeg_prepro_loop8(subject, condition, srmr_nr, sampling_rate)

debug_mode = false;

%% set variables
subject_id = sprintf('sub-%03i', subject);
analysis_path = [getenv('ANADIR') subject_id '/eeg/prepro/']; 
if ~isfolder(analysis_path)
    mkdir(analysis_path);
end
raw_path = [getenv('RAWDIR') subject_id '/eeg/'];
rpeak_path = [getenv('RPKDIR') subject_id '/'];
ica_path = [getenv('EEGDIR') subject_id '/'];
cfg_path = getenv('CFGDIR');

% get condition info
[cond_info] = get_conditionInfo(condition, srmr_nr);
cond_name = cond_info.cond_name;
trigger_name = cond_info.trigger_name;
stimulation = cond_info.stimulation;
cond_name2 = cond_info.cond_name2;


%% load cleaned EEG data
bad_chans = [];
file = dir([raw_path subject_id '_task-' cond_name2 '_run-*_eeg.set']);
for iblock = 1:length(file)
    
    % load data
    cnt1 = pop_loadset('filename', file(iblock).name , 'filepath', raw_path);
    
    
    % select EEG channels
    [eeg_chans, ~, ~] = get_channels(subject, true, true, srmr_nr); % including ECG and EOG channels
    idx_chans = find(ismember({cnt1.chanlocs.labels}, eeg_chans));
    cnt1 = pop_select(cnt1, 'channel', idx_chans);
    
         
    % remove stimulus artifact
    if stimulation ~= 0
        % interpolate stimulus artefact
        load([getenv('CFGDIR') 'interpolation_window.mat'], 'interpol_window') 
        interpol_window_eeg = interpol_window.x(subject, 2:3); % takes the same interpolation window used for cervical channels
        cnt1 = prepro_removeStimArtefact(cnt1, trigger_name, interpol_window_eeg, 1:size({cnt1.chanlocs.labels}, 2), 1);
        close
    end 
    
    % downsample 
    cnt1 = pop_resample( cnt1, sampling_rate);
    cnt1 = eeg_checkset(cnt1);
    
    % load bad channel info 
    load([ica_path cond_name '_' num2str(iblock) '_artifacts.mat'], 'bad_channels')
    if ~isempty(bad_channels)
        bad_chans = unique([bad_chans bad_channels]);    
    end
    
    % merge data sets
    if iblock == 1
        cnt_raw = cnt1;
    else
        cnt_raw = pop_mergeset(cnt_raw, cnt1);
    end
    
    clear cnt1
end

%% remove bad channels
if ~isempty(bad_chans)

    chan_idx = find(ismember({cnt_raw.chanlocs.labels}, bad_chans ));
    cnt = pop_select(cnt_raw, 'nochannel', chan_idx); clear chan_idx idx
    % add channel locations - needed for interpolation
    chanloc_file = [getenv('CFGDIR') 'standard-10-5-cap385_added_mastoids.elp'];
    cnt = pop_chanedit(cnt, 'lookup', chanloc_file, 'eval', 'chans = pop_chancenter(chans, [], []);');
    cnt = eeg_checkset(cnt);
    % interpolate removed channels
    cnt = pop_interp(cnt, cnt_raw.chanlocs, 'spherical');
else
    cnt = cnt_raw;
end

%% remove ICA components
% load ICA info
load([ica_path 'allConditions_ICAcomps_marked_for_rejection.mat'], 'marked_comps_SASICA')
cnt_ica = pop_loadset('filename', 'allConditions_sr250Hz_ICA.set', 'filepath', ica_path );

cnt.comprej = marked_comps_SASICA.all;
cnt.icaact = cnt_ica.icaact;
cnt.icawinv = cnt_ica.icawinv;
cnt.icasphere = cnt_ica.icasphere;
cnt.icaweights = cnt_ica.icaweights; 

% remove unnecessary channels
idx_chans = find(ismember({cnt.chanlocs.labels}, {'ECG' 'EOGH' 'EOGV'}));
cnt = pop_select(cnt, 'nochannel', idx_chans);

% remove selected ICA components
cnt = pop_subcomp(cnt, [cnt.comprej], 0);
cnt = eeg_checkset(cnt);


%% re-referenceing
% add reference channel to data
cnt.data(end + 1, :) = 0;
cnt.nbchan = size(cnt.data, 1);
if ~isempty(cnt.chanlocs)
    cnt.chanlocs(end + 1).labels = 'RM';
end

% rereferenced average ref
cnt = pop_reref( cnt, []);

% add channel locations
chanloc_file = [getenv('CFGDIR') 'standard-10-5-cap385_added_mastoids.elp'];
cnt = pop_chanedit(cnt, 'lookup', chanloc_file, 'eval', 'chans = pop_chancenter(chans, [], []);');



%% filtering
if srmr_nr == 1
    load([cfg_path 'cfg.mat'], 'esg_bp_freq', 'notch_freq')
    % notch filter
    [b_notch, a_notch] = butter(2, notch_freq/(cnt.srate/2),'stop');
      
    % bandpass filter
    [b_band, a_band] = butter(2, esg_bp_freq/(cnt.srate/2));
       
elseif srmr_nr == 2
    load([cfg_path 'cfg.mat'], 'esg_bp_freq')
    % comb filter
    fo = 50;
    q = 35;
    bw = (fo/(cnt.srate/2))/q;
    [b_notch, a_notch] = iircomb(cnt.srate/fo, bw, 'notch');
    
    % bandpass filter
    [b_band, a_band] = butter(2, esg_bp_freq/(cnt.srate/2));
        
end

% filter data (zero phase filtering)
cnt.data = filtfilt(b_notch, a_notch, double(cnt.data)')';
cnt.data = filtfilt(b_band, a_band, double(cnt.data)')';


if debug_mode 
    figure;
    idx = find(ismember({cnt_raw.chanlocs.labels}, 'CP4'));
    plot(cnt_raw.times, cnt_raw.data(idx, :), 'k'); hold on
    plot(cnt.times, cnt.data(idx, :), 'b')
    legend({'ica-clean' 'ica-clean+filt'})
    waitforbuttonpress
end


%% identify bad EEG intervals
amplitudeThreshold_hf = 60;
pointSpreadWidth = 200; %in ms
maxThreshold_lf = 120;
[~, artifact_info] = trimOutlier_adjust_Eoin(cnt, maxThreshold_lf, amplitudeThreshold_hf, pointSpreadWidth);
rejectDataIntervals = artifact_info.rejectDataIntervals;

%% remove previously identified bad intervals
counter = 0;
for itrial = 1:size(cnt.event, 2)
    if isempty(find(ismember(trigger_name, cnt.event(itrial).type)))
        cnt.event(itrial).number = [];
    else
        counter = counter + 1;
        cnt.event(itrial).number = counter;
    end
end
    
cnt1 = pop_select(cnt, 'nopoint', rejectDataIntervals);

%% remove previously identified bad channels
if ~isempty(artifact_info.rejectedChannels)
    chan_idx = find(ismember({cnt1.chanlocs.labels}, artifact_info.rejectedChannels));
    cnt2 = pop_select(cnt1, 'nochannel', chan_idx);
    cnt1 = pop_interp(cnt2, cnt1.chanlocs, 'spherical');
end


%% make epochs
load([cfg_path 'cfg.mat'], 'iv_epoch', 'iv_baseline')
iv_epoch = iv_epoch/1000;

% epoch data
epo = pop_epoch( cnt1, trigger_name, iv_epoch, 'newname', 'SpinalSEP Epochs', 'epochinfo', 'yes' );

% remove baseline
epo = pop_rmbase( epo, iv_baseline );

% check data set
epo = eeg_checkset( epo );


% check which epochs were removed
artifact_info.rejectDataIntervals = rejectDataIntervals;
artifact_info.epochnumber = [cnt.event.number];
artifact_info.eventincluded = zeros(1, length(artifact_info.epochnumber));
artifact_info.eventincluded([cnt1.event.number]) = 1;
artifact_info.epochincluded = zeros(1, length(artifact_info.epochnumber));
for ii = 1:length(epo.epoch)
    idx = find(ismember(epo.epoch(ii).eventtype, trigger_name));
    if ~isempty(idx)
        stim_number = epo.epoch(ii).eventnumber(idx);
        artifact_info.epochincluded(stim_number) = 1;
    end
end


%% save data
fname = ['epo_avgRef_cleanclean_' cond_name '.set'];
epo = pop_saveset(epo, 'filename', fname, 'filepath', ica_path);
% save artiact info
eval([cond_name '_artifact_info = artifact_info;']); 
fname = [ica_path 'artifacts.mat'];
if exist(fname, 'file')
    save(fname, [cond_name '_artifact_info'], '-append')
else
    save(fname, [cond_name '_artifact_info'])
end

end

