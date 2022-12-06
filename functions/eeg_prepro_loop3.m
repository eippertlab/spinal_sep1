% Author: Birgit Nierula
% nierula@cbs.mpg.de

function eeg_prepro_loop3(subject, condition, srmr_nr)

%% loop 3: remove identified bad channels and interpolate them

% set important variables
subject_id = sprintf('sub-%03i', subject);
analysis_path = [getenv('ANADIR') subject_id '/eeg/prepro/'];


% define stimulation conditions
[cond_info] = get_conditionInfo(condition, srmr_nr);
nblocks = cond_info.nblocks;
cond_name = cond_info.cond_name;


% load previous preprocessing step and merge blocks
for iblock = 1:nblocks
    load([analysis_path cond_name '_' num2str(iblock) '_artifacts.mat'], 'bad_channels')
    
    if ~isempty(bad_channels)
        % load eeg data
        load([getenv('CFGDIR') 'cfg.mat'], 'srate_ica')
        cnt = pop_loadset('filename', ['noStimart_sr' num2str(srate_ica) '_' cond_name '_' num2str(iblock) '.set'] , 'filepath', analysis_path);
        
        
        % remove bad channels
        [~, idx] = ismember({cnt.chanlocs.labels}, bad_channels );
        chan_idx = find(idx == 0);
        cnt1 = pop_select(cnt, 'channel', chan_idx); clear chan_idx idx
        cnt1 = eeg_checkset(cnt1);
        
        
        % interpolate removed channels
        cnt = pop_interp(cnt1, cnt.chanlocs, 'spherical');
        
        
        % save this processing step
        cnt = pop_saveset(cnt, 'filename', ['noStimart_sr' num2str(srate_ica) '_' cond_name '_' num2str(iblock) '_chansRemoved.set'] , 'filepath', analysis_path); % removed channels
    else
        % don´t save a new file
    end
end