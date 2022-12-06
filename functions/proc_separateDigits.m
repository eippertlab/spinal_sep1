function proc_separateDigits(epo, fname, fpath, trigger_name)

%% set max events
max_events = 6000; % all 3 conditions


%% select trials and reset signal to baseline
% D1
[epo1_short, epo1_long] = get_separatedEpoStruct(epo, max_events, trigger_name{1});
% D2
[epo2_short, epo2_long] = get_separatedEpoStruct(epo, max_events, trigger_name{2});
% D12
[epo12_short, epo12_long] = get_separatedEpoStruct(epo, max_events, trigger_name{3});


%% save
d_idx = strfind(fname,'digits');
% D1
new_fname = [fname(1:d_idx-1) 'd1' fname(d_idx+6:end)];
epo1_short = pop_saveset(epo1_short, 'filename', new_fname, 'filepath', fpath);
new_fname = [fname(1:d_idx-1) 'd1_long' fname(d_idx+6:end)];
epo1_long = pop_saveset(epo1_long, 'filename', new_fname, 'filepath', fpath);
% D2
new_fname = [fname(1:d_idx-1) 'd2' fname(d_idx+6:end)];
epo2_short = pop_saveset(epo2_short, 'filename', new_fname, 'filepath', fpath);
new_fname = [fname(1:d_idx-1) 'd2_long' fname(d_idx+6:end)];
epo2_long = pop_saveset(epo2_long, 'filename', new_fname, 'filepath', fpath);
% D12
new_fname = [fname(1:d_idx-1) 'd12' fname(d_idx+6:end)];
epo12_short = pop_saveset(epo12_short, 'filename', new_fname, 'filepath', fpath);
new_fname = [fname(1:d_idx-1) 'd12_long' fname(d_idx+6:end)];
epo12_long = pop_saveset(epo12_long, 'filename', new_fname, 'filepath', fpath);


end



%% ==============================================
%% function: separate digit conditions
%% ==============================================
function [epo_short, epo_long] = get_separatedEpoStruct(epo, max_events, trigger_name)

%% get vars
load([getenv('CFGDIR') 'cfg.mat'], 'iv_baseline')
if isfield(epo.epoch, 'eventnumber')
    has_eventnumber = true;
else
    has_eventnumber = false;
end


%% find condition indexes
% find correct trigger postition
counter = 0;
for itrial = 1:epo.trials
    % select trigger position
    stim_idx = find([epo.epoch(itrial).eventlatency{:}] == 0);
    if length(stim_idx) > 1
        tmp_idx = find(ismember({ epo.epoch(itrial).eventtype{stim_idx} }, trigger_name));
        stim_idx = stim_idx(tmp_idx);
    end
    if ~isempty(stim_idx)
        if strcmp(epo.epoch(itrial).eventtype{stim_idx}, trigger_name)
            counter = counter + 1;
            trial_idx(counter) = itrial;
            if has_eventnumber
                try
                    trial_number(counter) = [epo.epoch(itrial).eventnumber];
                catch
                    trial_number(counter) = [epo.epoch(itrial).eventnumber{stim_idx}];
                end
            else
                trial_number(counter) = itrial;
            end
        end
    end
end

%% short data set
% create short data set base on indexes
epo_short = pop_select(epo, 'trial', trial_idx);
% set to baseline
epo_short = pop_rmbase(epo_short, iv_baseline);
if ~isfield(epo_short.epoch, 'eventnumber')
    if isfield(epo.epoch, 'eventnumber')
        for ii = 1:length(epo_short.epoch)
            epo_short.epoch(ii).eventnumber = epo.epoch(trial_idx(ii)).eventnumber;
        end
    else
        for ii = 1:length(epo_short.epoch)
            epo_short.epoch(ii).eventnumber = trial_idx(ii);
        end
        for ii = 1:length(epo.epoch)
            epo.epoch(ii).eventnumber = NaN;
        end
    end
end

%% long data set with NaNs
% select trials and replace rest with NaN
epo_long = epo;
nchans = size(epo.data,1);
ntime = size(epo.data,2);
ntrials = max_events;
epo_long.trials = ntrials;

% nan template
tmp_epoch.event = NaN;
tmp_epoch.eventlatency = NaN;
tmp_epoch.eventtype = NaN;
tmp_epoch.eventurevent = NaN;
tmp_epoch.eventtrial_type = NaN;
tmp_epoch.eventduration = NaN;
tmp_epoch.eventnumber = NaN;

% replace
for ii = 1:ntrials
    tmp_idx = find(ii == trial_number);
    if ~isempty(tmp_idx)
        epo_long.epoch(ii) = epo_short.epoch(tmp_idx);
    else
        epo_long.epoch(ii) = tmp_epoch;
    end
end
epo_long.data = nan(nchans, ntime, ntrials);
epo_long.data(:, :, trial_number) = epo_short.data;
epo_long = eeg_checkset(epo_long);


end
