% Author: Birgit Nierula
% nierula@cbs.mpg.de

%% Removes stimulus artefact by interpolating from pre (in ms) to post (in ms)
% IN:
%   cnt: continuous signal in eeglab structure
%   eventType: name of event in trigger channel cnt.event.type
%   interpol_window_msec: [pre post] -stimulus interpolation time in milliseconds
%   channel_idx: index of channels to apply interpolation of stimulus artifact
%   check: if 1 prints figure of one trial
% OUT:
%   cnt1: updated cnt with interpolated stimulus artefacts


function cnt1 = prepro_removeStimArtefact(cnt, eventType, interpol_window_msec, channel_idx, debug_mode)

% create output structure
cnt1 = cnt;


% find locations
idx = ismember({cnt.event.type}, eventType);
trigger_pos = cell2mat({cnt.event(idx).latency});

% define interpolation window
fs = cnt.srate;
pre_window = round(interpol_window_msec(1) * fs / 1000); % in samples
post_window = round(interpol_window_msec(2) * fs / 1000); % in samples
intpol_window = ceil([pre_window post_window]); % interpolation window

% Piecewise Cubic Hermite Interpolating Polynomial (PCHIP) + replace EEG data
n_samples_fit = 5; %+1;  number of samples before and after cut used for interpolation fit

x_fit_raw = [intpol_window(1)-n_samples_fit : 1 : intpol_window(1), intpol_window(2) : 1 : intpol_window(2)+n_samples_fit];
x_interpol_raw = intpol_window(1) : 1 : intpol_window(2); % points to be interpolated; in pt

for ii = 1:length(trigger_pos) % loop through all stimulation events
    x_fit = round(trigger_pos(ii) + x_fit_raw); % fit point latencies for this event
    x_interpol = round(trigger_pos(ii) + x_interpol_raw); % latencies for to-be-interpolated data points
    
    for chan = channel_idx % loop through all channels
        y_fit = cnt.data(chan, x_fit); % y values to be fitted
        %y_interp = pchip(x_fit, y_fit, cnt.data(c, x_sr-x_sr_raw)); % calculate pchip, obtain values in t_cut interval
        y_interpol = pchip(x_fit, y_fit, x_interpol); % calculate pchip, obtain values in t_cut interval
        cnt1.data(chan, x_interpol) = y_interpol; % replace in EEG data
    end
    
    if mod(ii, 100) == 0 % talk to the operator every 100th trial
        fprintf('stimulation event %d \n', ii)
    end
end

if debug_mode
    figure; hold on;
    % plot signal with artifact
    plot_range = [-50 100];
    test_trial = 100;
    xx = (plot_range(1) : plot_range(2)) / cnt.srate * 1000;
    plot(xx, cnt.data(channel_idx(1), trigger_pos(test_trial) + plot_range(1) : trigger_pos(test_trial) + plot_range(2)));
    % plot signal with interpolated artifact
    plot(xx, cnt1.data(channel_idx(1), trigger_pos(test_trial) + plot_range(1) : trigger_pos(test_trial) + plot_range(2)),'r');
    xlabel('time [ms]')
    ylabel('amplitude [\muV]')
    title(['stimulus number ' num2str(test_trial)])
    legend({'raw' 'interpolated'})
end
