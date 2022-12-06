% Author: Birgit Nierula
% nierula@cbs.mpg.de

function esg_prepro_loop6(subject, condition, srmr_nr)

debug_mode = false;

%% set variables
subject_id = sprintf('sub-%03i', subject);
analysis_path = [getenv('ANADIR') subject_id '/esg/prepro/'];
cfg_path = getenv('CFGDIR');

% get condition info
[cond_info] = get_conditionInfo(condition, srmr_nr);
cond_name = cond_info.cond_name;
trigger_name = cond_info.trigger_name;
nerve = cond_info.nerve;


%% load cleaned ESG data
load_path = [analysis_path 'ecgclean_' cond_name '/'];
fname = ['cnt_clean_ecg_spinal_' cond_name '.set'];
cnt = pop_loadset('filename', fname, 'filepath', load_path);
clear load_path

%% remove bad channels, do not interpolate them
save_path = [getenv('ESGDIR') subject_id '/'];
load([save_path 'artifacts.mat'], 'bad_channels')

if ~isempty(bad_channels)
    chan_idx = find(ismember({cnt.chanlocs.labels}, bad_channels));
    cnt_orig = cnt;
    cnt = pop_select(cnt, 'nochannel', chan_idx);
end


%% re-referenceing
% add reference channel to data
cnt.data(end + 1, :) = 0;
cnt.nbchan = size(cnt.data, 1);
if ~isempty(cnt.chanlocs)
    cnt.chanlocs(end + 1).labels = 'TH6';
end

% anterior reference
if nerve == 1
    cnt_antRef = rereference_myChannels(cnt, 'AC');
elseif nerve == 2
    cnt_antRef = rereference_myChannels(cnt, 'AL');
end


%% filtering
if srmr_nr == 1
    load([cfg_path 'cfg.mat'], 'esg_bp_freq', 'notch_freq')
    % bandpass filter
    [b_band, a_band] = butter(2, esg_bp_freq/(cnt.srate/2));
    % notch filter
    [b_notch, a_notch] = butter(2, notch_freq/(cnt.srate/2),'stop');
    
    
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
cnt_raw = cnt;
cnt.data = filtfilt(b_notch, a_notch, double(cnt.data)')';
cnt.data = filtfilt(b_band, a_band, double(cnt.data)')';
if ~isempty(cnt_antRef)
    cnt_antRef.data = filtfilt(b_notch, a_notch, double(cnt_antRef.data)')';
    cnt_antRef.data = filtfilt(b_band, a_band, double(cnt_antRef.data)')';
end

if debug_mode 
    figure;
    idx = find(ismember({cnt_raw.chanlocs.labels}, 'L1'));
    plot(cnt_raw.times, cnt_raw.data(idx, :), 'k'); hold on
    plot(cnt.times, cnt.data(idx, :), 'b')
    waitforbuttonpress
end

%% identify bad intervals in continuous data
cutoff_threshold = 100; % uV
cutoff_range = 200; % msec
[~, artifact_info] = trimOutlier_esg(cnt, cutoff_threshold, cutoff_range);        
rejectDataIntervals = artifact_info.rejectDataIntervals;
if debug_mode
    figure; hold on
    for ii=1:size(rejectDataIntervals, 1)
        x_min = rejectDataIntervals(ii, 1); x_max = rejectDataIntervals(ii, 2);
        y_min = -300; y_max = 300;
        v = [x_min y_min; x_max y_min; x_max y_max; x_min y_max];
        f = [1 2 3 4];
        patch('Faces', f, 'Vertices', v, 'FaceColor', 'black', 'FaceAlpha', .5)
    end
    plot(cnt.times/1000*cnt.srate, cnt.data)
%     waitforbuttonpress
end


%% give every event a number
counter = 0;
for itrial = 1:size(cnt.event, 2)
    if isempty(find(ismember(trigger_name, cnt.event(itrial).type)))
        cnt.event(itrial).number = [];
        cnt_antRef.event(itrial).number = [];
    else
        counter = counter + 1;
        cnt.event(itrial).number = counter;
        cnt_antRef.event(itrial).number = counter;
    end
end

%% remove previously identified bad intervals
cnt1 = pop_select(cnt, 'nopoint', rejectDataIntervals);
if ~isempty(cnt_antRef)
    cnt_antRef = pop_select(cnt_antRef, 'nopoint', rejectDataIntervals);
end


%% remove previously identified bad channels
if ~isempty(artifact_info.rejectedChannels)
    chan_idx = find(ismember({cnt1.chanlocs.labels}, artifact_info.rejectedChannels));
    cnt1 = pop_select(cnt1, 'nochannel', chan_idx);
    if ~isempty(cnt_antRef)
        chan_idx = find(ismember({cnt_antRef.chanlocs.labels}, artifact_info.rejectedChannels));
        cnt_antRef = pop_select(cnt_antRef, 'nochannel', chan_idx);
    end
end



%% make epochs
load([cfg_path 'cfg.mat'], 'iv_epoch', 'iv_baseline')
iv_epoch = iv_epoch/1000;

% epoch data
epo = pop_epoch( cnt1, trigger_name, iv_epoch, 'newname', 'SpinalSEP Epochs', 'epochinfo', 'yes' );
if ~isempty(cnt_antRef)
    epo_antRef = pop_epoch( cnt_antRef, trigger_name, iv_epoch, 'newname', 'SpinalSEP Epochs', 'epochinfo', 'yes' );
end

% remove baseline
epo = pop_rmbase( epo, iv_baseline );
if ~isempty(cnt_antRef)
    epo_antRef = pop_rmbase( epo_antRef, iv_baseline );
end

% check data set
epo = eeg_checkset( epo );
if ~isempty(cnt_antRef)
    epo_antRef = eeg_checkset( epo_antRef );
end


% check which epochs were removed
artifact_info.epochnumber = [cnt.event.number];
artifact_info.eventincluded = zeros(1, length(artifact_info.epochnumber)); % all events in cleaned cnt
artifact_info.eventincluded([cnt1.event.number]) = 1;
artifact_info.epochincluded = zeros(1, length(artifact_info.epochnumber)); % all events in epo structure
for ii = 1:length(epo.epoch)
    idx = find(ismember(epo.epoch(ii).eventtype, trigger_name));
    if ~isempty(idx)
        stim_number = epo.epoch(ii).eventnumber{idx};
        artifact_info.epochincluded(stim_number) = 1;
    end
end



%% save data
fname = ['epo_cleanclean_' cond_name '.set'];
epo = pop_saveset(epo, 'filename', fname, 'filepath', save_path);
if ~isempty(cnt_antRef)
    fname = ['epo_antRef_cleanclean_' cond_name '.set'];
    epo_antRef = pop_saveset(epo_antRef, 'filename', fname, 'filepath', save_path);
end
% save artifact info
eval([cond_name '_artifact_info = artifact_info;']); 
fname = [save_path 'artifacts.mat'];
if exist(fname, 'file')
    save(fname, [cond_name '_artifact_info'], '-append')
else
    save(fname, [cond_name '_artifact_info'])
end

end

%% rereferencing
function cnt_new = rereference_myChannels(cnt, chan_name)

ref_idx = find(ismember({cnt.chanlocs.labels}, chan_name));
if ~isempty(ref_idx)
    cnt_new = pop_reref( cnt, ref_idx, 'keepref', 'on'); 
else
    cnt_new = [];
end

end
