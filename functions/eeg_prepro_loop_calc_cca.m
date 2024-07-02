% Author: Birgit Nierula
% nierula@cbs.mpg.de

function eeg_prepro_loop_calc_cca(subject, nerve, srmr_nr, ref_chan, plot_graphs)


%% set variables
subject_id = sprintf('sub-%03i', subject);
save_path = [getenv('EEGDIR') subject_id '/'];
cfg_path = getenv('CFGDIR');

% get condition info
if nerve == 1
    nerve_name = 'medianus';
elseif nerve == 2
    nerve_name = 'tibialis';
end


% load data
ref_name = 'avgRef_'; % keeping recording reference


if srmr_nr == 1
    fname = ['epo_' ref_name 'cleanclean_' nerve_name(1:end-2) '.set'];
    epo = pop_loadset('filename', fname, 'filepath', save_path);
elseif srmr_nr == 2
    fname = ['epo_' ref_name 'cleanclean_' nerve_name(1:3) '_mixed.set'];
    epo = pop_loadset('filename', fname, 'filepath', save_path);
    fname = ['epo_' ref_name 'cleanclean_' nerve_name(1:3) '_digits.set'];
    epo_d = pop_loadset('filename', fname, 'filepath', save_path);
end

if plot_graphs
    %% lab book
    % set up condition page in lab book
    page_name = nerve_name;
    page_path = [getenv('ZIMDIR') '03_CCA_mixed_' ref_chan '_Ref/'];
    page_title = [];
    if ~exist([page_path page_name '.txt'], 'file')
        zim_newpage(page_path, page_name, page_title)
    end
    figure_path1 = [page_path page_name '/'];
    txt_filename = [page_path page_name '.txt'];
    mytext =  '';
    text_level = 0;
    zim_addText(txt_filename, mytext, text_level)
    
    % set up subject page
    page_name = subject_id;
    page_path = figure_path1;
    page_title = [];
    figure_path2 = [page_path page_name '/'];
    if ~exist([page_path page_name '.txt'], 'file')
        zim_newpage(page_path, page_name, page_title)
        pause(2)
    end
    txt_filename = [page_path page_name '.txt'];
    mytext =  '';
    text_level = 0;
    zim_addText(txt_filename, mytext, text_level)
end

%% Canonical Component Analysis (CCA)
%% ===================================
% selected Channels
[eeg_chans, ~, ~] = get_channels(subject, false, false, srmr_nr);
chan_names = [eeg_chans {'RM'}]; clear eeg_chans
chan_idx = find(ismember({epo.chanlocs.labels}, chan_names));
epo = pop_select(epo, 'channel', chan_idx);
if srmr_nr == 2
    chan_idx = find(ismember({epo_d.chanlocs.labels}, chan_names));
    epo_d = pop_select(epo_d, 'channel', chan_idx);
end

% cca window size
halfwindow_size = 10/2;

% raw data peak
fpath = [save_path 'potential_latency.mat'];
load(fpath, [nerve_name(1:3) '_potlatency'])
eval(['sep_latency = ' nerve_name(1:3) '_potlatency;'])

% select time window
potential_window = [sep_latency-halfwindow_size sep_latency+halfwindow_size]; %in ms
% make sure window doesn't include interpolation window
load([cfg_path 'interpolation_window.mat'], 'interpol_window')
tmp = [interpol_window.x(subject,2:3); interpol_window.x(subject,4:5)];
interpol_window_esg = [min(tmp(:,1)) max(tmp(:,2))];
if potential_window(1) < interpol_window_esg(2)
    potential_window = [interpol_window_esg(2) interpol_window_esg(2) + 2*halfwindow_size+1];
end
potential_window = potential_window / 1000; % in sec

% cut signal
epo_cca = pop_select(epo, 'time', potential_window);


% prepare matrices for cca
% average matrix
epoav = mean(epo_cca.data(:, :, :), 3)';
avg_matrix = repmat(epoav, epo_cca.trials, 1); % obervations x channels

