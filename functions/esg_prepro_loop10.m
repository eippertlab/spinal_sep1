% Author: Birgit Nierula
% nierula@cbs.mpg.de

function esg_prepro_loop10(subject, condition, srmr_nr)

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

%% re-referenceing
% add reference channel to data
cnt.data(end + 1, :) = 0;
cnt.nbchan = size(cnt.data, 1);
if ~isempty(cnt.chanlocs)
    cnt.chanlocs(end + 1).labels = 'TH6';
end

% anterior reference
if condition == 1
    cnt_antRef_nerve1 = rereference_myChannels(cnt, 'AC');
    cnt_antRef_nerve2 = rereference_myChannels(cnt, 'AL');
end
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
% cnt_raw = cnt;
% cnt.data = filtfilt(b_notch, a_notch, double(cnt.data)')';
% cnt.data = filtfilt(b_band, a_band, double(cnt.data)')';
% if ~isempty(cnt_antRef)
if condition == 1
    cnt_antRef_nerve1.data = filtfilt(b_notch, a_notch, double(cnt_antRef_nerve1.data)')';
    cnt_antRef_nerve1.data = filtfilt(b_band, a_band, double(cnt_antRef_nerve1.data)')';
    
    cnt_antRef_nerve2.data = filtfilt(b_notch, a_notch, double(cnt_antRef_nerve2.data)')';
    cnt_antRef_nerve2.data = filtfilt(b_band, a_band, double(cnt_antRef_nerve2.data)')';
else
    cnt_antRef.data = filtfilt(b_notch, a_notch, double(cnt_antRef.data)')';
    cnt_antRef.data = filtfilt(b_band, a_band, double(cnt_antRef.data)')';
end


if condition == 1
    cnt_antRef_nerve1 = eeg_checkset( cnt_antRef_nerve1 );
    cnt_antRef_nerve2 = eeg_checkset( cnt_antRef_nerve2 );
else
    cnt_antRef = eeg_checkset( cnt_antRef );
end

%% save data
save_path = [analysis_path 'cnt_clean_controlAnalysis/'];
if ~isfolder(save_path)
    mkdir(save_path);
end

if condition == 1
    fname = ['cnt_antRef_cleanfiltered_' cond_name '_nerve1.set'];
    cnt_antRef_nerve1 = pop_saveset(cnt_antRef_nerve1, 'filename', fname, 'filepath', save_path);
    fname = ['cnt_antRef_cleanfiltered_' cond_name '_nerve2.set'];
    cnt_antRef_nerve2 = pop_saveset(cnt_antRef_nerve2, 'filename', fname, 'filepath', save_path);
else
    fname = ['cnt_antRef_cleanfiltered_' cond_name '.set'];
    cnt_antRef = pop_saveset(cnt_antRef, 'filename', fname, 'filepath', save_path);
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
