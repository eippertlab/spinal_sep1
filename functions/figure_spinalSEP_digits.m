function figure_spinalSEP_digits(condition, subjects)

% set path
savepath_ga = getenv('GADIR');

% condition info
srmr_nr = 2;
cond_info = get_conditionInfo(condition, srmr_nr);
cond_name = cond_info.cond_name;
nerve = cond_info.nerve;

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
% 10 = emg

% take single subject average
data_levels = [2 5 7]; % EEG-CCA ESG-CCA ENG
for dat_level = data_levels
    is_raw = false;
    out = ga_combineData(subjects, condition, srmr_nr, ...
        is_raw, dat_level);
    is_au = true;
    % all subjects
    for isubject = 1:length(subjects)
        if ~isempty(out{isubject})
            if isubject == length(subjects)
                epo_all1.(['d' num2str(dat_level)]).times = out{isubject,1}.times;
                epo_all2.(['d' num2str(dat_level)]).times = out{isubject,2}.times;
                epo_all12.(['d' num2str(dat_level)]).times = out{isubject,3}.times;
            end
            
            if dat_level == 2 % eeg cca
                chan_names = {NaN};
                epo_all1.(['d' num2str(dat_level)]).title = {'cortical CCA'};
                epo_all2.(['d' num2str(dat_level)]).title = {'cortical CCA'};
                epo_all12.(['d' num2str(dat_level)]).title = {'cortical CCA'};
            
            elseif dat_level == 5 % esg cca
                chan_names = {NaN};
                if nerve == 1
                    epo_all1.(['d' num2str(dat_level)]).title = {'cervical CCA'};
                    epo_all2.(['d' num2str(dat_level)]).title = {'cervical CCA'};
                    epo_all12.(['d' num2str(dat_level)]).title = {'cervical CCA'};
                elseif nerve == 2
                    epo_all1.(['d' num2str(dat_level)]).title = {'lumbar CCA'};
                    epo_all2.(['d' num2str(dat_level)]).title = {'lumbar CCA'};
                    epo_all12.(['d' num2str(dat_level)]).title = {'lumbar CCA'};
                end
                
            elseif dat_level == 7 % eng
                if nerve == 1
                    chan_names = {'Biceps'};
                    epo_all1.(['d' num2str(dat_level)]).title = chan_names{1};
                    epo_all2.(['d' num2str(dat_level)]).title = chan_names{1};
                    epo_all12.(['d' num2str(dat_level)]).title = chan_names{1};
                elseif nerve == 2
                    chan_names = name_kneemax(isubject);
                    epo_all1.(['d' num2str(dat_level)]).title = {'Knee'};
                    epo_all2.(['d' num2str(dat_level)]).title = {'Knee'};
                    epo_all12.(['d' num2str(dat_level)]).title = {'Knee'};
                end
                is_au = false;
            end
            
            for ichan = 1:length(chan_names)
                if ~isnan(chan_names{ichan})
                    chan_idx = find(ismember({out{isubject,1}.chanlocs.labels},chan_names{ichan}));
                else
                    chan_idx = 1;
                end
                
                dat1(1,:,:) = squeeze(out{isubject,1}.data(chan_idx,:,:));
                dat2(1,:,:) = squeeze(out{isubject,2}.data(chan_idx,:,:));
                dat12(1,:,:) = squeeze(out{isubject,3}.data(chan_idx,:,:));
                
                if length(subjects) > 1
                    epo_all1.(['d' num2str(dat_level)]).data(ichan,:,isubject) = nanmean(dat1, 3);
                    epo_all2.(['d' num2str(dat_level)]).data(ichan,:,isubject) = nanmean(dat2, 3);
                    epo_all12.(['d' num2str(dat_level)]).data(ichan,:,isubject) = nanmean(dat12, 3);
                    clear dat
                else
                    epo_all1.(['d' num2str(dat_level)]).data(ichan,:,:) = dat1;
                    epo_all2.(['d' num2str(dat_level)]).data(ichan,:,:) = dat2;
                    epo_all12.(['d' num2str(dat_level)]).data(ichan,:,:) = dat12;
                end
                clear dat1 dat2 dat12
            end
            epo_all1.(['d' num2str(dat_level)]).is_au = is_au;
            epo_all2.(['d' num2str(dat_level)]).is_au = is_au;
            epo_all12.(['d' num2str(dat_level)]).is_au = is_au;
        end
    end
