% Author: Birgit Nierula
% nierula@cbs.mpg.de

function EEG = find_exactRpeaks(EEG, trigger_name, ecg_chanName, debug_mode)
% if data was down-sampled it is necessary to search for more exact R-peaks
% data needs to have an ECG channel!
% BN, 06,2020

idx_ecg = find(ismember({EEG.chanlocs.labels}, ecg_chanName));

% get current R-peak indexes
event_idx = find(ismember({EEG.event.type}, trigger_name));
peak_idx = round([EEG.event(event_idx).latency]);
range = round([-60 60] * (EEG.srate / 1000)); % in samples
r_peaks = peak_idx;

% find the r peak
for ii = 1:size(peak_idx, 2)
    bgn = peak_idx(ii) + range(1);
    enn = peak_idx(ii) + range(2);
    if enn <= size(EEG.data, 2) && bgn > 0
        temp = EEG.data(idx_ecg, bgn:enn);
        [~, ind] = max(temp);
        r_peaks(ii) =  bgn + ind -1;
    end
end

% correct R-peak indexes
for ii = 1:length(event_idx)
    [EEG.event(event_idx(ii)).latency] = r_peaks(ii); % replace new latencies in data structure
end

if debug_mode
    figure; hold on
    plot(EEG.times, EEG.data(idx_ecg, :))
    plot(EEG.times(peak_idx), EEG.data(idx_ecg, peak_idx), 'r*' )
    plot(EEG.times(r_peaks), EEG.data(idx_ecg, r_peaks), 'g*' )
    hold off
end