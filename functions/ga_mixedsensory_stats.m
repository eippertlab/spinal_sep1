function ga_mixedsensory_stats(subjects, nerve, has_allsubj)


%% set variables
srmr_nr = 2;
savepath_ga = getenv('GADIR');
if nerve == 1
    conditions = 2:3;
    % channels
    chan_names = {'Biceps' 'SC6' 'SC6_antRef' 'esg_cca' 'eeg_cca'};
    nerve_name = 'median';
elseif nerve == 2
    conditions = 4:5;
    % channels
    chan_names = {'Knee' 'L1' 'L1_antRef' 'esg_cca' 'eeg_cca'};
    nerve_name = 'tibial';
end


for icondition = 1:length(conditions)
    condition = conditions(icondition);
    % get condition info
    [cond_info] = get_conditionInfo(condition, srmr_nr);
    eval(['cond_name = cond_info.cond_name;'])
    
    str_stimulation = cond_info.str_stimulation(2:end);
    if strcmp('digits', str_stimulation)
        str_stimulation = 'sensory';
    end

    [amp, lat] = get_mergedData(condition, srmr_nr, subjects, has_allsubj);


    if strcmp('sensory', str_stimulation)
        stim_types = 1;
        extension_conds = {'d12'};
    else
        stim_types = 1;
        extension_conds = {'m'};
    end

    for istim = 1:stim_types
        eval(['amplitude_' extension_conds{istim} ' = amp.amplitude_' extension_conds{istim} ';'])
        eval(['latency_' extension_conds{istim} ' = lat.latency_' extension_conds{istim} ';'])
    end
end

for ichan = 1:size(chan_names,2)
    
    
    X = [amplitude_m.(chan_names{ichan})']; % trials x subjects
    Y= [amplitude_d12.(chan_names{ichan})']; % trials x subjects
    
    %% ttest group level
    avgX = nanmean(X, 1);
    avgY = nanmean(Y, 1);
    nan_idx = find(~isnan(avgX - avgY));
    [H,P,CI,STATS] = ttest(avgX(:, nan_idx), avgY(:, nan_idx));
    
    % effect_size
    tmp_r= sqrt(STATS.tstat^2 / (STATS.tstat^2 + STATS.df));
    tmp_gavg = nanmean(avgX-avgY); % mean difference over trials and subjects
    tmp_std = nanstd(avgX-avgY); % std over subjects (mean is over trials)
    tmp_cohend = (nanmean(avgX) - nanmean(avgY)) / tmp_std;
    

    avg_all_m = nanmean(nanmean(X(:, nan_idx)));
    n_all_m = length(find(~isnan(nanmean(X(:, nan_idx),1))));
    sem_all_m = nanstd(nanmean(X(:, nan_idx), 1)) / sqrt(n_all_m);
    avg_all_d12 = nanmean(nanmean(Y(:, nan_idx)));
    n_all_d12 = length(find(~isnan(nanmean(Y(:, nan_idx),1))));
    sem_all_d12 = nanstd(nanmean(Y(:, nan_idx), 1)) / sqrt(n_all_d12);
    
    % vars for table
    nd = 2; % number of digits to round
    chan_name{ichan,1} = chan_names(ichan);
    amplitude_m_stat{ichan,1} = [num2str(round(avg_all_m,nd)) ' ' char(177) ' ' num2str(round(sem_all_m,nd))];
    amplitude_d12_stat{ichan,1} = [num2str(round(avg_all_d12,nd)) ' ' char(177) ' ' num2str(round(sem_all_d12,nd))];
    tstat(ichan,1) = round(STATS.tstat,nd);
    df(ichan,1) = STATS.df;
    P(ichan,1) = P';
    CI_all{ichan,1} = [num2str(round(CI(1),nd)) ' ' char(8211) ' ' num2str(round(CI(2),nd))];
    cohend(ichan,1) = round(tmp_cohend,nd);
    n_m(ichan,1) = n_all_m;
    n_d12(ichan,1) = n_all_d12;
    
    clear X Y 
end
A_groupstats = table(chan_name, n_m, amplitude_m_stat, n_d12, amplitude_d12_stat, df, tstat, P, CI_all, cohend);


fname_group = [savepath_ga 'stats_group_mixedsensory_' nerve_name '.xlsx'];
writetable(A_groupstats, fname_group)

clear chan_name n_m amplitude_m_stat n_d12 amplitude_d12_stat df tstat P ...
    CI_all cohend

for ichan = 1:size(chan_names,2)
    
    
    X = [latency_m.(chan_names{ichan})]; % trials x subjects
    Y= [latency_d12.(chan_names{ichan})]; % trials x subjects
    
    %% ttest group level
    nan_idx = find(~isnan(X - Y));
    [H,P,CI,STATS] = ttest(X(nan_idx), Y(nan_idx));
    
    tmp_r= sqrt(STATS.tstat^2 / (STATS.tstat^2 + STATS.df));
    tmp_gavg = nanmean(X-Y); % mean difference over trials and subjects
    tmp_std = nanstd(X-Y); % std over subjects (mean is over trials)
    tmp_cohend = (nanmean(X) - nanmean(Y)) / tmp_std;
    

    avg_all_m = nanmean(X(nan_idx));
    n_all_m = length(find(~isnan(X(nan_idx))));
    sem_all_m = nanstd(X(nan_idx)) / sqrt(n_all_m);
    avg_all_d12 = nanmean(Y(nan_idx));
    n_all_d12 = length(find(~isnan(Y(nan_idx))));
    sem_all_d12 = nanstd(Y(nan_idx), 1) / sqrt(n_all_d12);
    
    % vars for table
    nd = 2; % number of digits to round
    chan_name{ichan,1} = chan_names(ichan);
    latency_m_stat{ichan,1} = [num2str(round(avg_all_m,nd)) ' ' char(177) ' ' num2str(round(sem_all_m,nd))];
    latency_d12_stat{ichan,1} = [num2str(round(avg_all_d12,nd)) ' ' char(177) ' ' num2str(round(sem_all_d12,nd))];
    tstat(ichan,1) = round(STATS.tstat,nd);
    df(ichan,1) = STATS.df;
    P(ichan,1) = P';
    CI_all{ichan,1} = [num2str(round(CI(1),nd)) ' ' char(8211) ' ' num2str(round(CI(2),nd))];
    cohend(ichan,1) = round(tmp_cohend,nd);
    n_m(ichan,1) = n_all_m;
    n_d12(ichan,1) = n_all_d12;
    
    clear X Y
end
L_groupstats = table(chan_name, n_m, latency_m_stat, n_d12, latency_d12_stat, df, tstat, P, CI_all, cohend);
fname_group = [savepath_ga 'stats_group_mixedsensory_' nerve_name '_latency.xlsx'];
writetable(L_groupstats, fname_group)