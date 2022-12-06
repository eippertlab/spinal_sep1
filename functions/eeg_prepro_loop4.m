% Author: Birgit Nierula
% nierula@cbs.mpg.de

function eeg_prepro_loop4(subject, condition, srmr_nr)

%% loop 4: further automatic processing: re-reference, filter, artifact rejection

subject_id = sprintf('sub-%03i', subject);
analysis_path = [getenv('ANADIR') subject_id '/eeg/prepro/'];


% define stimulation conditions
[cond_info] = get_conditionInfo(condition, srmr_nr);
nblocks = cond_info.nblocks;
cond_name = cond_info.cond_name;
nerve = cond_info.nerve;
stimulation = cond_info.stimulation;
trigger_name = cond_info.trigger_name;
str_stimulation = cond_info.str_stimulation;
str_nerve = cond_info.str_nerve;


% load previous preprocessing step
load([getenv('CFGDIR') 'cfg.mat'], 'srate_ica')
for iblock = 1:nblocks
    
    % no removal of very bad epochs before ICA because it makes ICA less
    % sensitive to heart artifacts
    preICAtrim = false; % preICAtrim = set_preICAtrim(subject, cond_name, iblock, srmr_nr);
    
    % load data
    if exist([analysis_path 'noStimart_sr' num2str(srate_ica) '_' cond_name '_' num2str(iblock) '_chansRemoved.set'], 'file')
        cnt = pop_loadset('filename', ['noStimart_sr' num2str(srate_ica) '_' cond_name '_' num2str(iblock) '_chansRemoved.set'] , 'filepath', analysis_path); % load dataset without bad channels
    else
        cnt = pop_loadset('filename', ['noStimart_sr' num2str(srate_ica) '_' cond_name '_' num2str(iblock) '.set'] , 'filepath', analysis_path); % load dataset from before channel rejection
    end
    
    
    % Filter data for automatic artifact removal and for ICA
    load([getenv('CFGDIR') 'cfg.mat'], 'bp_ica')
    bp_filter = bp_ica; % [0.5 45]
    % filter
    [b, a] = butter(2, bp_filter(1)/(cnt.srate/2), 'high'); % high pass filter
    cnt.data = filtfilt(b, a, double(cnt.data)')';    % this function doubles the filter order
    [c, d] = butter(2, bp_filter(2)/(cnt.srate/2), 'low'); % low pass filter
    cnt.data = filtfilt(c, d, double(cnt.data)')';
    
       
    if preICAtrim    
        % Remove portions of the data with very large artifacts (superficial cleaning; exclude frontal channels)
        sd_thresh_lf = 15; % standard deviation threshold for frequency range 1 to 15 Hz
        amplitudeThreshold_hf = 150; % threshold for frequency range 15 to 45 Hz
        pointSpreadWidth = 300; % area around artifacts that is cut out; in ms
        chan_ex = {'Fp1', 'FPz', 'Fp2', 'ECG' 'EOGV' 'EOGH'}; % excluded channels
        [cnt_trimmed, rejectDataIntervals, badPointsInSec, badPointsPerc] = trimOutlier_superficial_cleaning(cnt, sd_thresh_lf, amplitudeThreshold_hf, pointSpreadWidth, chan_ex);
        cnt_trimmed.etc.rejectDataIntervals_beforeICA = rejectDataIntervals; % also put in EEG structure


        % save information about artifacts
        params_autoclean.sd_thresh_lf = sd_thresh_lf;
        params_autoclean.amplitudeThreshold_hf = amplitudeThreshold_hf;
        params_autoclean.pointSpreadWidth = pointSpreadWidth;
        params_autoclean.chan_ex = chan_ex;
    else
        rejectDataIntervals = [];
        badPointsInSec = [];
        badPointsPerc = [];
        params_autoclean.sd_thresh_lf = [];
        params_autoclean.amplitudeThreshold_hf = [];
        params_autoclean.pointSpreadWidth = [];
        params_autoclean.chan_ex = [];
        cnt_trimmed = cnt;
        cnt_trimmed.etc.rejectDataIntervals_beforeICA = rejectDataIntervals;
    end
    save([analysis_path cond_name '_' num2str(iblock) '_automatic_artifacts_beforeICA.mat'], 'rejectDataIntervals', 'badPointsInSec', 'badPointsPerc', 'params_autoclean')
    
    if preICAtrim
        % actually remove artifacts from this dataset
        cnt_trimmed = pop_select(cnt_trimmed, 'nopoint', rejectDataIntervals);
        cnt_trimmed = eeg_checkset(cnt_trimmed);
    end
    
    
    % save cleaned dataset (ready for ICA)
    cnt_trimmed = pop_saveset(cnt_trimmed, [analysis_path cond_name '_' num2str(iblock) '_clean_beforeICA.set']);
    
    
    % also plot spectrum and save it (double-check)
    h = figure; pop_spectopo(cnt, 1, [], 'EEG' , 'percent', 100, 'freqrange',[1 100],'electrodes','off'); % spectrogram
    title([subject_id ': ' cond_name ', block ' num2str(iblock)])
    export_fig([getenv('ANADIR') 'Power_spectrum_beforeICA.pdf'], '-pdf', '-append', h)
    close
end

