% Author: Birgit Nierula
% nierula@cbs.mpg.de

function  [EEGorig, EEG, cfg] = eeg_prepro_loop7_1_allBlocks(subject, veog_channames, heog_channames)

%% loop 7: check ICA components with SASICA

% define variables
subject_id = sprintf('sub-%03i', subject);
analysis_path = [getenv('ANADIR') subject_id '/eeg/prepro/'];


load([getenv('CFGDIR') 'cfg.mat'], 'srate_ica')

    
% ica info
fname = ['allConditions_sr' num2str(srate_ica) 'Hz_ICA.set'];
EEG = pop_loadset('filename', fname, 'filepath', analysis_path);


% find channel indexes
idx_veog = find(ismember({EEG.chanlocs.labels}, veog_channames));
idx_heog = find(ismember({EEG.chanlocs.labels}, heog_channames));
idx_ecg = find(ismember({EEG.chanlocs.labels}, 'ECG'));


% since data was down-sampled: find more exact R-peaks
debug_mode = true;
EEG = find_exactRpeaks(EEG, 'qrs', 'ECG', debug_mode);

EEGorig = EEG;

% epoch data to R-peak
epo_window = [-100 1000]/1000; %epoching time window
EEG = pop_epoch(EEG, {'qrs'}, epo_window);
close all


% SASCIA configuration
cfg.opts.noplot = 0;
cfg.opts.nocompute = 0;
cfg.autocorr.enable = true;
cfg.autocorr.dropautocorr = 'auto'; % default is 2SD: 'auto'
cfg.autocorr.autocorrint = 20;% will compute autocorrelation with this many milliseconds lag
cfg.focalcomp.enable = true;
cfg.focalcomp.focalICAout = 'auto 1.5'; % using default, which is 2SD
cfg.trialfoc.enable = false;
cfg.trialfoc.focaltrialout = 'auto'; % using default which is 2SD
cfg.resvar.enable = false;
cfg.resvar.thresh = 40 ; %residual variance allowed, default is 15%
cfg.SNR.enable = false;

cfg.EOGcorr.enable = true;
cfg.EOGcorr.corthreshV ='auto 4';% threshold correlation with vertical EOG, default would be 4 SD from average correlation: 'auto 4'
cfg.EOGcorr.Veogchannames = idx_veog;% vertical channel(s), VEOG Fp1
cfg.EOGcorr.corthreshH ='auto 4';% threshold correlation with horizontal EOG
cfg.EOGcorr.Heogchannames = idx_heog;% horizantal channel(s) f7 f8
cfg.chancorr.enable =true;
cfg.chancorr.channames = 'ECG';
cfg.chancorr.corthresh='auto 1';

cfg.FASTER.enable = false; % default thresh is 3 SDs from average for each measure
cfg.FASTER.blinkchans = [];
cfg.ADJUST.enable = false; % combines different features for detection (SAD,SVD,TK
cfg.MARA.enable = false;


% plot ecg channel for comparison
figure; hold on
plot(EEG.times, mean(EEG.data(idx_ecg,:,:), 3));
xline(0)
title('ECG channel'); xlabel('time [ms]'); ylabel('amplitude [\muV]')
hold off

