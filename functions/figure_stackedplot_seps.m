% Author: Birgit Nierula
% nierula@cbs.mpg.de

function figure_stackedplot_seps(condition, srmr_nr, subjects)

% set path
savepath_ga = getenv('GADIR');

% condition info
cond_info = get_conditionInfo(condition, srmr_nr);
cond_name = cond_info.cond_name;
nerve = cond_info.nerve;
str_stimulation = cond_info.str_stimulation;

if nerve == 2
    fname = [savepath_ga 'amplitudeAndLatency_allSubjects.mat'];
    load(fname, 'name_kneemax')
end

% data level:
% 1 = eeg clean
% 2 = eeg cca
% 3 = esg clean TH6 ref
% 4 = esg clean anterior ref
% 5 = esg cca
% 6 = brainstem
% 7 = eng

% take single subject average  
data_levels = [1 6 4 7 ];
for dat_level = data_levels
    is_raw = false;
    out = ga_combineData(subjects, condition, srmr_nr, ...
        is_raw, dat_level);
    is_au = false;
    if dat_level == 2 || dat_level == 5
        is_au = true;
    end
    % all subjects
    for isubject = 1:length(subjects)
        if ~isempty(out{isubject})
            if dat_level == 10 % emg
                if nerve == 1
                    chan_names = {'Thumb'};
                    epo_all.(['d' num2str(dat_level)]).title = {'APB'};
                elseif nerve == 2
                    chan_names = {'Toe'};
                    epo_all.(['d' num2str(dat_level)]).title = {'FHB'};
                end
                
            elseif dat_level == 7 %eng
                if nerve == 1
                    chan_names = { 'EP' 'Biceps'};
                    epo_all.(['d' num2str(dat_level)]).title = {'left EP - rigth EP' 'axilla' };
                elseif nerve == 2
                    chan_names = name_kneemax(isubject);
                    epo_all.(['d' num2str(dat_level)]).title = {'popliteal fossa'};
                end
                
            elseif dat_level == 3 % esg TH6-Ref
                if nerve == 1
                    chan_names = {'SC6'};
                    epo_all.(['d' num2str(dat_level)]).title = {'SC6-TH6'};
                elseif nerve == 2
                    chan_names = {'L1' 'L4'};
                    epo_all.(['d' num2str(dat_level)]).title = {'L1-TH6' 'L4-TH6'};
                end
            elseif dat_level == 4 % esg ant-Ref
                if nerve == 1
                    chan_names = {'SC6'};
                    epo_all.(['d' num2str(dat_level)]).title = {'SC6-AC'};
                elseif nerve == 2
                    chan_names = {'L1' 'L4'};
                    epo_all.(['d' num2str(dat_level)]).title = {'L1-AC' 'L4-AC'};
                end
            elseif dat_level == 6 % bs
                if nerve == 1
                    chan_names = {'SC1'};
                elseif nerve == 2
                    chan_names = {'S3'};
                end
                epo_all.(['d' num2str(dat_level)]).title = {[chan_names{1} '-Fpz']};
            
            elseif dat_level == 1 % eeg
                if nerve == 1
                    chan_names = {'CP4'};
                elseif nerve == 2
                    chan_names = {'Cz'};
                end
                epo_all.(['d' num2str(dat_level)]).title = chan_names;
            end

            for ichan = 1:length(chan_names)
                if ~isnan(chan_names{ichan})
                    chan_idx = find(ismember({out{isubject}.chanlocs.labels},chan_names{ichan}));
                else
                    chan_idx = 1;
                end
                if length(subjects) > 1
                    epo_all.(['d' num2str(dat_level)]).data(ichan,:,isubject) = nanmean(out{isubject}.data(chan_idx,:,:), 3);
                else
                    epo_all.(['d' num2str(dat_level)]).data(ichan,:,:) = out{isubject}.data(chan_idx,:,:);
                end
                    
                if length(subjects) == 1 
                    epo_all.(['d' num2str(dat_level)]).times = out{isubject}.times;
                    epo_all.(['d' num2str(dat_level)]).chanlocs(ichan) = out{isubject}.chanlocs(chan_idx);    
                end
            end
            epo_all.(['d' num2str(dat_level)]).potLatency(isubject,:) = out{isubject}.potLatency;
            epo_all.(['d' num2str(dat_level)]).potWindow(isubject,:) = out{isubject}.potWindow;
            epo_all.(['d' num2str(dat_level)]).is_au = is_au;
            if isubject == 1
                epo_all.times = out{isubject}.times;
            end
            
        end
    end
