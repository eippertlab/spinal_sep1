% Author: Birgit Nierula
% nierula@cbs.mpg.de

function figure_spinal_isopotentialplot(dat, subjects, condition, srmr_nr, is_au)


% get info
[cond_info] = get_conditionInfo(condition, srmr_nr);
cond_name = cond_info.cond_name;
[~, esg_chans, ~] = get_channels(15, false, false, srmr_nr);


%% merge data
all_chanvalues = NaN(length(subjects), size(esg_chans,2));
for isubject = 1:length(subjects)
    epo = dat{subjects(isubject)};
    pot_start = epo.potWindow(1);
    pot_end = epo.potWindow(2);
    idx1 = find(epo.times <= pot_start);
    idx2 = find(epo.times >= pot_end);
    time_idx = idx1(end) : idx2(1);
    for ichan = 1:size(esg_chans,2)
        chan_idx = find(ismember({epo.chanlocs.labels}, esg_chans{ichan}));
        if ~isempty(chan_idx)
            all_chanvalues(isubject, ichan) = mean(mean(epo.data(chan_idx,time_idx,:), 3), 2);
        end
    end
end
chanvalues = nanmean(all_chanvalues,1);

%% make plots
%% ------------
fset = myFigureSettings(); % input: size(1) = width, size(2) = hight
fig_size = fset.fig_size; 
font_size = fset.font_size;


fig_size(2) = fig_size(2) * 2; % double hight

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
    colorbar_axes = [-1 1];
    title_str = [cond_name ' single subj'];
end
mrmr_esg_isopotentialplot(subjects, chanvalues, colorbar_axes, esg_chans)

h1 = colorbar;
if ~is_au
    ylabel(h1, ['Magnitude [' char(181) 'V]'])
    set(h1,'fontname', font_name)
else
    ylabel(h1, 'Magnitude [a.u.]')
    set(h1,'fontname', font_name)
end

title(title_str)


if length(subjects) > 1     
    if is_au
        fname = ['esg_cca_' cond_name '_isopot_grndAvg'];
    else
        fname = ['esg_' cond_name '_isopot_grndAvg'];
    end
else
    if is_au
        fname = ['esg_cca_' cond_name sprintf('_isopot_sub-%03i_esg', subjects)];
    else
        fname = ['esg_' cond_name sprintf('_isopot_sub-%03i_esg', subjects)];
    end
end
print([getenv('FIGUREPATH') fname], '-dpng', '-painters') 
print([getenv('FIGUREPATH') fname], '-dsvg', '-painters')    
