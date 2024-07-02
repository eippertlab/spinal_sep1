% Author: Birgit Nierula (Feb, 2020)
% nierula@cbs.mpg.de

%% cfg definition
% this file defines important analysis parameters.

% sampling rate
srate_ica = 250;
srate_rpeak = 5000;

% interpolation window - just for R-peak detection!!
interpol_window_rpeak = [-1.5 1.5];

% eeg interpolation window
interpol_window = [-1.5 4]; % same window Tilman used

% filtering
bp_ica = [0.5 45];
notch_freq = [48 52];
esg_bp_freq = [30 400];
% other_hp_freq = [10 400]; % eng and emg
esg_bp_late = [5 400]; % filter for late potentials

% included subjects
subjects = 1:36;

% epochs
iv_epoch = [-200 700]; % in ms
iv_baseline = [-110 -10]; %in ms

save_dir = [getenv('EXPDIR') 'analysis/manuscript_sep/scripts/cfg_srmr1/'];                	

save([save_dir 'cfg.mat'], ...
    'srate_ica', ...
    'srate_rpeak', ...
    'interpol_window_rpeak', ... 
    'interpol_window', ...
    'bp_ica', ...
    'notch_freq', ...
    'esg_bp_freq', ...
    'subjects', ...
    'iv_epoch', ...
    'iv_baseline', ... %     'other_hp_freq', ...
    'esg_bp_late')
