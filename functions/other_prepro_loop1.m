% Author: Birgit Nierula
% nierula@cbs.mpg.de

function other_prepro_loop1(subject, condition, srmr_nr, sampling_rate)

%% eng preprocessing

%% set variables
subject_id = sprintf('sub-%03i', subject);
analysis_path = [getenv('OTHERDIR') subject_id '/other/prepro/']; 
if ~exist(analysis_path,'dir'); mkdir(analysis_path); end
raw_path = [getenv('RAWDIR') subject_id '/eeg/'];
cfg_path = getenv('CFGDIR');

% get condition info
[cond_info] = get_conditionInfo(condition, srmr_nr);
cond_name = cond_info.cond_name;
trigger_name = cond_info.trigger_name;
stimulation = cond_info.stimulation;
cond_name2 = cond_info.cond_name2;
nerve = cond_info.nerve;


%% load raw data
file = dir([raw_path subject_id '_task-' cond_name2 '_run-*_eeg.set']);
for iblock = 1:length(file)
    
    % load data
    cnt1 = pop_loadset('filename', file(iblock).name , 'filepath', raw_path);
    
    
    %% select ENG channels
    if nerve == 1
        eng_chans = {'EP' 'Biceps'} ;
    elseif nerve == 2
        eng_chans = {'KneeM' 'Knee1' 'Knee2' 'Knee3' 'Knee4'} ;
    end
    idx_eng = find(ismember({cnt1.chanlocs.labels}, eng_chans));
    cnt1_eng = pop_select(cnt1, 'channel', idx_eng);

    
            
    %% remove stimulus artifact
    if stimulation ~= 0
        % interpolate stimulus artefact
        if nerve == 1
            interpol_window = [-3 4];
        elseif nerve == 2
            interpol_window = [-3 6];
        end
        cnt1_eng = prepro_removeStimArtefact(cnt1_eng, trigger_name, interpol_window, 1:size({cnt1_eng.chanlocs.labels}, 2), 1); 
        close
        close
    end 
    
    %% downsample 
    cnt1_eng = pop_resample( cnt1_eng, sampling_rate);
    cnt1_eng = eeg_checkset(cnt1_eng);
    
    
    %% merge data sets
    if iblock == 1
        cnt_eng = cnt1_eng;
    else
        cnt_eng = pop_mergeset(cnt_eng, cnt1_eng);
    end
    
    clear cnt1*
end



%% filtering
if srmr_nr == 1
    load([cfg_path 'cfg.mat'], 'other_hp_freq', 'notch_freq')

    % bandpass + notch filter for eng
    [b_band, a_band] = butter(2, other_hp_freq/(cnt_eng.srate/2));
    % notch filter
    [b_notch, a_notch] = butter(2, notch_freq/(cnt_eng.srate/2),'stop');
       
elseif srmr_nr == 2
    load([cfg_path 'cfg.mat'], 'other_hp_freq')
    % comb filter
    fo = 50;
    q = 35;
    bw = (fo/(cnt_eng.srate/2))/q;
    [b_notch, a_notch] = iircomb(cnt_eng.srate/fo, bw, 'notch');
    % bandpass filter
    [b_band, a_band] = butter(2, other_hp_freq/(cnt_eng.srate/2));
        
end
% filter data (zero phase filtering)
a_all = poly([roots(a_band); roots(a_notch)]);
b_all = conv(b_band, b_notch);
cnt_eng.data = filtfilt(b_all, a_all, double(cnt_eng.data)')';



%% make epochs
load([cfg_path 'cfg.mat'], 'iv_epoch', 'iv_baseline')
iv_epoch = iv_epoch/1000;

% epoch data
epo_eng = pop_epoch( cnt_eng, trigger_name, iv_epoch, 'newname', 'NEP Epochs', 'epochinfo', 'yes' );

% remove baseline
epo_eng = pop_rmbase( epo_eng, iv_baseline );

% check data set
epo_eng = eeg_checkset( epo_eng );


%% save data
fname = ['eng_filt_' cond_name '.set'];
pop_saveset(epo_eng, 'filename', fname, 'filepath', analysis_path);
