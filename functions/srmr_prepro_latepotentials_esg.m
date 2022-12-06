% Author: Birgit Nierula
% nierula@cbs.mpg.de

function [epo] = srmr_prepro_latepotentials_esg(subject, condition, is_restcontrol, new_ref, srmr_nr)
%% prepro ESG with broadband filtering (loop 6 with different filtering)
% load ecg-clean ESG data
% filtering from 0.5-400 Hz + 50 Hz notch
% epoch
% remove bad channels
% remove bad epochs
% merge subjects

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
fname_stim = ['cnt_clean_ecg_spinal_' cond_name '.set'];
cnt = pop_loadset('filename', fname_stim, 'filepath', load_path);

if is_restcontrol
    cnt_stim = cnt; clear cnt

    load_path = [analysis_path 'ecgclean_rest/'];
    fname = ['cnt_clean_ecg_spinal_rest.set'];
    cnt_rest = pop_loadset('filename', fname, 'filepath', load_path);
    clear load_path

    %% create triggers in rest data
    % add as many rest data sets to each other to recreate the applied triggers
    % during the stimualtion condition
    rest_length = cnt_rest.pnts; % in samples
    stim_idx = find(ismember({cnt_stim.event.type}, trigger_name));
    stim_latency = [cnt_stim.event(stim_idx).latency];

    counter = 0;
    latency_correction = 0;
    idx = 1;
    cnt = [];
    while idx(end) < numel(stim_idx)
        counter = counter + 1;
        latency_correction1 = latency_correction;
        tmp_latency = stim_latency - latency_correction;
        idx = find(tmp_latency > 0 & tmp_latency < rest_length);
        cnt_tmp = cnt_rest;
        n_events = length(cnt_tmp.event);
        if idx(end) == numel(stim_idx)
            idx_selected = stim_idx(idx);
            event_idx = n_events+1:n_events+numel(idx);
        else
            idx_selected = stim_idx(idx(1:end-1));
            event_idx = n_events+1:n_events+numel(idx)-1;
        end
        cnt_tmp.event(event_idx) = cnt_stim.event(idx_selected);
        for ii = event_idx
            cnt_tmp.event(ii).latency = cnt_tmp.event(ii).latency - latency_correction;
        end
        idx_next = stim_idx(idx(end-1));
        latency_correction2 = [cnt_stim.event(idx_next).latency] - latency_correction;
        latency_correction = latency_correction1 + latency_correction2;
        if counter == 1
            cnt = cnt_tmp;
        else
            cnt = pop_mergeset(cnt, cnt_tmp);
        end
        clear cnt_tmp
    end
    clear cnt_stim
end


%% remove bad channels, do not interpolate them
save_path = [getenv('ESGDIR') subject_id '/'];
load([save_path 'artifacts.mat'], 'bad_channels')

if ~isempty(bad_channels)
    chan_idx = find(ismember({cnt.chanlocs.labels}, bad_channels));
    cnt_orig = cnt;
    cnt = pop_select(cnt, 'nochannel', chan_idx);
end


if ~isempty(new_ref)
    %% re-referenceing
    % add reference channel to data
    cnt.data(end + 1, :) = 0;
    cnt.nbchan = size(cnt.data, 1);
    if ~isempty(cnt.chanlocs)
        cnt.chanlocs(end + 1).labels = 'TH6';
    end
    
    if strcmp(new_ref, 'FzRef')
        % Fz reference
        cnt = rereference_myChannels(cnt, 'Fz-TH6');
    elseif strcmp(new_ref, 'antRef')
        % anterior reference
        if nerve == 1
            cnt = rereference_myChannels(cnt, 'AC');
        elseif nerve == 2
            cnt = rereference_myChannels(cnt, 'AL');
        end
    end
end


%% filtering
if srmr_nr == 1
    load([cfg_path 'cfg.mat'], 'esg_bp_late', 'notch_freq')
    esg_bp_freq = esg_bp_late;
    % bandpass filter
    [b_band, a_band] = butter(2, esg_bp_freq/(cnt.srate/2));
    % notch filter
    [b_notch, a_notch] = butter(2, notch_freq/(cnt.srate/2),'stop');
    
    
elseif srmr_nr == 2
    esg_bp_freq = [5 400];
    notch_freq = [48 50];
    % bandpass filter
    [b_band, a_band] = butter(2, esg_bp_freq/(cnt.srate/2));
    % notch filter
    [b_notch, a_notch] = butter(2, notch_freq/(cnt.srate/2),'stop');
%     load([cfg_path 'cfg.mat'], 'esg_bp_freq')
%     % comb filter
%     fo = 50;
%     q = 35;
%     bw = (fo/(cnt.srate/2))/q;
%     [b_notch, a_notch] = iircomb(cnt.srate/fo, bw, 'notch');
%     % bandpass filter
%     [b_band, a_band] = butter(2, esg_bp_freq/(cnt.srate/2));
        
end

% filter data (zero phase filtering)
cnt_nofilt = cnt;
cnt.data = filtfilt(b_notch, a_notch, double(cnt.data)')';
cnt.data = filtfilt(b_band, a_band, double(cnt.data)')';

if debug_mode 
    figure;
    idx = find(ismember({cnt_nofilt.chanlocs.labels}, 'L1'));
    plot(cnt_nofilt.times, cnt_nofilt.data(idx, :), 'k'); hold on
    plot(cnt.times, cnt.data(idx, :), 'b')
    waitforbuttonpress
end
clear cnt_nofilt


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
    else
        counter = counter + 1;
        cnt.event(itrial).number = counter;
    end
end

%% remove previously identified bad intervals
cnt1 = pop_select(cnt, 'nopoint', rejectDataIntervals);


%% remove previously identified bad channels
if ~isempty(artifact_info.rejectedChannels)
    chan_idx = find(ismember({cnt1.chanlocs.labels}, artifact_info.rejectedChannels));
    cnt1 = pop_select(cnt1, 'nochannel', chan_idx);
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



% %% save data
% if is_restcontrol
%     fname = ['epo_cleanclean_broadband_' cond_name '_restcontrol.set'];
% else
%     fname = ['epo_cleanclean_broadband_' cond_name '.set'];
% end
% epo = pop_saveset(epo, 'filename', fname, 'filepath', save_path);
% 
% % save artifact info
% fname = [save_path 'artifacts.mat'];
% if is_restcontrol
%     eval([cond_name '_bb_restcntrl_artifact_info = artifact_info;']);
%     if exist(fname, 'file')
%         save(fname, [cond_name '_bb_restcntrl_artifact_info'], '-append')
%     else
%         save(fname, [cond_name '_bb_restcntrl_artifact_info'])
%     end
% else
%     eval([cond_name '_bb_artifact_info = artifact_info;']);
%     if exist(fname, 'file')
%         save(fname, [cond_name '_bb_artifact_info'], '-append')
%     else
%         save(fname, [cond_name '_bb_artifact_info'])
%     end
% end



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
