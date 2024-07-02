% Author: Birgit Nierula
% nierula@cbs.mpg.de

function stats_late_seps(epo_esg, epo_control, condition, srmr_nr)
%% stats late SEPs
addpath('/data/pt_02296/toolboxes/fieldtrip-20200331');

% paths
cfg_path = getenv('CFGDIR');
ga_path = getenv('GADIR');

% condition info
cond_info = get_conditionInfo(condition, srmr_nr);
cond_name = cond_info.cond_name;
nerve = cond_info.nerve;
if nerve == 1
    chan_names = {'SC6'};
elseif nerve == 2
    chan_names = {'L1'};
end

% change to fieldtrip format
% prepare for fieldtrip
subj_number = numel(epo_esg); %total subject number
grand_trials = cell(subj_number, 2); 
epoch_number = NaN(subj_number, 2);
load([cfg_path 'cfg.mat'], 'iv_baseline')
cfg2 = []; 
cfg2.baseline = iv_baseline/1000; 


for isubject = 1:subj_number 
    % get data
    n_trials = min([epo_esg{isubject}.trials epo_control{isubject}.trials]);
    if epo_esg{isubject}.trials > n_trials
        epo_esg{isubject} = pop_select(epo_esg{isubject}, 'trial', 1:n_trials);
    elseif epo_control{isubject}.trials > n_trials
        epo_control{isubject} = pop_select(epo_control{isubject}, 'trial', 1:n_trials);
    end
    esg_stim = epo_esg{isubject};
    esg_cntrl = epo_control{isubject};
    
    % select channels from target patch
    [~, cervical_chans, lumbar_chans,~] = get_esg_channels();
    if nerve == 1
        tmp_idx = find(~ismember(cervical_chans, {'AC' 'AL' 'L4'}));
        cervical_patch = cervical_chans(tmp_idx);
        chan_idx1 = find(ismember({esg_stim.chanlocs.labels}, cervical_patch));
        chan_idx2 = find(ismember({esg_cntrl.chanlocs.labels}, cervical_patch));
    elseif nerve == 2
        tmp_idx = find(~ismember(lumbar_chans, {'AC' 'AL' 'L4'}));
        lumbar_patch = lumbar_chans(tmp_idx);
        chan_idx1 = find(ismember({esg_stim.chanlocs.labels}, lumbar_patch));
        chan_idx2 = find(ismember({esg_cntrl.chanlocs.labels}, lumbar_patch));
    end
         
    for icond = 1:2
        if icond == 1
            esg_dat = pop_select(esg_stim, 'channel', chan_idx1);
        else
            esg_dat = pop_select(esg_cntrl, 'channel', chan_idx2);
        end
        data = eeglab2fieldtrip(esg_dat, 'timelockanalysis', 'timeloc');
        data.dimord = 'chan_time';
        data = ft_timelockbaseline(cfg2, data); % baseline correction
        data.fsample = esg_dat.srate;
        n_epos = size(esg_dat.data, 3);
        grand_trials{isubject, icond} = data;
        epoch_number(isubject, icond) = n_epos;  
        clear esg_dat data n_epos 
    end
end

   
sigSTIM = grand_trials(:,1)';
sigCNTRL = grand_trials(:,2)';   

%load layout and neighbours created with ESG data
load([cfg_path 'layout_cervicalPatch.mat'])
cfg = [];
if nerve == 2
    % change to lumbar channels
    new_names = {'' '' 'S20' 'S23' 'L1' 'S31' 'S35' '' 'S22' 'S26' 'S30' 'S34' 'S24' 'S28' 'S32' 'S36' '' '' '' ''};
    for ii = [3:7 9:16]
        layout_esg.label{ii} = new_names{ii};
    end
end
cfg.layout = layout_esg;
cfg.channel     = {'all',  '-Iz', '-SC1', '-ECG', '-AC', '-S4', '-S8', '-S12', '-S16'}; % exclude channels
layout = ft_prepare_layout(cfg);
ft_layoutplot(cfg)

cfg.method      = 'triangulation';
cfg.feedback    = 'yes'; % don't show a neighbour plot
neighbours = ft_prepare_neighbours(cfg, sigSTIM{1,1}); % define neighbouring channels


