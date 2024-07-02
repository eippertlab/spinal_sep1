% Author: Birgit Nierula
% nierula@cbs.mpg.de

function esg_prepro_loop3(subject, conditions, srmr_nr)

%% set variables
subject_id = sprintf('sub-%03i', subject);
analysis_path = [getenv('ANADIR') subject_id '/esg/prepro/'];
save_path = [getenv('ESGDIR') subject_id '/'];
if ~exist(save_path, 'dir'), mkdir(save_path); end

condition_counter = 0;
for condition = conditions
    condition_counter = condition_counter + 1;
    
    % get condition info
    [cond_info] = get_conditionInfo(condition, srmr_nr);
    cond_name = cond_info.cond_name;
    trigger_name = cond_info.trigger_name;


    %% load data
    load_path = [analysis_path 'ecgclean_' cond_name '/'];
    fname = ['cnt_clean_ecg_spinal_' cond_name '.set'];
    cnt = pop_loadset( 'filename', fname, 'filepath', load_path );


    %% select ESG channels
    [~, esg_chans, ~] = get_channels(subject, false, false, srmr_nr); % excluding ECG and excluding EOG channels
    chan_idx = find(ismember({cnt.chanlocs.labels}, esg_chans));
    cnt = pop_select(cnt, 'channel', chan_idx);

    %% merge data sets
    if condition_counter == 1
        cnt_all = cnt;
        trigger_all = trigger_name;
    else
        cnt_all = pop_mergeset(cnt_all, cnt);
        trigger_all = [trigger_all trigger_name];
    end
    clear cnt
end
cnt = cnt_all; clear cnt_all
trigger_name = trigger_all; clear trigger_all


%% filter for artifact detection
% highpass at 30 Hz
cnt_filt = cnt;
[a,b] = butter(2, 30/(cnt.srate/2), 'high'); % removes most leftovers from heart artifact when lower bound set to 30 Hz
cnt_filt.data = filtfilt(a, b, double(cnt.data)')';


%% identify bad channels
% 1) using the spectrum
[~, cervical_chans, lumbar_chans, ~] = get_esg_channels();
cervical_idx = find(ismember({cnt.chanlocs.labels}, cervical_chans));
lumbar_idx = find(ismember({cnt.chanlocs.labels}, lumbar_chans));
h = figure('units','normalized','outerposition',[0 0 1 1]);
subplot(1,2,1)
cervical_cnt = pop_select(cnt, 'channel', cervical_idx);
pop_spectopo(cervical_cnt, 1, [], 'EEG' , 'percent', 100, 'freqrange',[1 500],'electrodes','off'); % spectrogram
title('cervical channels')
subplot(1,2,2)
lumbar_cnt = pop_select(cnt, 'channel', lumbar_idx);
pop_spectopo(lumbar_cnt, 1, [], 'EEG' , 'percent', 100, 'freqrange',[1 500],'electrodes','off'); % spectrogram
title('lumbar channels')
suptitle([subject_id ' all conditions'])
% save plots of all subjects
export_fig([getenv('ANADIR') 'Channel_inspection_powerSpectrum.pdf'], '-pdf', '-append', h)
close

% 2) using log-MS (--> less sensitive to outliers)
wait4input = false; % do not wait for user input!
bad_channels = prepro_check4badChannels(cnt_filt, trigger_name, wait4input, []);
title([subject_id ' - LMS -  all conditions'])
% save plots for all subjects
export_fig([getenv('ANADIR') 'Channel_inspection_check4badChannels.pdf'], '-pdf', '-append')
close

% 3) using RMS (--> more sensitive to outliers)
wait4input = false; % do not wait for user input!
bad_channels = prepro_esg_check4badChannels(cnt_filt, trigger_name, wait4input);
title([subject_id ' - RMS -  all conditions'])

% save plots for all subjects
page_name = '02_channel_inspection';
page_path = getenv('ZIMDIR');
page_title = [];
if ~exist([page_path page_name '.txt'], 'file')
    zim_newpage(page_path, page_name, page_title)
end
figure_path = [page_path page_name '/'];
if ~exist(figure_path, 'dir')
    mkdir(figure_path)
end
export_fig([figure_path 'Channel_inspection_check4badChannels.pdf'], '-pdf', '-append')
close


% save empty variable for bad channels
% (will be later changed for those subjects where channels are removed)
save([save_path 'artifacts.mat'], 'bad_channels')

