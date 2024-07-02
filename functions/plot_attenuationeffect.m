function plot_attenuationeffect(subjects, nerve)

%% set paths
savepath_ga = getenv('GADIR');


%% load data
load([savepath_ga 'data4stats.mat'], 'wide')

%% set variables
stimType = 1; % sensory nerve stimulation
if nerve == 1
    nerve_name = 'median';
    title_names = {'EEG' 'cervical CCA' 'upper arm'};
    target_chans = {'eeg_cca' 'esg_cca' 'Biceps'};
    negative_potential = [true true true];
elseif nerve == 2
    nerve_name = 'tibial';
    title_names = {'EEG' 'lumbar CCA' 'pop fossa'};
    target_chans = {'eeg_cca' 'esg_cca' 'Knee'};
    negative_potential = [false true true];
end

 
% select nerve and sensory stimulation
col_nerve = find(ismember(wide.columns, 'nerve'));
idx_nerve = find(wide.data(:, col_nerve) == nerve);
col_stimType = find(ismember(wide.columns, 'stimType'));
idx_stimType = find(wide.data(idx_nerve, col_stimType) == stimType);
idx_nerveStimType = idx_nerve(idx_stimType); clear idx_tmp   
dat_subset = wide.data(idx_nerveStimType, :);

% select stimulation location
col_stimLoc = find(ismember(wide.columns, 'stimLoc'));
idx1 = find(dat_subset(:, col_stimLoc) == 1); % digit1
idx2 = find(dat_subset(:, col_stimLoc) == 2); % digit2
idx3 = find(dat_subset(:, col_stimLoc) == 3); % digit1+2

col_data = find(ismember(wide.columns, {'eeg-cca' 'esg-cca' 'eng'})); % {'eeg-cca' 'brainstem' 'esg-cca' 'plexus-eng' 'eng'}
d1 = dat_subset(idx1, [1 col_data]);
d2 = dat_subset(idx2, [1 col_data]);
d1d2(:, 1) = d1(:, 1);
for ii = 2:size(title_names, 2)+1
    d1d2(:, ii) = d1(:, ii) + d2(:, ii); % sum: d1 + d2
end
d12 = dat_subset(idx3, [1 col_data]); % simultaneous stimulation d12



%% plots and statistics
for chan_idx = 1:numel(target_chans)%size(title_names, 2)+1% EEG = 2, ESG = 3, CCA = 4, BIP = 5, CCA_BIP = 6
    
    if ~strcmp(target_chans{chan_idx}, '')
        % column for this channel
        column_idx = chan_idx + 1;
        
        % figure settings
        if strcmp(target_chans{chan_idx}, 'eeg_cca')
            y_lim = [-3 0];
        elseif strcmp(target_chans{chan_idx}, 'esg_cca')
            y_lim = [-1 0];
        else
            y_lim = [-2 0];
        end
        if strcmp(target_chans{chan_idx}, 'eeg_cca') & nerve == 2
            is_reverse = false;
            y_lim = [0 3];
        else
            is_reverse = true;
        end
        
        title_str = title_names{chan_idx};
        if strcmp(target_chans{chan_idx}, 'eeg_cca') | strcmp(target_chans{chan_idx}, 'esg_cca')
            y_label = 'Amplitude [a.u.]';
        else
            y_label = ['Amplitude [' char(181) 'V]'];
        end

        % remove subjects with NaN in one of the three conditions
        logical_included = ones(1, length(subjects));
        idx1 = find(isnan(d1(:, column_idx)));
        idx2 = find(isnan(d2(:, column_idx)));
        idx12 = find(isnan(d12(:, column_idx)));
        idx = unique([idx1' idx2' idx12']);
        logical_included(idx) = 0;
        idx_included = find(logical_included);
        
        tmp_d1 = d1(idx_included, column_idx);
        tmp_d2 = d2(idx_included, column_idx);
        tmp_d1d2 = d1d2(idx_included, column_idx);
        tmp_d12 = d12(idx_included, column_idx);

        %% bar attenuation effect
        cfg.d1 = tmp_d1;
        cfg.d2 = tmp_d2;
        cfg.d1d2 = tmp_d1d2;
        cfg.d12 = tmp_d12;
        cfg.y_lim = y_lim;
        cfg.title_str = title_str;
        cfg.nerve = nerve;
        cfg.selected_conditions = 2;
        cfg.y_label = y_label;
        cfg.is_reverse = is_reverse;
        figures_interactionRatio(cfg)
        
        %% stats 
        disp(nerve_name)
        disp(title_names{chan_idx})        

        % Interaction ratio:
        data = [nanmean(tmp_d1d2, 1) nanmean(tmp_d12, 1) ]';
        ir = ((tmp_d1d2 - tmp_d12) ./ tmp_d1d2) * 100;
        mean_ir = mean(ir);
        str = {'Mean Interaction Ratio: ', [num2str(mean_ir) '%']};
        disp(str)        
        
        [H,P,CI,STATS] = ttest(ir, 0)
        STATS.H = H;
        STATS.P = P;
        STATS.CI = CI;
        STATS.r = sqrt(STATS.tstat^2 / (STATS.tstat^2 + STATS.df));
        STATS.cohend = (mean_ir - 0) / std(ir);
        disp('STATS = ')
        STATS
        all_stats.stats_ir{chan_idx} = STATS;
        all_stats.mean_ir(1, chan_idx) = mean_ir;
        all_stats.ir{chan_idx} = ir;

    end    
end
% save
file_name = [savepath_ga nerve_name '_stats_interactionRatio.mat'];
save(file_name, 'all_stats')
clear d*