% Author: Birgit Nierula
% nierula@cbs.mpg.de

function [cnt, QRSevents, fwts, ecg_idx] = prepro_prepare4ecgCleaning(cnt_qrs, esg_chans)
  
% esg_chans have to include ECG channel!

%% select only ESG channels and ECG channel
[~, idx] = ismember({cnt_qrs.chanlocs.labels}, esg_chans);
channels = find(idx);
cnt = pop_select(cnt_qrs, 'channel', channels); clear idx channels

%% get number of ECG channel
[~, idx] = ismember({cnt.chanlocs.labels}, 'ECG');
ecg_idx = find(idx);


%% get latencies of qrs events
QRSevents = [];
for aEvent = 1:length(cnt.event)
    if strcmp(cnt.event(aEvent).type, 'qrs')
        QRSevents(end + 1) = round(cnt.event(aEvent).latency);
    end
end

%% make filter (outside of fmrib to make algorithm faster)
fs = cnt.srate;
a = [0 0 1 1];
f = [0 0.4/(fs/2) 0.9/(fs/2) 1]; % 0.9 Hz highpass filter
% f = [0 0.4/(fs/2) 0.5/(fs/2) 1]; % 0.5 Hz highpass filter
ord = round(3*fs/0.5);
fwts = firls(ord, f, a);
    
end