% single trial matrix
st_matrix = reshape(epo_cca.data, epo_cca.nbchan, epo_cca.pnts * epo_cca.trials)'; % observations x channels
st_matrix_long = reshape(epo.data, epo.nbchan, epo.pnts * epo.trials)'; % observations x channels


%% run CCA
[W_av, W_st, R] = canoncorr(avg_matrix, st_matrix); % W = canonical coefficients, R = sample canoical correlations

% number of components
all_components = size(R,2);

if plot_graphs
    figure
    bar(1:size(R,2), R)
    ylabel('sample canonical correlation'), xlabel('component number')
    title([subject_id ' - ' nerve_name ':CCA - components'])
    
    % save in lab book
    figure_name = [subject_id '_' nerve_name '_' ...
        num2str(potential_window(1, 1)*1000) '-' ...
        num2str(potential_window(1, 2)*1000) '_cca_correlations'];
    print([figure_path2 figure_name],'-dpng')
    % link figure to lab book and add some text
    txt_filename = [page_path page_name '.txt'];
    figure_filename = [figure_name '.png'];
    figure_title = 'Sample canonical correlations of CCA compontents';
    title_level = 2;
    figure_width = [];
    zim_addFigure(txt_filename, figure_filename, figure_title, title_level, figure_width)
    mytext = [''];
    text_level = 0;
    zim_addText(txt_filename, mytext, text_level)
end


%% Apply obtained weights to long dataset (according to eval_win)
CCA_concat = (st_matrix_long * W_st(:, 1:all_components))';
if srmr_nr == 2
    % apply weights to digits
    st_matrix_digits = reshape(epo_d.data, epo_d.nbchan, epo_d.pnts * epo_d.trials)';
    CCA_concat_d = (st_matrix_digits * W_st(:, 1:all_components))';
end

%% Spatial patterns
A_st = cov(st_matrix) * W_st;
if plot_graphs
    figure('units','normalized','outerposition',[0 0 1 1])
    for icomp = 1:all_components
        subplot(2, ceil(all_components/2), icomp)
        colorbar_axes = [];
        topoplot( A_st(:,icomp), epo.chanlocs)
        title(['comp ' num2str(icomp)])
    end
    suptitle([subject_id ' - ' nerve_name ': CCA - spatial pattern'])
    
    % save in lab book
    figure_name = [subject_id '_' nerve_name '_' ...
        num2str(potential_window(1, 1)*1000) '-' ...
        num2str(potential_window(1, 2)*1000) '_cca_spatialPatterns'];
    print([figure_path2 figure_name],'-dpng')
    % link figure to lab book and add some text
    txt_filename = [page_path page_name '.txt'];
    figure_filename = [figure_name '.png'];
    figure_title = 'CCA: Spatial patterns of all components';
    title_level = 2;
    figure_width = [];
    zim_addFigure(txt_filename, figure_filename, figure_title, title_level, figure_width)
    mytext = [''];
    text_level = 0;
    zim_addText(txt_filename, mytext, text_level)
end


%% Re-reshape
CCA_comps = reshape(CCA_concat, all_components, epo.pnts, epo.trials);
if srmr_nr == 2
    CCA_comps_d = reshape(CCA_concat_d, all_components, epo_d.pnts, epo_d.trials);
end


