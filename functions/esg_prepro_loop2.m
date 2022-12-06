% Author: Birgit Nierula
% nierula@cbs.mpg.de

function esg_prepro_loop2(subject, condition, srmr_nr, sampling_rate)


% set variables
subject_id = sprintf('sub-%03i', subject);
analysis_path = [getenv('ANADIR') subject_id '/esg/prepro/'];

if ~isfolder(analysis_path)
    mkdir(analysis_path);
end


% get condition info
[cond_info] = get_conditionInfo(condition, srmr_nr);
cond_name = cond_info.cond_name;

save_path = [analysis_path 'ecgclean_' cond_name '/'];
if ~exist(save_path, 'dir'), mkdir(save_path); end
figure_path = save_path;
save_name = [save_path 'pca_chan_'];

% load files
[~, esg_chans, ~] = get_channels(subject, false, false, srmr_nr); % excluding ECG and excluding EOG channels


% loda data
fname = ['raw_' num2str(sampling_rate) '_spinal_' cond_name];
cnt = pop_loadset('filename', [fname '.set'], 'filepath', analysis_path);
load([analysis_path fname '.mat'], 'QRSevents', 'fwts');


% keep only ECG channels
esg_idx = find(ismember({cnt.chanlocs.labels}, esg_chans));
cnt = pop_select(cnt, 'channel', esg_idx);
cnt = eeg_checkset(cnt);


% clean data channel by channel
data = cell(1, length(esg_idx));
parfor chan = 1:size(esg_chans, 2)
%     disp([cond_name ' ' num2str(chan)])

    % select channel
    cnt1 = pop_select(cnt, 'channel', chan); 
    cnt1.data = double(cnt1.data);
    
    % set fmrib input variables
    method = 'obs';
    channelNames = {'Iz' 'SC1' 'S3' 'SC6' 'S20' 'L1' 'L4'}; %these channels will be plottet (only for debugging/testing)

    % run fmrib
    cnt1 = myfmrib_pas_parallel(cnt1, QRSevents, method, fwts, ...
        [save_name num2str(chan) '.mat'], channelNames, subject_id, figure_path, []); % adapted for data: delay of r-peak = 0 %(data, eventtype, method)

    data{chan} = cnt1.data;
end


% create eeglab structure
cnt_new = cnt;
cnt_new.data = [];
for chan = 1:cnt.nbchan
    cnt_new.data(chan, :) = data{chan};
end
cnt_new = eeg_checkset(cnt_new);
    
    
% save files
fname_new = ['cnt_clean_ecg_spinal_' cond_name '.set'];
cnt_new = pop_saveset(cnt_new, 'filename', fname_new, 'filepath', save_path);


% delete old files 
delete_files = dir([analysis_path fname '*']);
for ii = 1:size(delete_files, 1)
    delete([analysis_path delete_files(ii).name]);
end
