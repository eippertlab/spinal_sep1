function [amp_bin, mats_concat] = ga_binned_correlation(subjects, conditions, srmr_nr)

% initialize output variables
amp_esg_bin_peri_m = []; amp_esg_bin_peri_d1 = []; amp_esg_bin_peri_d2 = []; amp_esg_bin_peri_d12 = [];
amp_esg_bin_eeg_m = []; amp_esg_bin_eeg_d1 = []; amp_esg_bin_eeg_d2 = []; amp_esg_bin_eeg_d12 = [];

%% set variables
savepath_ga = getenv('GADIR');

for condition = conditions
    % get condition info
    [cond_info] = get_conditionInfo(condition, srmr_nr);
    cond_name = cond_info.cond_name;
    nerve = cond_info.nerve;
    str_stimulation = cond_info.str_stimulation(2:end);
    if strcmp('digits', str_stimulation)
        str_stimulation = 'sensory';
    end
    
    has_allsubj = false;
    [amp, lat] = get_mergedData(condition, srmr_nr, subjects, has_allsubj);

    if strcmp('sensory', str_stimulation)
        stim_types = 3;
        extension_conds = {'d1' 'd2' 'd12'};
    else
        stim_types = 1;
        extension_conds = {'m'};
    end

    for istim = 1:stim_types
        eval(['amplitude_' extension_conds{istim} ' = amp.amplitude_' extension_conds{istim} ';'])
    end
end


%% correlation
if nerve == 1
    nerve_name = 'medianus';
    chan_names = {'Biceps' 'esg_cca' 'eeg_cca'};
elseif nerve == 2
    nerve_name = 'tibialis';
    chan_names = {'Knee' 'esg_cca' 'eeg_cca'};
end

mat_tmp_concat = []; cond_concat = []; ID_concat = []; % initialize variables containing concatenated data for R analyses
for isubject = 1:length(subjects)
    clear nan_idx
    for ichan = 1:size(chan_names, 2)
            corr_matrix_m(1:2000, ichan) = amplitude_m.(chan_names{ichan})(isubject,:)'; % trials x channels
            if srmr_nr == 2
                corr_matrix_d1(1:6000, ichan) = amplitude_d1.(chan_names{ichan})(isubject,:)'; % trials x channels

                corr_matrix_d2(1:6000, ichan) = amplitude_d2.(chan_names{ichan})(isubject,:)'; % trials x channels

                corr_matrix_d12(1:6000, ichan) = amplitude_d12.(chan_names{ichan})(isubject,:)'; % trials x channels
            end
    end
    % find trials with amplitude values over all three channels
    trial_idx_m = find(~isnan(sum(corr_matrix_m, 2)));
    trial_idx_d1 = find(~isnan(sum(corr_matrix_d1, 2)));
    trial_idx_d2 = find(~isnan(sum(corr_matrix_d2, 2)));
    trial_idx_d12 = find(~isnan(sum(corr_matrix_d12, 2)));
    
    mat_m = corr_matrix_m(trial_idx_m,:);
    mat_d1 = corr_matrix_d1(trial_idx_d1,:);
    mat_d2 = corr_matrix_d2(trial_idx_d2,:);
    mat_d12 = corr_matrix_d12(trial_idx_d12,:);


    % binning analyses (within participants)
    cond_list = {'m', 'd1', 'd2', 'd12'};
    
    for c = 1:length(cond_list)
        mat_tmp = eval(['mat_' cond_list{c}]); % select condition
    
        [~, sort_ix_peri] = sort(mat_tmp(:,1), 'ascend'); % sort peripheral amplitudes
        [~, sort_ix_eeg] = sort(mat_tmp(:,3), 'ascend'); % sort EEG amplitudes
        
        amp_esg_sort_peri = mat_tmp(sort_ix_peri,2); % ESG sorted by peripheral signal
        amp_esg_sort_eeg = mat_tmp(sort_ix_eeg,2); % ESG sorted by EEG signal
        
        nbins = 30; %10
        ntrials = size(mat_tmp,1);

        amp_esg_bin_peri_tmp = []; amp_esg_bin_eeg_tmp = []; % initialize variables
        for n = 1:nbins
            amp_esg_bin_peri_tmp(n) = mean(amp_esg_sort_peri( round(ntrials/nbins*(n-1))+1:round(ntrials/nbins*n) ));  
            amp_esg_bin_eeg_tmp(n) = mean(amp_esg_sort_eeg( round(ntrials/nbins*(n-1))+1:round(ntrials/nbins*n) ));      
        end

        % store binning results in group variables
        eval(['amp_esg_bin_peri_' cond_list{c} '(isubject,:) = amp_esg_bin_peri_tmp;'])
        eval(['amp_esg_bin_eeg_' cond_list{c} '(isubject,:) = amp_esg_bin_eeg_tmp;'])

        % prepare data in long format for analyses in R
        eval(['mat_tmp_concat = cat(1, mat_tmp_concat, mat_' cond_list{c} ');']); % concatenate rows (mix all conditions)
        cond_concat = [cond_concat, repmat(c,1,ntrials)];
        ID_concat = [ID_concat, repmat(isubject,1,ntrials)];

    end
end

%% create output structure
amp_bin = struct();
for c = 1:length(cond_list)
    eval(['amp_bin.amp_esg_bin_peri_' cond_list{c} ' = amp_esg_bin_peri_' cond_list{c} ';']);
    eval(['amp_bin.amp_esg_bin_eeg_' cond_list{c} ' = amp_esg_bin_eeg_' cond_list{c} ';']);
end

%% concatenated single-trial amplitudes
mats_concat = struct();
mats_concat.ID = ID_concat;
mats_concat.cond = cond_concat;
mats_concat.peri = mat_tmp_concat(:,1);
mats_concat.ESG = mat_tmp_concat(:,2);
mats_concat.EEG = mat_tmp_concat(:,3);





