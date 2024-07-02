% Author: Birgit Nierula
% nierula@cbs.mpg.de

function pot_latency = esg_prepro_loop7_potentialLatency(subject, nerve, srmr_nr)


%% set variables
subject_id = sprintf('sub-%03i', subject);
analysis_path = [getenv('ANADIR') subject_id '/esg/prepro/'];
save_path = [getenv('ESGDIR') subject_id '/'];
cfg_path = getenv('CFGDIR');

% get condition info
if nerve == 1
    nerve_name = 'medianus';
elseif nerve == 2
    nerve_name = 'tibialis';
end


% load data
if srmr_nr == 1
    fname = ['epo_cleanclean_' nerve_name(1:end-2) '.set'];
    epo = pop_loadset('filename', fname, 'filepath', analysis_path);
elseif srmr_nr == 2
    files = dir([analysis_path 'epo_' ref_name 'cleanclean_' nerve_name(1:3) '_mixed.set']);
    epo = pop_loadset('filename', files(1).name, 'filepath', analysis_path);
end

% figure
figure;
tmp_idx = find(ismember({epo.chanlocs.labels}, target_chan));
plot(epo.times, mean(epo.data(tmp_idx, :, :), 3))
xlim([-30 40])
title(epo.chanlocs(tmp_idx).labels)
xlabel('[ms]')
ylabel(['[' char(181) 'V]'])

% enter latency of potential
tmp = input('Enter the latency of the potential in averaged signal in ms:   ');
idx = find(epo.times >= tmp);

idxs = idx(1)-3 : idx(1)+3;
tmp_pk = findpeaks(epo.times(idxs));
pot_latency = epo.times(idxs(tmp_pk));

plot(pot_latency, mean(epo.data(tmp_idx, idxs(tmp_pk), :), 3), 'r*')

save_dat = input('if the point is at the right latency press enter, else enter 0  :');

if isempty(save_dat)
    eval([nerve_name(1:3) '_potlatency = pot_latency;'])
    fpath = [save_path 'potential_latency.mat'];
    if exist(fpath, 'file')
        save(fpath, [nerve_name(1:3) '_potlatency'], '-append')
    else
        save(fpath, [nerve_name(1:3) '_potlatency'])
    end
end