% plot time course of CCA components
y_range = [-100 200];
figure('units','normalized','outerposition',[0 0 1 1])
for icomp = 1:all_components
    selected_components = icomp;
    
    epo_cca = epo; epo_cca.data = [];
    epo_cca.data = CCA_comps(selected_components, :, :);
    epo_cca = pop_select(epo_cca, 'time', y_range);
    % set to baseline
    epo_cca = pop_rmbase(epo_cca, [-100 -10]);
    
    if srmr_nr == 2
        epod_cca = epo_d; epod_cca.data = [];
        epod_cca.data = CCA_comps_d(selected_components, :, :);
        epod_cca = pop_select(epod_cca, 'time', y_range);
        % set to baseline
        epod_cca = pop_rmbase(epod_cca, [-100 -10]);
    end
    
    
    
    %% check if it needs to be inverted
    if icomp == 1
        idx = find(epo_cca.times > sep_latency-3 & epo_cca.times < sep_latency+3 );
        tmp_dat = mean(mean(epo_cca.data(:,idx,:), 3), 2);
        is_inverted = false;
        if nerve == 2
            if tmp_dat < 0
                is_inverted = true;
            end
        else
            if tmp_dat > 0
                is_inverted = true;
            end
        end
        if is_inverted
            epo_cca.data = epo_cca.data * (-1);
            if srmr_nr == 2
                epod_cca.data = epod_cca.data * (-1);
            end
        end
    else
        if is_inverted
            epo_cca.data = epo_cca.data * (-1);
            if srmr_nr == 2
                epod_cca.data = epod_cca.data * (-1);
            end
        end
    end
    
    %% save info: CCA weights, whether inverted, cleaned data
    file_name = [save_path 'cca_info_' nerve_name(1:3) 'mixed.mat'];
    save(file_name, 'W_av', 'W_st', 'R', 'is_inverted')
    
    if plot_graphs
        %% make plot
        subplot(2, ceil(all_components/2), icomp); hold on;
        %% 1) compare cleaned signal with CCA
        if nerve == 1
            chan_str = 'CP4';
            x_lim = [-25 50];
        elseif nerve == 2
            chan_str = 'Cz';
            x_lim = [-25 70];
        end
        % select time window
        if nerve == 1
            epo_raw = pop_select(epo, 'time', [-0.025 0.065]);
            epo_cca = pop_select(epo_cca, 'time', [-0.025 0.065]);
            if srmr_nr == 2
                epod_cca = pop_select(epod_cca, 'time', [-0.025 0.065]);
            end
        else
            epo_raw = pop_select(epo, 'time', [-0.025 0.085]);
            epo_cca = pop_select(epo_cca, 'time', [-0.025 0.085]);
            if srmr_nr == 2
                epod_cca = pop_select(epod_cca, 'time', [-0.025 0.085]);
            end
        end
        idx = find(ismember({epo_raw.chanlocs.labels}, chan_str));
        epo_raw.data = epo_raw.data(idx, :, :);
        
        % normalize
        tmp = normalize_2zscore(squeeze(epo_raw.data)');
        epo_raw.data(1, :, :) = tmp'; clear tmp
        tmp = normalize_2zscore(squeeze(epo_cca.data)');
        epo_cca.data(1, :, :) = tmp'; clear tmp
        if srmr_nr == 2
            tmp = normalize_2zscore(squeeze(epod_cca.data)');
            epod_cca.data(1, :, :) = tmp'; clear tmp
        end
        
        plot(epo_raw.times, mean(epo_raw.data, 3), 'LineWidth', 2)
        plot(epo_cca.times, mean(epo_cca.data, 3), 'LineWidth', 2)
        if srmr_nr == 2
            plot(epod_cca.times, mean(epod_cca.data, 3), 'LineWidth', 2)
        end
        ylabel('normalized [a.u.]'), xlabel('time [ms]')
        xlim(x_lim)
        title([chan_str ' / Component ' num2str(icomp)])
    end
end

if plot_graphs
    legend ({'mixed ECG-clean' 'CCA mixed' 'CCA digits'})
    suptitle([subject_id ' - ' nerve_name])
    
    % save in lab book
    figure_name = [subject_id '_' nerve_name '_' ...
        num2str(potential_window(1, 1)*1000) '-' ...
        num2str(potential_window(1, 2)*1000) '_' chan_str ...
        'cca_sep'];
    print([figure_path2 figure_name],'-dpng')
    % link figure to lab book and add some text
    txt_filename = [page_path page_name '.txt'];
    figure_filename = [figure_name '.png'];
    figure_title = ['SEPs of CCA compontents and of target channel (' chan_str ')'];
    title_level = 2;
    figure_width = [];
    zim_addFigure(txt_filename, figure_filename, figure_title, title_level, figure_width)
    mytext = [''];
    text_level = 0;
    zim_addText(txt_filename, mytext, text_level)
end

close all


