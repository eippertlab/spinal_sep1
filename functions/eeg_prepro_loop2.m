% Author: Birgit Nierula
% nierula@cbs.mpg.de

function eeg_prepro_loop2(subj_inspect, subject, condition, block, srmr_nr, make_plot)

%% loop 2: "manually" look at datasets that showed noisy spectra 
%% (not necessarily bad channels), mark and reject bad channels if needed  

% define path and subject id
subject_id = sprintf('sub-%03i', subject);
analysis_path = [getenv('ANADIR') subject_id '/eeg/prepro/'];
save_path = [getenv('EEGDIR') subject_id '/'];


% get condition info
[cond_info] = get_conditionInfo(condition, srmr_nr);
trigger_name = cond_info.trigger_name;
cond_name = cond_info.cond_name;
block_number = num2str(block);


% check if bad channels were visually detected in this subject
block_idx = [];
subj_idx = find(ismember({subj_inspect{:, 1}}, sprintf('sub-%03i', subject)));
if ~isempty(subj_idx)
    tmp_idx = find(ismember({subj_inspect{subj_idx, 2}}, cond_name));
    cond_idx = subj_idx(tmp_idx); clear tmp_idx
    if ~isempty(cond_idx)
        tmp_idx = find(ismember({subj_inspect{cond_idx, 3}}, block_number));
        block_idx = cond_idx(tmp_idx); clear tmp_idx
    end
end


% load previous preprocessing step
load([getenv('CFGDIR') 'cfg.mat'], 'srate_ica')
cnt = pop_loadset('filename', ['noStimart_sr' num2str(srate_ica) '_' cond_name '_' block_number '.set'] , 'filepath', analysis_path);


% exclude ECG and EOG channels
idx = find(ismember({cnt.chanlocs.labels}, {'ECG' 'EOGH' 'EOGV'}));
cnt = pop_select(cnt, 'nochannel', idx);


% automatically check for bad channels
cnt1 = cnt;
cnt1 = clean_rawdata(cnt1, 5, 'off', 0.85, 'off', -1, 'off');
tmp = ismember({cnt.chanlocs.labels}, {cnt1.chanlocs.labels});
auto_badchan = find(tmp == 0);

disp('##################')
disp([subject_id ', ' cond_name ', block ' block_number])
disp(['auto rejection: ' num2str(length(auto_badchan)) ' channels'])
if ~isempty(auto_badchan)
    for ii = 1:length(auto_badchan); disp(cnt.chanlocs(auto_badchan(ii)).labels); end
end
disp('##################')

bad_channels = [];

% inspect channels
if ~isempty(auto_badchan) || ~isempty(block_idx)

    if ~isempty(auto_badchan)
        disp('#### 1) check channels from automatic step')
        vis_artifacts(cnt1, cnt)
        input('press ENTER to continue \n')
    end


    % plot spectrum of each channel
    disp('#### 2) check spectrum of all channels')
    h = figure; pop_spectopo(cnt, 1, [], 'EEG' , 'percent', 100, 'freqrange',[1 100],'electrodes','off'); % spectrogram
    title([subject_id ' ' cond_name])
    % export_fig([getenv('ANADIR'), 'Bad_Channel_inspection_separately.pdf'], '-pdf','-append')
    input('press enter to continue \n')
    

    % Plot Channels to check how they look like
    if make_plot
        chan_idx = input('enter index of channel to check OR 0 for nothing! \n chan_idx = ');
        while chan_idx ~= 0
            figure; hold on
            plot(cnt.times, cnt.data(chan_idx, :))
            ylim([-500 500])
            title([subject_id '_' cond_name ' ' block_number 'channel ' cnt.chanlocs(chan_idx).labels])
            hold off
    %         export_fig([getenv('ANADIR'), 'Bad_Channel_inspection_separately.pdf'], '-pdf','-append')
            chan_idx = input('enter index of channel to check OR 0 for nothing! \n chan_idx = ');
        end
    end


    % plot log root mean square (RMS) of each epch in each channel
    disp('#### 3) check activity in each epoch for all channels')
    wait4input = true;
    bad_channels = prepro_check4badChannels(cnt, trigger_name, wait4input, {cnt.chanlocs(auto_badchan).labels});
end

% save excluded channels
save([analysis_path cond_name '_' block_number '_artifacts.mat'], 'bad_channels', '-append')
save([save_path cond_name '_' block_number '_artifacts.mat'], 'bad_channels', '-append')
clear bad_channels
close all