cfg = [];
cfg.channel = {neighbours.label};
cfg.latency = [0 0.6];
cfg.method = 'montecarlo';
cfg.statistic = 'depsamplesT'; % within subnum design
cfg.correctm = 'cluster';
cfg.clusteralpha = 0.05;
cfg.clusterstatistic ='maxsum';
cfg.clusterthreshold = 'parametric';
cfg.neighbours = neighbours; % as defined above
cfg.tail = 0; % two-tailed test
cfg.clustertail = 0;
cfg.numrandomization = 1000;
% prepare design matrix for comparison of two conditions

design = zeros(2,2*subj_number);
for i = 1:subj_number
    design(1,i) = i;
end
for i = 1:subj_number
    design(1,subj_number+i) = i;
end
design(2,1:subj_number)        = 1;
design(2,subj_number+1:2*subj_number) = 2;

cfg.design = design;
cfg.uvar  = 1;
cfg.ivar  = 2;

% Run statistics
stat= ft_timelockstatistics(cfg, sigSTIM{:}, sigCNTRL{:});

% save 
fname = ['stats_ga_latepotentials_' cond_name];
save([ga_path fname], 'stat')

% grand avg
cfg = [];
cfg.channel   = {neighbours.label};
cfg.latency   = 'all';
cfg.parameter = 'avg';  %cfg.keepindividual='yes';
gaSTIM        = ft_timelockgrandaverage(cfg, sigSTIM{:}); % grand average for systole
gaCNTRL        = ft_timelockgrandaverage(cfg, sigCNTRL{:}); % grand average for diastole

% take the difference of the averages using ft_math
cfg           = [];
cfg.operation = 'subtract';
cfg.parameter = 'avg';
raweffectSTIMvsCNTRL = ft_math(cfg, gaSTIM, gaCNTRL);

% Make a vector of all p-values associated with the clusters from ft_timelockstatistics.
pos_cluster_pvals = [stat.posclusters(:).prob];