end



%% make plots
%% ------------
fset = myFigureSettings(); % input: size(1) = width, size(2) = hight
fig_size = fset.fig_size;
font_size = fset.font_size;


datlevel_name = {'eegcca' 'esgcca' 'eng'};
for ii = 1:length(data_levels)
    
    epo1 = epo_all1.(['d' num2str(data_levels(ii))]);
    epo2 = epo_all2.(['d' num2str(data_levels(ii))]);
    epo12 = epo_all12.(['d' num2str(data_levels(ii))]);
    
    % find included subjects
    included_subjects = get_includedSubjects(savepath_ga, nerve, ii, subjects);
    
    for ichan = 1:size(epo1.data,1)
        % ==================== FIGURE SETTINGS ========================
        figure;
        set(gcf, 'units', 'centimeters', 'position', [1 1 fig_size(1) fig_size(2)])


        % ==================== COLOR SETTINGS ========================
        color_code = {fset.digits1 fset.digits2 fset.digits12};
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

        
        %% D1
        % calculate mean and sem
        grndAvg = nanmean(epo1.data(ichan, :, included_subjects), 3);
        if length(subjects) > 1
            grndSem = nanstd(epo1.data(ichan, :, included_subjects), [], 3) / sqrt(size(epo1.data, 3));            
        else
            grndSem = nanstd(epo1.data(ichan, :, included_subjects), [], 3);
        end
        error_band = fill([epo1.times fliplr(epo1.times)], [grndAvg-grndSem fliplr(grndAvg+grndSem)], ...
            color_code{1}, 'LineStyle','none');
        % plot
        set(error_band, 'facealpha', face_alpha);
        h(1) = plot( epo1.times, grndAvg, 'Color', color_code{1}, 'linewidth', line_width );
        clear grndAV grndSem
        legend_name{1} = 'd1';
        
        %% D2
        % calculate mean and sem
        grndAvg = nanmean(epo2.data(ichan, :, included_subjects), 3);
        if length(subjects) > 1
            grndSem = nanstd(epo2.data(ichan, :, included_subjects), [], 3) / sqrt(size(epo2.data, 3));
        else
            grndSem = nanstd(epo2.data(ichan, :, included_subjects), [], 3);
        end
        error_band = fill([epo2.times fliplr(epo2.times)], [grndAvg-grndSem fliplr(grndAvg+grndSem)], ...
            color_code{2}, 'LineStyle','none');
        % plot
        set(error_band, 'facealpha', face_alpha);
        h(2) = plot( epo2.times, grndAvg, 'Color', color_code{2}, 'linewidth', line_width );
        clear grndAV grndSem
        legend_name{2} = 'd2';
        
        %% D12
        % calculate mean and sem
        grndAvg = nanmean(epo12.data(ichan, :, included_subjects), 3);
        if length(subjects) > 1
            grndSem = nanstd(epo12.data(ichan, :, included_subjects), [], 3) / sqrt(size(epo12.data, 3));
        else
            grndSem = nanstd(epo12.data(ichan, :, included_subjects), [], 3);
        end
        error_band = fill([epo12.times fliplr(epo12.times)], [grndAvg-grndSem fliplr(grndAvg+grndSem)], ...
            color_code{3}, 'LineStyle','none');
        % plot
        set(error_band, 'facealpha', face_alpha);
        h(3) = plot( epo12.times, grndAvg, 'Color', color_code{3}, 'linewidth', line_width );
        clear grndAV grndSem
        legend_name{3} = 'd12';

        legend1 = legend (h([1 2 3]), legend_name);
        set(legend1,...
            'Position',[0.15 0.83 0.07 0.06]);
        set(gcf, 'color', [1 1 1]); box off;
        xlim(x_lim)
        set(gca, 'Xtick', xtickpoints)
        xlabel('Time [ms]')
        set(gca, 'XTickLabel', xticklabels)

        ylim('auto') %ylim(y_lim)%ylim('auto')
        %set(gca, 'Ytick', y_lim(1):2:y_lim(2))
        if ~epo1.is_au
            ylabel(['[' char(181) 'V]'])
        else
            ylabel('[a.u.]')
        end
        grid on
        title (['N = ' num2str(length(included_subjects))])

        %% save
        if length(subjects) > 1
            fname = ['sep_digits_' cond_name '_' datlevel_name{ii} '_grndAvg'];
        else
            fname = ['sep_digits_' cond_name '_' datlevel_name{ii} sprintf('_sub-%03i', subjects)];
        end
        %print([getenv('FIGUREPATH') fname], '-dpng', '-painters') 
        %print([getenv('FIGUREPATH') fname], '-dsvg', '-painters')  

        %% convert to excel
        %% ------------
        % columns: counter, time, subjects d1, subjects d2, subjects d12
        excel_fname = [getenv('FIGUREPATH') 'Figure_06.xlsx'];
        sheet_name = 'attenuation_';

        all_conditions = {'_d1' '_d2' '_d12'};
        
        all_times = epo1.times;
        all_data1 = squeeze(epo1.data(ichan, :, included_subjects));
        all_data2 = squeeze(epo2.data(ichan, :, included_subjects));
        all_data12 = squeeze(epo12.data(ichan, :, included_subjects));
        
        counter = 0:length(all_times)-1;
        col_header1 = [];col_header2 = [];col_header12 = [];
        sub_counter = 0;
        for isub = included_subjects
            sub_counter = sub_counter + 1;
            col_header1{sub_counter} = [sprintf('sub-%03i', isub) all_conditions{1}];
            col_header2{sub_counter} = [sprintf('sub-%03i', isub) all_conditions{2}];
            col_header12{sub_counter} = [sprintf('sub-%03i', isub) all_conditions{3}];
        end
        
        table1 = array2table(counter');
        table1.('time') = all_times';
        table2 = array2table(all_data1, 'VariableNames', col_header1');
        table3 = array2table(all_data2, 'VariableNames', col_header2');
        table4 = array2table(all_data12, 'VariableNames', col_header12');
        table = [table1,table2,table3,table4];
        writetable(table, excel_fname, 'Sheet', sprintf('%s', [cond_name '_' sheet_name datlevel_name{ii}]))

    end
    
end

end


function idx_included = get_includedSubjects(savepath_ga,nerve, chan_idx, subjects)

% load data
load([savepath_ga 'data4stats.mat'], 'wide')
% set variables
stimType = 1; % sensory nerve stimulation
if nerve == 1
    title_names = {'EEG' 'cervical CCA' 'upper arm'};
    target_chans = {'eeg_cca' 'esg_cca' 'Biceps'};
elseif nerve == 2
    title_names = {'EEG' 'lumbar CCA' 'pop fossa'};
    target_chans = {'eeg_cca' 'esg_cca' 'Knee'};
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

% remove subjects with NaN in one of the three conditions
column_idx = chan_idx + 1;
logical_included = ones(1, length(subjects));
idx1 = find(isnan(d1(:, column_idx)));
idx2 = find(isnan(d2(:, column_idx)));
idx12 = find(isnan(d12(:, column_idx)));
idx = unique([idx1' idx2' idx12']);
logical_included(idx) = 0;
idx_included = find(logical_included);

end

