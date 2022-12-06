% Author: Birgit Nierula
% nierula@cbs.mpg.de

function esg_prepro_loop4_check(subject, condition, iblock, srmr_nr)

subject_id = sprintf('sub-%03i', subject);
analysis_path = [getenv('ANADIR') subject_id '/esg/prepro/'];
save_path = [getenv('ESGDIR') subject_id '/'];

load([save_path 'artifacts.mat'], 'bad_channels')
if isempty(bad_channels)
    clear bad_channels
end
    
% get condition info
[cond_info] = get_conditionInfo(condition, srmr_nr);
cond_name = cond_info.cond_name;
trigger_name = cond_info.trigger_name;
nblocks = cond_info.nblocks;

%% load data
load_path = [analysis_path 'ecgclean_' cond_name '/'];
fname = ['cnt_clean_ecg_spinal_' cond_name '.set'];
cnt = pop_loadset( 'filename', fname, 'filepath', load_path );

%% select ESG channels
[~, esg_chans, ~] = get_channels(subject, false, false, srmr_nr); % excluding ECG and excluding EOG channels
chan_idx = find(ismember({cnt.chanlocs.labels}, esg_chans));
cnt = pop_select(cnt, 'channel', chan_idx);
    
%% separate blocks
idx = find(ismember({cnt.event.type}, 'boundary'));
block_idx = [cnt.event(idx).latency];
if length(block_idx) == nblocks-1

    idx_start = round([1 block_idx+1]);
    idx_end = round([block_idx cnt.pnts]);
    cnt1 = pop_select(cnt, 'point', idx_start(iblock) : idx_end(iblock));
    
    %% filter for artifact detection
    % lowpass at 30 Hz
    cnt_filt = cnt1;
    [a,b] = butter(2, 30/(cnt1.srate/2), 'high'); % removes most leftovers from heart artifact when lower bound set to 30 Hz
    cnt_filt.data = filtfilt(a, b, double(cnt1.data)')';
    
    %% identify bad channels
    % 1) using the spectrum
    [~, cervical_chans, lumbar_chans, ~] = get_esg_channels();
    cervical_idx = find(ismember({cnt.chanlocs.labels}, cervical_chans));
    lumbar_idx = find(ismember({cnt.chanlocs.labels}, lumbar_chans));
    
    figure('units','normalized','outerposition',[0 0 1 1]);
    cervical_cnt = pop_select(cnt_filt, 'channel', cervical_idx);
    pop_spectopo(cervical_cnt, 1, [], 'EEG' , 'percent', 100, 'freqrange',[1 500],'electrodes','off'); % spectrogram
    title([subject_id ' cervical channels ' cond_name ' block' num2str(iblock)])
    
    check_channel = input('check_channel = ');
    while ~isempty(check_channel)
        chan_idx = find((1:cervical_cnt.nbchan == check_channel) == 0);
        figure; plot(cervical_cnt.times, cervical_cnt.data(chan_idx,:), 'k')
        hold on
        plot(cervical_cnt.times, cervical_cnt.data(check_channel, :), 'r')
        title([subject_id ' cervical channels + ' cervical_cnt.chanlocs(check_channel).labels...
            ' ' subject_id ' ' cond_name ' block' num2str(iblock)])
        check_channel = input('check_channel = ');
    end
    
    figure('units','normalized','outerposition',[0 0 1 1]);
    lumbar_cnt = pop_select(cnt_filt, 'channel', lumbar_idx);
    pop_spectopo(lumbar_cnt, 1, [], 'EEG' , 'percent', 100, 'freqrange',[1 500],'electrodes','off'); % spectrogram
    title([subject_id 'lumbar channels'])
    suptitle([subject_id ' ' cond_name])
    
    check_channel = input('check_channel = ');
    while ~isempty(check_channel)
        chan_idx = (1:lumbar_cnt.nbchan == check_channel) == 0;
        figure; plot(lumbar_cnt.times, lumbar_cnt.data(chan_idx,:), 'k')
        hold on
        plot(lumbar_cnt.times, lumbar_cnt.data(check_channel, :), 'r')
        title([subject_id ' lumbar channels + ' lumbar_cnt.chanlocs(check_channel).labels...
            ' ' subject_id ' ' cond_name ' block' num2str(iblock)])
        check_channel = input('check_channel = ');
    end
    
    % 2) using log-MS (--> less sensitive to outliers)
    wait4input = true; % do not wait for user input!
    bad_channels1 = prepro_check4badChannels(cnt_filt, trigger_name, wait4input, []);
    title([subject_id ' - LMS - ' cond_name ' block' num2str(iblock)])
    
    % 3) using RMS (--> more sensitive to outliers)
    wait4input = true; % do not wait for user input!
    bad_channels2 = prepro_esg_check4badChannels(cnt_filt, trigger_name, wait4input);
    title([subject_id ' - RMS - ' cond_name])
    
    if ~isempty(bad_channels1) 
        if ~isempty(bad_channels2)
            chans = {bad_channels1{:} bad_channels2{:}};
        else
            chans = bad_channels1;
        end
    elseif ~isempty(bad_channels2) 
        chans = bad_channels2;
    else
        chans = [];
    end
    
    if ~isempty(chans)
        idx = find(ismember({cnt_filt.chanlocs.labels}, chans));
        idx = unique(idx);
        eval(['bad_channels.' cond_name '.block' num2str(iblock) ' = {cnt_filt.chanlocs(idx).labels};'])
    else
        eval(['bad_channels.' cond_name '.block' num2str(iblock) ' = [];'])
    end
    
end

%% save excluded channels
save([save_path 'artifacts.mat'], 'bad_channels', '-append')
    










