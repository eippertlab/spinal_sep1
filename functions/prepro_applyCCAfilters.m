% Author: Birgit Nierula
% nierula@cbs.mpg.de

function prepro_applyCCAfilters(subject, nerve, srmr_nr, is_eeg)


%% set variables
subject_id = sprintf('sub-%03i', subject);
if is_eeg
    save_path = [getenv('EEGDIR') subject_id '/'];
else
    save_path = [getenv('ESGDIR') subject_id '/'];
end
cfg_path = getenv('CFGDIR');

% get condition info
if nerve == 1
    nerve_name = 'medianus';
elseif nerve == 2
    nerve_name = 'tibialis';
end

% ref name
if is_eeg
    ref_name = 'avgRef_';
else  
    ref_name = 'antRef_'; % anterior cervical or lumbar channel    
end


% load data
if srmr_nr == 1
    fname = ['epo_' ref_name 'cleanclean_' nerve_name(1:end-2) '.set'];
    epo = pop_loadset('filename', fname, 'filepath', save_path);
elseif srmr_nr == 2
    fname = ['epo_' ref_name 'cleanclean_' nerve_name(1:3) '_mixed.set'];
    epo = pop_loadset('filename', fname, 'filepath', save_path);
    fname = ['epo_' ref_name 'cleanclean_' nerve_name(1:3) '_digits.set'];
    epo_d = pop_loadset('filename', fname, 'filepath', save_path);
end


%% prepare for CCA weights
if is_eeg
    % selected Channels
    [eeg_chans, ~, ~] = get_channels(subject, false, false, srmr_nr);
    chan_names = [eeg_chans {'RM'}]; clear eeg_chans
    chan_idx = find(ismember({epo.chanlocs.labels}, chan_names));
    epo = pop_select(epo, 'channel', chan_idx);
    if srmr_nr == 2
        chan_idx = find(ismember({epo_d.chanlocs.labels}, chan_names));
        epo_d = pop_select(epo_d, 'channel', chan_idx);
    end
else
    % selected Channels
    [~, cervical_chans, lumbar_chans, ~] = get_esg_channels();
    if nerve == 1
        all_chans = cervical_chans;
    elseif nerve == 2
        all_chans = lumbar_chans;
    end
    log_idx = ismember(all_chans, {'Fz-TH6' 'AC' 'AL' 'L4'});
    idx = find(~log_idx);
    esg_chans = all_chans(idx);
    chan_idx = find(ismember({epo.chanlocs.labels}, esg_chans));
    epo = pop_select(epo, 'channel', chan_idx);
    if srmr_nr == 2
        chan_idx = find(ismember({epo_d.chanlocs.labels}, esg_chans));
        epo_d = pop_select(epo_d, 'channel', chan_idx);
    end
end


%% load CCA info: 
file_name = [save_path 'cca_info_' nerve_name(1:3) 'mixed.mat'];
load(file_name, 'W_st', 'is_inverted')

% single trial matrix
st_matrix_mixed = reshape(epo.data, epo.nbchan, epo.pnts * epo.trials)'; % observations x channels
if srmr_nr == 2
    st_matrix_digits = reshape(epo_d.data, epo_d.nbchan, epo_d.pnts * epo_d.trials)'; % observations x channels
end


%% select component
if is_eeg
    load([getenv('CFGDIR') 'eeg_cca_components.mat'], 'selected_components')
else
    load([getenv('CFGDIR') 'cca_components.mat'], 'selected_components')
end
eval(['selected_comps = selected_components.' nerve_name '{subject};'])


%% Apply selected weights to dataset 
CCA_concat_m = mean(st_matrix_mixed * W_st(:, selected_comps), 2)';
if srmr_nr == 2
    % apply weights to digits
    CCA_concat_d = mean(st_matrix_digits * W_st(:, selected_comps), 2)';
end


%% Re-reshape
CCA_comps_m = reshape(CCA_concat_m, 1, epo.pnts, epo.trials);
if srmr_nr == 2
    CCA_comps_d = reshape(CCA_concat_d, 1, epo_d.pnts, epo_d.trials);
end


% create data structure
epo_cca = epo; epo_cca.data = [];
epo_cca.data = CCA_comps_m;
epo_cca.nbchan = 1;
epo_cca.chanlocs = [];
epo_cca.chanlocs(1).labels = [];
epo_cca = eeg_checkset(epo_cca);


% set to baseline
load([cfg_path 'cfg.mat'], 'iv_baseline')
epo_cca = pop_rmbase(epo_cca, iv_baseline);
    
if srmr_nr == 2
    epod_cca = epo_d; epod_cca.data = [];
    epod_cca.data = CCA_comps_d;
    epod_cca.nbchan = 1;
    epod_cca.chanlocs = [];
    epod_cca.chanlocs(1).labels = [];
    epod_cca = eeg_checkset(epod_cca);
    % set to baseline
    epod_cca = pop_rmbase(epod_cca, iv_baseline);
end


%% check if it needs to be inverted
if is_inverted
    epo_cca.data = epo_cca.data * (-1);
    if srmr_nr == 2
        epod_cca.data = epod_cca.data * (-1);
    end
end
  

%% save
if srmr_nr == 1
    fname = ['epo_ccacleanclean_' nerve_name(1:end-2) '.set'];
    pop_saveset(epo_cca, 'filename', fname, 'filepath', save_path);
elseif srmr_nr == 2
    fname = ['epo_ccacleanclean_' nerve_name(1:3) '_mixed.set'];
    pop_saveset(epo_cca, 'filename', fname, 'filepath', save_path);
    fname = ['epo_ccacleanclean_' nerve_name(1:3) '_digits.set'];
    pop_saveset(epod_cca, 'filename', fname, 'filepath', save_path);
end