% Author: Birgit Nierula
% nierula@cbs.mpg.de

function other_prepro_findpeak(subject, condition, srmr_nr)

%% finds CNAP/SNAP peaks

%% set variables
subject_id = sprintf('sub-%03i', subject);
analysis_path = [getenv('OTHERDIR') subject_id '/other/prepro/']; 
if ~exist(analysis_path,'dir'); mkdir(analysis_path); end
raw_path = [getenv('RAWDIR') subject_id '/eeg/'];
cfg_path = getenv('CFGDIR');

% get condition info
[cond_info] = get_conditionInfo(condition, srmr_nr);
cond_name = cond_info.cond_name;
trigger_name = cond_info.trigger_name;
stimulation = cond_info.stimulation;
cond_name2 = cond_info.cond_name2;
nerve = cond_info.nerve;

% define target channels
if nerve == 1
    target_chan = {'EP' 'Biceps'};
    is_min = true;
elseif nerve == 2
    target_chan = {'KneeM' 'Knee1' 'Knee2' 'Knee3' 'Knee4'};
    is_min = true;    
end
x_lim = [-30 40];


%% load data
fname = ['eng_filt_' cond_name '.set'];
epo = pop_loadset('filename', fname, 'filepath', analysis_path);
fpath = [analysis_path 'other_potential_latency.mat'];
if exist(fpath, 'file')
    load(fpath, [cond_name '_potlatency'])
end

%% figure
f1 = figure('units','normalized','outerposition',[0 0 1 1]); hold on
for ichan = 1:length(target_chan)
    tmp_idx = find(ismember({epo.chanlocs.labels}, target_chan(ichan)));
    plot(epo.times, mean(epo.data(tmp_idx, :, :), 3))
    targetchan_idx(ichan) = tmp_idx;
end
xlim(x_lim)
legend(epo.chanlocs(targetchan_idx).labels)
xlabel('[ms]')
ylabel(['[' char(181) 'V]'])
title([subject_id '-' cond_name])

for ichan = 1:length(target_chan)
    save_dat = 0;
    while save_dat == 0
        % enter latency of potential
        tmp = input([target_chan{ichan} ': Enter the latency of the potential in ms:   ']);
        if ~isnan(tmp)
            idx = find(epo.times >= tmp);

            idxs = idx(1)-2 : idx(1)+2;
            if is_min
                [~, idx_pk] = min(mean(epo.data(targetchan_idx(ichan), idxs, :), 3),[], 2);
            else
                [~, idx_pk] = max(mean(epo.data(targetchan_idx(ichan), idxs, :), 3),[], 2);
            end
            tmp_latency = epo.times(idxs(idx_pk));

            plot(tmp_latency, mean(epo.data(targetchan_idx(ichan), idxs(idx_pk), :), 3), 'r*')
            figure(f1)
        else
            tmp_latency = NaN;
        end

        save_dat = input('if the point is at the right latency press enter, else enter 0  :');
    end
    eval([cond_name '_potlatency.' target_chan{ichan} ' = tmp_latency;']); clear tmp_latency
end

if exist(fpath, 'file')
    save(fpath, [cond_name '_potlatency'], '-append')
else
    save(fpath, [cond_name '_potlatency'])
end

close