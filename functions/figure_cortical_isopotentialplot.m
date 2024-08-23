% Author: Birgit Nierula
% nierula@cbs.mpg.de

function figure_cortical_isopotentialplot(dat, subjects, condition, srmr_nr, is_au)


% get info
[cond_info] = get_conditionInfo(condition, srmr_nr);
cond_name = cond_info.cond_name;
[eeg_chans, ~, ~] = get_channels(15, false, false, srmr_nr);


%% merge data
all_chanvalues = NaN(length(subjects), size(eeg_chans,2));
for isubject = 1:length(subjects)
    epo = dat{subjects(isubject)};
    pot_lat(isubject) = epo.potLatency(1);
    idx1 = find(epo.times >= pot_lat(isubject));
    time_idx = idx1(1);
    for ichan = 1:size(eeg_chans,2)
        chan_idx = find(ismember({epo.chanlocs.labels}, eeg_chans{ichan}));
        if ~isempty(chan_idx)
            all_chanvalues(isubject, ichan) = mean(epo.data(chan_idx, time_idx, :), 3);
        end
    end
end
chanlocs = epo.chanlocs;
chanvalues = nanmean(all_chanvalues,1);
pot_latency = mean(pot_lat);


%% make plots
%% ------------
fset = myFigureSettings(); % input: size(1) = width, size(2) = hight
fig_size = fset.fig_size; 
font_size = fset.font_size;


% ==================== FIGURE SETTINGS ========================
figure;
set(gcf, 'Units', 'centimeters', 'Position', [1 1 fig_size(1) fig_size(2)])
h = get(gcf);
h.Position = [1 1 fig_size(1) fig_size(2)];
h.PaperUnits = 'centimeter';
h.PaperOrientation = 'landscape';
h.PaperUnits = 'centimeters';
h.Units = 'centimeters';
h.PaperType = 'A0';


% ==================== COLOR SETTINGS ========================
face_alpha = 0.3;


% ==================== GRAPH SETTINGS ========================
line_width = 1;
font_name = 'Roboto';

set(gca,'linewidth',1)
set(gca,'FontSize', font_size)
set(gca,'FontName', font_name)

% ==================== PLOT FIGURE ============================
if length(subjects) > 1
    colorbar_axes = [-1 1];
    title_str = [cond_name ' grand avg'];
else
    colorbar_axes = [-2 2];
    title_str = [cond_name ' single subj'];
end

topoplot(chanvalues, chanlocs);
caxis(colorbar_axes), c = colorbar; 
c.Label.FontSize = font_size;
if is_au
    c.Label.String = ['Amplitude [a.u.]'];
else
    c.Label.String = ['Amplitude [' char(181) 'V]'];
end
title([num2str(pot_latency) ' ms'])
    
if length(subjects) > 1     
    if is_au
        fname = ['eeg_cca_' cond_name '_isopot_grndAvg'];
    else
        fname = ['eeg_' cond_name '_isopot_grndAvg'];
    end
else
    if is_au
        fname = ['eeg_cca_' cond_name sprintf('_isopot_sub-%03i_esg', subjects)];
    else
        fname = ['eeg_' cond_name sprintf('_isopot_sub-%03i_esg', subjects)];
    end
end
print([getenv('FIGUREPATH') fname], '-dpng', '-painters') 
print([getenv('FIGUREPATH') fname], '-dsvg', '-painters')   


