% Author: Birgit Nierula
% nierula@cbs.mpg.de

function pot_latency = bs_prepro_loop2(isubject, icondition, srmr_nr, is_min)

%% get potential latency

%% set variables
subject_id = sprintf('sub-%03i', isubject);
analysis_path = [getenv('ANADIR') subject_id '/bs/prepro/'];
save_path = [getenv('BSDIR') subject_id '/'];
load_eegpath = [getenv('EEGDIR') subject_id '/'];
load_esgpath = [getenv('ESGDIR') subject_id '/'];
if ~exist(save_path,'dir'); mkdir(save_path); end

% get condition info
cond_info = get_conditionInfo(icondition, srmr_nr);
cond_name = cond_info.cond_name;
nerve = cond_info.nerve;


% get condition info
target_chan3 = 'Iz';
if nerve == 1
    target_chan1 = 'SC1';
    target_chan2 = 'S3';
    target_chan4 = 'SC6';
    target_eeg = 'CP4';
    target_esg = 'SC6';
    x_lim = [-30 40];
    is_min = true;
elseif nerve == 2
    target_chan1 = 'S3';
    target_chan2 = 'SC1';
    target_chan4 = 'SC6';
    target_eeg = 'Cz';
    target_esg = 'L1';
    x_lim = [-30 60];
    is_min = true;
end


%% load
fname = ['epo_bs_cleanclean_' cond_name '.set'];
if exist([analysis_path fname], 'file')
    epo = pop_loadset('filename', fname, 'filepath', analysis_path);
    fname = ['epo_avgRef_cleanclean_' cond_name '.set'];
    epo_eeg = pop_loadset('filename', fname, 'filepath', load_eegpath);
    fname = ['epo_cleanclean_' cond_name '.set'];
    epo_esg = pop_loadset('filename', fname, 'filepath', load_esgpath);


    %% figure
    f1 = figure('units','normalized','outerposition',[0 0 1 1]); hold on
    tmp_idx1 = find(ismember({epo.chanlocs.labels}, target_chan1));
    tmp_idx2 = find(ismember({epo.chanlocs.labels}, target_chan2));
    tmp_idx3 = find(ismember({epo.chanlocs.labels}, target_chan3));
    tmp_idx4 = find(ismember({epo.chanlocs.labels}, target_chan4));
    tmp_eeg = find(ismember({epo_eeg.chanlocs.labels}, target_eeg));
    tmp_esg = find(ismember({epo_esg.chanlocs.labels}, target_esg));
    plot(epo_esg.times, mean(epo_esg.data(tmp_esg, :, :), 3),'k--')
    plot(epo_eeg.times, mean(epo_eeg.data(tmp_eeg, :, :), 3),'b--')
    plot(epo.times, mean(epo.data(tmp_idx4, :, :), 3))
    plot(epo.times, mean(epo.data(tmp_idx3, :, :), 3))
    plot(epo.times, mean(epo.data(tmp_idx2, :, :), 3))
    plot(epo.times, mean(epo.data(tmp_idx1, :, :), 3))
    xlim(x_lim)
    legend([{epo_esg.chanlocs(tmp_esg).labels} {epo_eeg.chanlocs(tmp_eeg).labels} {epo.chanlocs([tmp_idx4 tmp_idx3 tmp_idx2 tmp_idx1]).labels}])
    xlabel('[ms]')
    ylabel(['[' char(181) 'V]'])
    title([subject_id cond_name])

    save_dat = 0;

    while save_dat == 0
        % enter latency of potential
        tmp = input('Enter the latency of the potential in averaged signal in ms:   ');
        if ~isnan(tmp)
            idx = find(epo.times >= tmp);

            idxs = idx(1)-2 : idx(1)+2;
            if is_min
                [~, idx_pk] = min(mean(epo.data(tmp_idx1, idxs, :), 3),[], 2);
            else
                [~, idx_pk] = max(mean(epo.data(tmp_idx1, idxs, :), 3),[], 2);
            end
            pot_latency = epo.times(idxs(idx_pk));

            plot(pot_latency, mean(epo.data(tmp_idx1, idxs(idx_pk), :), 3), 'r*')
            figure(f1)
        else
            pot_latency = NaN;
        end

        save_dat = input('if the point is at the right latency press enter, else enter 0  :');
    end

    eval([cond_name(1:3) '_potlatency = pot_latency;'])
    fpath = [save_path 'potential_latency.mat'];
    if exist(fpath, 'file')
        save(fpath, [cond_name(1:3) '_potlatency'], '-append')
    else
        save(fpath, [cond_name(1:3) '_potlatency'])
    end

    close
else
    pot_latency = NaN;
end