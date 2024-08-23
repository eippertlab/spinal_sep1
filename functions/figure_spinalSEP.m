% Author: Birgit iNierula
% nierula@cbs.mpg.de

function figure_spinalSEP(condition, subjects)

% set path
savepath_ga = getenv('GADIR');

% condition info
srmr_nr = 1;
cond_info = get_conditionInfo(condition, srmr_nr);
cond_name = cond_info.cond_name;
nerve = cond_info.nerve;
trigger_name = cond_info.trigger_name;

if nerve == 2
    knee_chans = {'KneeM' 'Knee1' 'Knee2' 'Knee3' 'Knee4'};
    fname = [savepath_ga 'amplitudeAndLatency_allSubjects.mat'];
    load(fname, [cond_name '_values'])
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
data_levels = [3 5]; 
for dat_level = data_levels
    is_raw = false;
    out = ga_combineData(subjects, condition, srmr_nr, ...
        is_raw, dat_level);
    is_au = true;
    % all subjects
    for isubject = 1:length(subjects)
        if ~isempty(out{isubject})
            if isubject == length(subjects)
                epo_all.(['d' num2str(dat_level)]).times = out{isubject}.times;
            end
            if dat_level == 3 % esg TH6-Ref
                if nerve == 1
                    chan_names = {'SC6'};
                elseif nerve == 2
                    chan_names = {'L1'};
                end
                epo_all.(['d' num2str(dat_level)]).title = chan_names;
            elseif dat_level == 4 % esg ant-Ref
                if nerve == 1
                    chan_names = {'SC6'};
                elseif nerve == 2
                    chan_names = {'L1'};
                end
                epo_all.(['d' num2str(dat_level)]).title = chan_names;
            elseif dat_level == 5 % esg cca
                chan_names = {NaN};
                if nerve == 1
                    epo_all.(['d' num2str(dat_level)]).title = {'cervical CCA'};
                elseif nerve == 2
                    epo_all.(['d' num2str(dat_level)]).title = {'lumbar CCA'};
                end
            end
            
            for ichan = 1:length(chan_names)
                if ~isnan(chan_names{ichan})
                    chan_idx = find(ismember({out{isubject}.chanlocs.labels},chan_names{ichan}));
                else
                    chan_idx = 1;
                end
                % normalize data
                dat(1,:,:) = normalize_2zscore(squeeze(out{isubject}.data(chan_idx,:,:)));
                if length(subjects) > 1
                    epo_all.(['d' num2str(dat_level)]).data(ichan,:,isubject) = nanmean(dat, 3);
                    clear dat
                else
                    epo_all.(['d' num2str(dat_level)]).data(ichan,:,:) = dat;
                end
                clear dat
            end
            epo_all.(['d' num2str(dat_level)]).potLatency = out{isubject}.potLatency;
            %epo_all.(['d' num2str(dat_level)]).potWindow = out{isubject}.potWindow;
            epo_all.(['d' num2str(dat_level)]).is_au = is_au;
        end
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
color_code = {fset.mixed2 fset.mixed};
face_alpha = 0.3;


% ==================== GRAPH SETTINGS ========================
line_width = 1;
font_name = 'Roboto';

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


for ii = 1:length(data_levels)
    ichan = 1;
    epo = epo_all.(['d' num2str(data_levels(ii))]);

    % calculate mean and sem
    grndAvg = nanmean(epo.data(ichan, :, :), 3);
    if length(subjects) > 1
        grndSem = nanstd(epo.data(ichan, :, :), [], 3) / sqrt(size(epo.data, 3));
        error_band = fill([epo.times fliplr(epo.times)], [grndAvg-grndSem fliplr(grndAvg+grndSem)], color_code{1}, 'LineStyle','none');

        % plot
        set(error_band, 'facealpha', face_alpha);
    end
    h = plot( epo.times, grndAvg, 'Color', color_code{ii}, 'linewidth', line_width );

    clear grndAV grndSem


    legend_name{ii} = epo.title{ichan};  
    legend_lines(ii) = h;
end
legend1 = legend (legend_lines, legend_name);
set(legend1,...
    'Position',[0.56 0.25 0.43 0.18]);
set(gcf, 'color', [1 1 1]); box off;
xlim(x_lim)
set(gca, 'Xtick', xtickpoints)
xlabel('Time [ms]')
set(gca, 'XTickLabel', xticklabels)

ylim('auto') %ylim(y_lim)%ylim('auto')
%set(gca, 'Ytick', y_lim(1):2:y_lim(2))
if ~epo.is_au
    ylabel(['[' char(181) 'V]'])
else
    ylabel('[a.u.]')
end
grid on


%% save
if length(subjects) > 1
    fname = ['sep_spinal_' cond_name '_grndAvg'];
else
    fname = ['sep_spinal_' cond_name sprintf('_sub-%03i', subjects)];
end
print([getenv('FIGUREPATH') fname], '-dpng', '-painters') 
print([getenv('FIGUREPATH') fname], '-dsvg', '-painters')  


%% convert to excel
%% ------------
% 1 = eeg clean
% 2 = eeg cca
% 3 = esg clean TH6 ref
% 4 = esg clean anterior ref
% 5 = esg cca
% 6 = brainstem
% 7 = eng
% columns: counter, time, subject trace
excel_fname = [getenv('FIGUREPATH') 'Figure_03.xlsx'];
levels = {'eeg' 'eeg-cca' 'esg-TH6' 'esg-antRef' 'esg-cca' 'brainstem' 'eng'};
sheet_names = levels(data_levels);
all_data = epo_all;
struct_names = fieldnames(all_data);
for ii = 1:length(sheet_names)
    for tt = 1:length(all_data.(struct_names{ii}).title)
        time = all_data.(struct_names{ii}).times;
        counter = 0:length(time)-1;
        sheet_name = sheet_names{ii};
        tmp_data = [counter' time' squeeze(all_data.(struct_names{ii}).data(tt,:,:))];
        writematrix(tmp_data, excel_fname, 'Sheet', sprintf('%s', [cond_name '_' sheet_name '_' all_data.(struct_names{ii}).title{tt}]))
    end
end