end

%% make plots
%% ------------
fset = myFigureSettings(); % input: size(1) = width, size(2) = hight
fig_size = fset.fig_size; 
fig_size(1) = fig_size(1) * 1; % width
fig_size(2) = fig_size(2) * 3; % hight
font_size = fset.font_size;

% ==================== FIGURE SETTINGS ========================
figure;
set(gcf, 'units', 'centimeters', 'position', [1 1 fig_size(1) fig_size(2)])


% ==================== COLOR SETTINGS ========================
color_code = {fset.mixed};
face_alpha = 0.3;


% ==================== GRAPH SETTINGS ========================
line_width = 1;
font_name = 'Roboto';

if nerve == 1
    chan_number = length(data_levels) + 1;
else
    chan_number = length(data_levels);
end

chan_counter = 0;
line_level = 100;
line_level_start = line_level;
y_space = 5;
for ii = 1:length(data_levels)
    epo = epo_all.(['d' num2str(data_levels(ii))]);
    for ichan = 1:size(epo.data,1)
        chan_counter = chan_counter + 1;

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
        hold on;

        grndAvg = nanmean(epo.data(ichan, :, :), 3) + line_level;
        if length(subjects) > 1
            grndSem = nanstd(epo.data(ichan, :, :), [], 3) / sqrt(size(epo.data, 3)); 
        else
            grndSem = nanstd(epo.data(ichan, :, :), [], 3); 
        end
        error_band = fill([epo_all.times fliplr(epo_all.times)], [grndAvg-grndSem fliplr(grndAvg+grndSem)], color_code{1}, 'LineStyle','none');
        set(error_band, 'facealpha', face_alpha);
        plot( epo_all.times, grndAvg, 'Color', color_code{1}, 'linewidth', line_width );
        xlim(x_lim)
        text(x_lim(2), line_level, epo.title{ichan})
        
        if data_levels(ii) == 4 && ichan == 1
            x_line = nanmean(epo.potLatency(:,1));
        end
        
        clear grndAV grndSem
        
        line_level = line_level - y_space;
        
        clear grndAV grndSem error_band
    end
end
xline(0,'--');
xline(x_line,'--');
set(gcf, 'color', [1 1 1]); box off;
set(gca, 'Xtick', xtickpoints)
xlabel('Time [ms]')
set(gca, 'XTickLabel', xticklabels)

tmp_yticks = [line_level:y_space:line_level_start]';
tmp_y = [tmp_yticks-1.5 tmp_yticks tmp_yticks+1.5]';
ytickpoints = tmp_y(:);

tick_counter = 0;
for ilabel = 1:length(tmp_yticks)
    tick_counter = tick_counter + 1;
    yticklabels(tick_counter:tick_counter+2) = {'-1.5' '0' '1.5'}';
    tick_counter = tick_counter + 2;
end
ylim('auto') %ylim(y_lim)%ylim('auto')
set(gca, 'Ytick', single(ytickpoints'))
ylabel(['[' char(181) 'V]'])
set(gca, 'YTickLabel', yticklabels)

        

if length(subjects) > 1     
    fname = ['sep_stackedPlot_' cond_name '_grndAvg'];
else
    fname = ['sep_stackedPlot_' cond_name sprintf('_sub-%03i', subjects)];
end
print([getenv('FIGUREPATH') fname], '-dpng', '-painters') 
print([getenv('FIGUREPATH') fname], '-dsvg', '-painters')    
