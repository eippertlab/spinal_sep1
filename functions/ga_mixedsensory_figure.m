function ga_mixedsensory_figure(subjects, nerve)


%% set variables
srmr_nr = 2;
figure_path = getenv('FIGUREPATH');
if nerve == 1
    % channels
    chan_names = {'esg_cca'};
    nerve_name = 'med';
elseif nerve == 2
    % channels
    chan_names = {'esg_cca'};
    nerve_name = 'tib';
end
fname_start = 'epo_ccacleanclean_';

for ichan = 1:length(chan_names)
    
    for isubject = 1:length(subjects)
        % get path
        subject_id = sprintf('sub-%03i', subjects(isubject));
        load_path = [getenv('ESGDIR') subject_id '/'];
        % load d12 data
        fname = [fname_start nerve_name '_d12.set'];
        tmp_d12 = pop_loadset('filename', fname, 'filepath', load_path);
        % load mixed data
        fname = [fname_start nerve_name '_mixed.set'];
        tmp_m = pop_loadset('filename', fname, 'filepath', load_path);
        
        % take mean and combine all subjects
        if isubject == 1
            epo_d12 = tmp_d12; epo_d12.data = [];
            epo_m = tmp_m; epo_m.data = [];
        end
        if tmp_d12.nbchan == 1
            chan_idx = 1;
            epo_d12.data(chan_idx, :, isubject) = nanmean(tmp_d12.data, 3);
        end
        if tmp_m.nbchan == 1
            chan_idx = 1;
            epo_m.data(chan_idx, :, isubject) = nanmean(tmp_m.data, 3);
        end
    end
    
    %% make plots
    %% ------------
    fset = myFigureSettings(); % input: size(1) = width, size(2) = hight
    fig_size = fset.fig_size;
    font_size = fset.font_size;
    % ==================== FIGURE SETTINGS ========================
    figure;
    set(gcf, 'units', 'centimeters', 'position', [1 1 fig_size(1) fig_size(2)])
    
    
    % ==================== COLOR SETTINGS ========================
    color_code = {fset.mixed fset.digits12};
    face_alpha = 0.3;
    
    
    % ==================== GRAPH SETTINGS ========================
    line_width = 1;
    font_name = fset.font_name;
    
    if nerve == 1
        x_lim = [-20 60];
        xtickpoints = -20:10:60;
        xticklabels = {'-20' '' '0' '' '20' '' '40' '' '60'}';
    elseif nerve == 2
        x_lim = [-20 80];
        xtickpoints = -20:10:80;
        xticklabels = {'-20' '' '0' '' '20' '' '40' '' '60' '' '80'}';
    end
    
    set(gca,'linewidth',1)
    set(gca,'FontSize', font_size)
    set(gca,'FontName', font_name)
    
    % ==================== PLOT FIGURE ============================
    hold on,
    
    
    %% Mixed
    % calculate mean and sem
    grndAvg = nanmean(epo_m.data(ichan, :, :), 3);
    grndSem = nanstd(epo_m.data(ichan, :, :), [], 3) / sqrt(size(epo_m.data, 3));
    error_band = fill([epo_m.times fliplr(epo_m.times)], [grndAvg-grndSem fliplr(grndAvg+grndSem)], ...
        color_code{1}, 'LineStyle','none');
    % plot
    set(error_band, 'facealpha', face_alpha);
    h(1) = plot( epo_m.times, grndAvg, 'Color', color_code{1}, 'linewidth', line_width );
    clear grndAV grndSem
    legend_name{1} = 'mixed';
    
    %% D12
    % calculate mean and sem
    grndAvg = nanmean(epo_d12.data(ichan, :, :), 3);
    grndSem = nanstd(epo_d12.data(ichan, :, :), [], 3) / sqrt(size(epo_d12.data, 3));
    error_band = fill([epo_d12.times fliplr(epo_d12.times)], [grndAvg-grndSem fliplr(grndAvg+grndSem)], ...
        color_code{2}, 'LineStyle','none');
    % plot
    set(error_band, 'facealpha', face_alpha);
    h(2) = plot( epo_d12.times, grndAvg, 'Color', color_code{2}, 'linewidth', line_width );
    clear grndAV grndSem
    legend_name{2} = 'd12';
    
    legend1 = legend (h([1 2]), legend_name);
    set(legend1,...
        'Position',[0.15 0.83 0.07 0.06]);
    set(gcf, 'color', [1 1 1]); box off;
    xlim(x_lim)
    set(gca, 'Xtick', xtickpoints)
    xlabel('Time [ms]')
    set(gca, 'XTickLabel', xticklabels)
    
    ylim('auto') %ylim(y_lim)%ylim('auto')
    %set(gca, 'Ytick', y_lim(1):2:y_lim(2))
    ylabel('[a.u.]')
    grid on
    
    %% save
    if length(subjects) > 1
        figure_name = [figure_path 'mixedsensory_' nerve_name '_' chan_names{ichan} '_grndAvg'];
    else
        figure_name = [figure_path 'mixedsensory_' nerve_name '_' chan_names{ichan} '_' subject_id];
    end
    print(figure_name, '-dpng', '-painters')
    print(figure_name, '-dsvg', '-painters')
end