% Then, find which clusters are deemed interesting to visualize, here we use a cutoff criterion based on the
% cluster-associated p-value, and take a 5% two-sided cutoff (i.e. 0.025 for the positive and negative clusters,
% respectively
pos_clust = find(pos_cluster_pvals < 0.025);
pos       = ismember(stat.posclusterslabelmat, pos_clust);

% and now for the negative clusters...
neg_cluster_pvals = [stat.negclusters(:).prob];
neg_clust         = find(neg_cluster_pvals < 0.025);
neg               = ismember(stat.negclusterslabelmat, neg_clust);

if nerve == 1
    % two positive and one negative cluster
    pos1 = stat.posclusterslabelmat == 1; % or == 2, or 3, etc.
    pos2 = stat.posclusterslabelmat == 2;
    neg1 = stat.negclusterslabelmat == 1;
    neg2 = [];
elseif nerve == 2
    % two positive and two negative clusters
    pos1 = stat.posclusterslabelmat == 1; % or == 2, or 3, etc.
    pos2 = stat.posclusterslabelmat == 2;
    neg1 = stat.negclusterslabelmat == 1;
    neg2 = stat.negclusterslabelmat == 2;
end


% To be sure that your sample-based time windows align with your time windows in seconds, check the following:
timestep      = 0.002; % timestep between time windows for each subplot (in seconds)
sampling_rate = sigSTIM{1}.fsample; % Data has a temporal resolution of 300 Hz
sample_count  = length(stat.time);
% number of temporal samples in the statistics object
j = [0:timestep:1]; % Temporal endpoints (in seconds) of the ERP average computed in each subplot
m = [1:timestep*sampling_rate:sample_count]; % temporal endpoints in M/EEG samples

% First ensure the channels to have the same order in the average and in the statistical output.
% This might not be the case, because ft_math might shuffle the order
[i1,i2] = match_str(raweffectSTIMvsCNTRL.label, stat.label);

% % plot
% figure;
% for k = 1:20
%    subplot(4,5,k);
%    cfg = [];
%    t_lim = [j(k) j(k+1)];   % time interval of the subplot
%    colorbar_axes = [-0.5 0.5];
%    % If a channel is in a to-be-plotted cluster, then
%    % the element of pos_int with an index equal to that channel
%    % number will be set to 1 (otherwise 0).
% 
%    % Next, check which channels are in the clusters over the
%    % entire time interval of interest.
%    pos_int = zeros(numel(raweffectSTIMvsCNTRL.label),1);
%    neg_int = zeros(numel(raweffectSTIMvsCNTRL.label),1);
%    pos_int(i1) = all(pos(i2, m(k):m(k+1)), 2);
%    neg_int(i1) = all(neg(i2, m(k):m(k+1)), 2);
%    
%    % time indexes
%    t_idx = find(raweffectSTIMvsCNTRL.time >= t_lim(1) & raweffectSTIMvsCNTRL.time <= t_lim(2));
%    chanvalues = mean(raweffectSTIMvsCNTRL.avg(i1,t_idx),2);
%    ga_esg_isopotentialplot(1:subj_number, chanvalues, colorbar_axes, raweffectSTIMvsCNTRL.label(i1))
% %    highlight_idx = find(pos_int | neg_int);
% %    highlightvalues = zeros(numel(raweffectSTIMvsCNTRL.label),1); 
% %    highlightvalues(highlight_idx) = 1;
% %    if ~isempty(highlight_idx)
% %        ga_esg_isoplot_significantChans(1:subj_number, highlightvalues, raweffectSTIMvsCNTRL.label(i1))
% %    end
%    title(['time=' num2str(t_lim(1)) '-' num2str(t_lim(2)) 'ms'])
%    
%    
% end
   
%% plot GA and mark significant ivals
% figure;
% if nerve == 1
%     chan_grid = {   ''     'S3'   ''   ;
%                     'S5'   'S3'   'S7' ;
%                     'S5'   'S6'   'S7' ;
%                     'S9'   'S6'   'S11';
%                     'S9'   'SC6'  'S11';
%                     'S13'  'SC6'  'S15';
%                     'S13'  'S14'  'S15';
%                     'S17'  'S14'  'S19';
%                     'S17'  'S18'  'S19';
%                     ''     'S18'  ''    };  
% elseif nerve == 2
%     chan_grid = {   ''      'S20'   ''   ;
%                     'S22'   'S20'   'S24' ;
%                     'S22'   'S23'   'S24' ;
%                     'S26'   'S23'   'S28';
%                     'S26'   'L1'    'S28';
%                     'S30'   'L1'    'S32';
%                     'S30'   'S31'   'S32';
%                     'S34'   'S31'   'S36';
%                     'S34'   'S35'   'S36';
%                     ''      'S35'   ''    };  
% end
% grid_pos = reshape(1:30, 3, 10)';
% 
% for iplot = 1:numel(gaSTIM.label)
%     plot_idx = find(ismember(chan_grid, gaSTIM.label{iplot}));
%     plot_pos = grid_pos(plot_idx);
%     if ~isempty(plot_pos)
%         subplot(10,3,plot_pos); hold on
%         plot(gaSTIM.time, gaSTIM.avg(iplot,:))
%         plot(gaCNTRL.time, gaCNTRL.avg(iplot,:))
%         xlabel('Time [ms]')
%         ylabel(['Magnitude [' char(181) 'V]'])
%     end
% end  

% plot cluster
figure; hold on
x_lim = [-25 200]/1000;
t_idx = find(gaSTIM.time >= 0 & gaSTIM.time < 0.601);
hf = figure;
if nerve == 1
    ncluster = 3;
elseif nerve == 2
    ncluster =4;
end
for icluster = 1:ncluster
    if icluster == 1
        iv = find(sum(pos1,1))
        c = pos1;
        ss = [0.001 1 0.9 0.9];
    elseif icluster == 2
        iv = find(sum(pos2,1))
        c = pos2;
        ss = [0.001 1 0.5 0.5];
    elseif icluster == 3
        iv = find(sum(neg1,1))
        c = neg1;
        ss = [0.001 1 0.1 0.1];
    elseif icluster == 4
        iv = find(sum(neg2,1))
        c = neg2;
        ss = [0.001 1 0.1 0.1];
    end
    % find channels that are significant over the whole iv
    max_chan = max(sum(c(:,iv),2));
    chan_idx = find(sum(c(:,iv),2) == max_chan); % cluster channel indeces
    
    % average over cluster channels
    ha = subplot(ncluster,1,icluster);
    avgSTIM = mean(gaSTIM.avg(chan_idx,:),1);
    avgCNTRL = mean(gaCNTRL.avg(chan_idx,:),1);
    plot(gaSTIM.time, avgSTIM), hold on
    plot(gaCNTRL.time, avgCNTRL)
    x = gaSTIM.time(t_idx(iv));
    patch([x fliplr(x)], [avgSTIM(t_idx(iv)) fliplr(avgCNTRL(t_idx(iv)))], 'g')
    xlim(x_lim)
    hapos = get(ha, 'position');
    dim = hapos .* ss;
    annotation('textbox', dim, 'String', gaSTIM.label(chan_idx), 'FitBoxToText','on','verticalalignment', 'bottom')
    ylabel(['Magnitude [' char(181) 'V]'])
    xlabel('Time [ms]')
    title(['cluster ' num2str(icluster)])
    hold off
end
suptitle(['Results cluster analysis ' cond_name])
 


%% for publication
close all

%% make plots
%% ------------
% ==================== FIGURE SETTINGS ========================
fset = myFigureSettings(); % input: size(1) = width, size(2) = hight
fig_size = fset.fig_size; fig_size(1) = fig_size(1) * 1.5;
font_size = fset.font_size;


% ==================== COLOR SETTINGS ========================
color_code = {fset.late1 fset.late2 };
face_alpha = 0.3;


% ==================== GRAPH SETTINGS ========================
line_width = 1;
font_name = 'Roboto';
x_lim = [-100 600];
xtickpoints = -100:100:600;
xticklabels = {'-100' '0' '' '200' '' '400' '' '600'}';
is_au = false;

% ==================== PLOT FIGURE ============================

% plot first cluster
x_lim = [-50 300]/1000;
t_idx = find(gaSTIM.time >= 0 & gaSTIM.time < 0.601);
clstr{1} = pos1; 
clstr{2} = pos2; 
clstr{3} = neg1; 
clstr{4} = neg2; 
cluster_name = {'pos1' 'pos2' 'neg1' 'neg2'};
for icluster = 1:ncluster
    figure;
    set(gcf, 'units', 'centimeters', 'position', [1 1 fig_size(1) fig_size(2)])
    set(gca,'linewidth',1)
    set(gca,'FontSize', font_size)
    set(gca,'FontName', font_name)
    hold on,
    
    iv = find(sum(clstr{icluster},1));
    c = clstr{icluster};
    ss = [0.001 1 0.9 0.9];

    % find channels that are significant over the whole iv
    max_chan = max(sum(c(:,iv),2));
    chan_idx = find(sum(c(:,iv),2) == max_chan); % cluster channel indeces

    % average over cluster channels
    avgSTIM = mean(gaSTIM.avg(chan_idx,:),1);
    avgCNTRL = mean(gaCNTRL.avg(chan_idx,:),1);
    plot(gaSTIM.time, avgSTIM, 'Color', color_code{1}), hold on
    plot(gaCNTRL.time, avgCNTRL, 'Color', color_code{2})
    x = gaSTIM.time(t_idx(iv));
    patch([x fliplr(x)], [avgSTIM(t_idx(iv)) fliplr(avgCNTRL(t_idx(iv)))], 'g')
    xlim(x_lim)
    % title(gaSTIM.label(chan_idx))
    ylabel(['Magnitude [' char(181) 'V]'])
    xlabel('Time [ms]')
    hold off

    %% save
    fname = ['sep_latespinal_' cond_name '_grndAvg_long_cluster_'  cluster_name{icluster}];
    print([getenv('FIGUREPATH') fname], '-dpng', '-painters') 
    print([getenv('FIGUREPATH') fname], '-dsvg', '-painters') 
end
