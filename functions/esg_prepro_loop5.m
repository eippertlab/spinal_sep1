% Author: Birgit Nierula
% nierula@cbs.mpg.de

function esg_prepro_loop5(subject, condition, srmr_nr)


%% set variables
subject_id = sprintf('sub-%03i', subject);
analysis_path = [getenv('ANADIR') subject_id '/esg/prepro/'];
cfg_path = getenv('CFGDIR');

% get condition info
[cond_info] = get_conditionInfo(condition, srmr_nr);
cond_name = cond_info.cond_name;
trigger_name = cond_info.trigger_name;
nerve = cond_info.nerve;
nblocks = cond_info.nblocks;

%% set up zim page
zim_path = getenv('ZIMDIR');
page_name = '02_timefrequency_plots';
% check if zim page exists and create it if not
page_path = zim_path;
page_title = [];
if ~exist([page_path page_name '.txt'], 'file')
    zim_newpage(page_path, page_name, page_title)
end
figure_path = [page_path page_name '/'];
if ~exist(figure_path, 'dir')
    mkdir(figure_path)
end
% create zim subpage for each participant
page_name = subject_id;
page_path = figure_path;
page_title = [];
figure_path = [page_path page_name '/'];
if ~exist([page_path page_name '.txt'], 'file')
    zim_newpage(page_path, page_name, page_title)
    pause(2)
end
txt_filename = [page_path page_name '.txt'];
mytext =  '';
text_level = 0;
zim_addText(txt_filename, mytext, text_level)


%% load cleaned ESG data
load_path = [analysis_path 'ecgclean_' cond_name '/'];
fname = ['cnt_clean_ecg_spinal_' cond_name '.set'];
cnt = pop_loadset('filename', fname, 'filepath', load_path);
clear load_path


%% make time-frequency plots
if nerve == 1
	chan_names = {'SC6'}; 
else
    chan_names = {'L1'}; 
end
x_lim = [-50 100];

for iplot = 1:length(chan_names)
    
    chan_idx = find(ismember({cnt.chanlocs.labels}, chan_names(iplot)));
    cnt1 = pop_select(cnt, 'channel', chan_idx);
    
    % epoch data
    load([cfg_path 'cfg.mat'], 'iv_epoch', 'iv_baseline')
    iv_epoch = iv_epoch/1000;
    epo1 = pop_epoch( cnt1, trigger_name, iv_epoch, 'newname', ...
        'SpinalSEP Epochs', 'epochinfo', 'yes' );
    epo1 = pop_rmbase(epo1, iv_baseline);
    epo_av = epo1; epo_av.data = nanmean(epo1.data, 3);
    
    % plot average
    figure_name = ['avg_' subject_id '_' cond_name '_' chan_names{iplot}];
    figure('units','normalized','outerposition',[0 0 1 1]);
    plot(epo_av.times, epo_av.data)
    xlim(x_lim)
    xlabel('time [ms]')
    ylabel('[microV]')
    title(figure_name)
    % save plot
    print([figure_path figure_name],'-dpng')
    % link figure to lab book and add some text
    txt_filename = [page_path page_name '.txt'];
    figure_filename = [figure_name '.png'];
    figure_title = [cond_name ': channel ' chan_names{iplot}];
    title_level = 2;
    figure_width = [];
    zim_addFigure(txt_filename, figure_filename, figure_title, title_level, figure_width)
    mytext = [''];
    text_level = 0;
    zim_addText(txt_filename, mytext, text_level)
    
    % make tf-plot
    figure_name = ['tf_plot_' subject_id '_' cond_name '_' chan_names{iplot}];
    min_freq = 1; 
    max_freq = 500;
    num_frex = 50;
    color_range = [];
    is_normalized = true;
    figure('units','normalized','outerposition',[0 0 1 1]);
    proc_tf_plots(epo_av, min_freq, max_freq, num_frex, [], color_range, ...
        is_normalized)
    xlim(x_lim)
    title(figure_name)
    % save plot
    print([figure_path figure_name],'-dpng')
    % link figure to lab book and add some text
    txt_filename = [page_path page_name '.txt'];
    figure_filename = [figure_name '.png'];
    figure_title = [cond_name ': channel ' chan_names{iplot}];
    title_level = 2;
    figure_width = [];
    zim_addFigure(txt_filename, figure_filename, figure_title, title_level, figure_width)
    mytext = [''];
    text_level = 0;
    zim_addText(txt_filename, mytext, text_level)
    clear epo1 epo_av cnt1
end

