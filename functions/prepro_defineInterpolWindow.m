% Author: Birgit Nierula (May, 2020)
% nierula@cbs.mpg.de

function [out] = prepro_defineInterpolWindow(subject, srmr_nr, bids_dir)

%% loop 1: downsample for ica and channel inspection (make plots for all subjects and conditions)

% set variables
subject_id = sprintf('sub-%03i', subject);
if srmr_nr == 1
    raw_path = [bids_dir subject_id '/eeg/'];
elseif srmr_nr == 2
end

trigger_name = {'Median - Stimulation' 'Tibial - Stimulation' 'med_mixed'...
    'tib_mixed' 'med1' 'med2' 'med12' 'tib1' 'tib2' 'tib12'};


% get file names
cond_files = dir([raw_path '*.set']);

for iblock = 1:length(cond_files)
    
    clearvars cnt 
    
    % load data
    cnt = pop_loadset('filename', cond_files(iblock).name , 'filepath', raw_path);
    % change event latencies to matlab convention
    if ~isempty(cnt.event)
        for ievent = 1:size(cnt.event, 2)
            cnt.event(ievent).latency = cnt.event(ievent).latency + 1;
        end
    end
    
    % select ESG channels
    [brainstem_chans, cervical_chans, lumbar_chans, ref_chan] = get_esg_channels();
    idx_cervical = find(ismember({cnt.chanlocs.labels}, [brainstem_chans cervical_chans]));
    tmp_c = pop_select(cnt, 'channel', idx_cervical); 
    idx_lumbar = find(ismember({cnt.chanlocs.labels}, [lumbar_chans]));
    tmp_l = pop_select(cnt, 'channel', idx_lumbar); 
    
    % merge blocks
    if iblock == 1
        cnt_c = tmp_c;
        cnt_l = tmp_l;
    else
        cnt_c = pop_mergeset(cnt_c, tmp_c);
        cnt_l = pop_mergeset(cnt_l, tmp_l);
    end
end
 
% make epochs
epo_c = pop_epoch(cnt_c, trigger_name, [-100 100]/1000);
epo_l = pop_epoch(cnt_l, trigger_name, [-100 100]/1000);
epo_c = pop_rmbase(epo_c, [-100 -10]);
epo_l = pop_rmbase(epo_l, [-100 -10]);

% plot stimulation artifact
[c_start, c_end] = get_window(epo_c, 'cervical');
[l_start, l_end] = get_window(epo_l, 'lumbar');

out = [subject c_start c_end l_start l_end];
end

function [c_start, c_end] = get_window(epo_c, channel_level)
close all
figure(1)
plot(epo_c.times, mean(mean(epo_c.data, 3), 1));
xlim([-15 15])
xlabel('[ms]')
ylabel(['[' char(181) 'V]'])
title(channel_level)
c_start = input(['enter start ' channel_level ' interpolation window:  ']);
c_end = input('enter end cervical interpolation window:  ');

cin = input(['Is the ' channel_level ' interpol window = '...
    num2str(c_start) ' - ' num2str(c_end) ' correct? 0=NO, enter=YES  ']);
while ~isempty(cin)
    c_start = input(['enter start ' channel_level ' interpolation window:  ']);
    c_end = input(['enter end ' channel_level ' interpolation window:  ']);

    cin = input(['Is the ' channel_level ' interpol window = '...
        num2str(c_start) ' - ' num2str(c_end) ' correct? 0=NO, enter=YES  ']);
end

end  