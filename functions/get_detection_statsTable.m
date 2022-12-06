% Author: Birgit Nierula
% nierula@cbs.mpg.de

function get_detection_statsTable(conditions, srmr_nr)


for icondition = conditions
    %% set variables
    savepath_ga = getenv('GADIR');
    
    % get condition info
    [cond_info] = get_conditionInfo(icondition, srmr_nr);
    cond_name = cond_info.cond_name;
    nerve = cond_info.nerve;
    str_stimulation = cond_info.str_stimulation(2:end);
    if strcmp('digits', str_stimulation)
        str_stimulation = 'sensory';
    end
    
    if strcmp('sensory', str_stimulation)
        extension_conds = {'d1' 'd2' 'd12' };
    else
        extension_conds = {'m'};
    end
    stim_types = length(extension_conds);

    if srmr_nr == 1
        if nerve == 1
            chan_names = {'Biceps' 'EP' 'SC6' 'SC6_antRef' 'esg_cca' 'SC1' 'eeg_cca'};
        elseif nerve == 2
            chan_names = {'Knee' 'L1' 'L1_antRef' 'esg_cca' 'S3' 'eeg_cca'};
        end
    elseif srmr_nr == 2
        if nerve == 1
            chan_names = {'Biceps' 'SC6' 'SC6_antRef' 'esg_cca' 'eeg_cca'};
        elseif nerve == 2
            chan_names = {'Knee' 'L1' 'L1_antRef' 'esg_cca' 'eeg_cca'};
        end
    end
    for istim = 1:stim_types
        % info order: chan_name n_withPotential latency_mean latency_sd
        % amplitude_mean amplitude_sd tstat df P CI_lower CI_upper d
        % load amplitude stats
        % T_groupstats = table(chan_all, n_all, avg_all, sem_all, tstat_all, df_all, p_all, ci_all, r_all, d_all, h_all);
        if strcmp('mixed', str_stimulation)
            fname_group = [savepath_ga 'stats_group_detectability_' cond_name '.xlsx'];
        else
            fname_group = [savepath_ga 'stats_group_detectability_' cond_name '_' extension_conds{istim} '.xlsx'];
        end
        T_groupstats = readtable(fname_group);
        for ichan = 1:length(chan_names)
            % load latency mean and sem
            if strcmp('mixed', str_stimulation)
                fname_group = [savepath_ga 'stats_group_latency_' cond_name '_' chan_names{ichan} '.mat'];
            else
                fname_group = [savepath_ga 'stats_group_latency_' cond_name '_' extension_conds{istim} '_' chan_names{ichan} '.mat'];
            end
            load(fname_group, 'latency')
            
            % enter in table (for publication) (order: chan_name n_withPotential latency_mean latency_sd
            % amplitude_mean amplitude_sd tstat df P CI_lower CI_upper d)
            nd = 2; % number of digits to round
            chan_idx = find(ismember(T_groupstats.chan_all, chan_names{ichan}));
            chan_name{ichan,1} = chan_names{ichan};
            n_withPotential(ichan,1) = NaN;
            latency_stat{ichan,1} = [num2str(round(latency.mean,nd)) ' ' char(177) ' ' num2str(round(latency.sem,nd))];
            amplitude_stat{ichan,1} = [num2str(round(T_groupstats.avg_all(chan_idx),nd)) ' ' char(177) ' ' num2str(round(T_groupstats.sem_all(chan_idx),nd))];
            snr_stat{ichan,1} = [num2str(round(T_groupstats.snr_avg(chan_idx),nd)) ' ' char(177) ' ' num2str(round(T_groupstats.snr_sem(chan_idx),nd))];
            tstat(ichan,1) = round(T_groupstats.tstat_all(chan_idx),nd);
            df(ichan,1) = T_groupstats.df_all(chan_idx);
            P(ichan,1) = T_groupstats.p_all(chan_idx);
            CI{ichan,1} = [num2str(round(T_groupstats.ci_all_1(chan_idx),nd)) ' ' char(8211) ' ' num2str(round(T_groupstats.ci_all_2(chan_idx),nd))];
            cohend(ichan,1) = round(T_groupstats.d_all(chan_idx),nd);
        end
        T_stats = table(chan_name, n_withPotential, latency_stat, amplitude_stat, snr_stat, tstat, P, CI, cohend);
        tname = [savepath_ga 'statsTable_' cond_name '_' extension_conds{istim} '.xlsx'];
        writetable(T_stats, tname)
        clear T_stats chan_idx chan_name n_withPotential latency_stat amplitude_stat tstat df P CI* cohend snr_stat
    end
end