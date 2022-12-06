function proc_createMixedLong(epo, fname, fpath, trigger_name, cond_name)

%% set max events
max_events = 2000; % mixed condition


% mixed
epo_long = get_getEpoStruct(epo, max_events, trigger_name{1});


%% save
d_idx = strfind(fname, cond_name);
ll = length(cond_name);

new_fname = [fname(1:d_idx+ll-1) '_long' fname(d_idx+ll:end)];
epo_long = pop_saveset(epo_long, 'filename', new_fname, 'filepath', fpath);


end



%% ==============================================
%% function: get long mixed structure
%% ==============================================
function epo_long = get_getEpoStruct(epo, max_events, trigger_name)

% get vars
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

%% check eventnumber exists
if ~isfield(epo.epoch, 'eventnumber')
    for ii = 1:length(epo.epoch)
        epo.epoch(ii).eventnumber = trial_idx(ii);
    end
end

%% create long data set with NaNs
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
        epo_long.epoch(ii) = epo.epoch(tmp_idx);
    else
        epo_long.epoch(ii) = tmp_epoch;
    end
end
epo_long.data = nan(nchans, ntime, ntrials);
epo_long.data(:, :, trial_number) = epo.data;
epo_long = eeg_checkset(epo_long);


end
