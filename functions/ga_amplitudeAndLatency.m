% Author: Birgit Nierula
% nierula@cbs.mpg.de

function ga_amplitudeAndLatency(subjects, condition, srmr_nr)

savepath_ga = getenv('GADIR'); if ~exist(savepath_ga,'dir'), mkdir(savepath_ga); end

% get condition info
[cond_info] = get_conditionInfo(condition, srmr_nr);
cond_name1 = cond_info.cond_name;
nerve = cond_info.nerve;
trigger_name = cond_info.trigger_name;
str_stimulation  = cond_info.str_stimulation(2:end);
if strcmp('digits', str_stimulation)
    str_stimulation = 'sensory';
    for subcondition = 1:3
        cond_name{subcondition} = [cond_name1(1:5) trigger_name{subcondition}(4:end)];
    end
else
    cond_name{1} = cond_name1;
end

if nerve == 1
    nerve_name = 'medianus';
    target_eeg = 'CP4';
    target_bs = 'SC1';
    target_esg = 'SC6';
    target_eng = {'EP' 'Biceps'};
elseif nerve == 2
    nerve_name = 'tibialis';
    target_eeg = 'Cz';
    target_bs = 'S3';
    target_esg = 'L1';
    target_eng = {'KneeM' 'Knee1' 'Knee2' 'Knee3' 'Knee4'};
end

if srmr_nr == 1
    str_add = '';
elseif srmr_nr == 2
    str_add = '_long';
end

for isubject = subjects
    
    %% set variables
    subject_id = sprintf('sub-%03i', isubject);
    savepath_eeg = [getenv('EEGDIR') subject_id '/'];
    savepath_bs = [getenv('ANADIR') subject_id '/bs/prepro/'];
    savepath_bs2 = [getenv('BSDIR') subject_id '/'];
    savepath_esg = [getenv('ESGDIR') subject_id '/'];
    savepath_other = [getenv('OTHERDIR') subject_id '/other/prepro/'];

    
    %% load data
    % eeg
    fname = ['epo_avgRef_cleanclean_' cond_name{1} str_add '.set'];
    epo1_eeg = pop_loadset('filename', fname, 'filepath', savepath_eeg);
    if length(cond_name) > 1
        fname = ['epo_avgRef_cleanclean_' cond_name{2} str_add '.set'];
        epo2_eeg = pop_loadset('filename', fname, 'filepath', savepath_eeg);
        fname = ['epo_avgRef_cleanclean_' cond_name{3} str_add '.set'];
        epo12_eeg = pop_loadset('filename', fname, 'filepath', savepath_eeg);
    else
        epo2_eeg = []; epo12_eeg = []; 
    end
    % eeg-cca
    fname = ['epo_ccacleanclean_' cond_name{1} str_add '.set'];
    cca1_eeg = pop_loadset('filename', fname, 'filepath', savepath_eeg);
    if length(cond_name) > 1
        fname = ['epo_ccacleanclean_' cond_name{2} str_add '.set'];
        cca2_eeg = pop_loadset('filename', fname, 'filepath', savepath_eeg);
        fname = ['epo_ccacleanclean_' cond_name{3} str_add '.set'];
        cca12_eeg = pop_loadset('filename', fname, 'filepath', savepath_eeg);
    else
        cca2_eeg = []; cca12_eeg = []; 
    end
    % bs
    fname = ['epo_bs_cleanclean_' cond_name{1} str_add '.set'];
    if exist([savepath_bs fname], 'file')
        epo1_bs = pop_loadset('filename', fname, 'filepath', savepath_bs);
        if length(cond_name) > 1
            fname = ['epo_bs_cleanclean_' cond_name{2} str_add '.set'];
            epo2_bs = pop_loadset('filename', fname, 'filepath', savepath_bs);
            fname = ['epo_bs_cleanclean_' cond_name{3} str_add '.set'];
            epo12_bs = pop_loadset('filename', fname, 'filepath', savepath_bs);
        else
            epo2_bs = []; epo12_bs = []; 
        end
        has_bs = true;
    else
        has_bs = false;
    end
    % esg
    fname = ['epo_cleanclean_' cond_name{1} str_add '.set'];
    epo1_esg = pop_loadset('filename', fname, 'filepath', savepath_esg);
    if length(cond_name) > 1
        fname = ['epo_cleanclean_' cond_name{2} str_add '.set'];
        epo2_esg = pop_loadset('filename', fname, 'filepath', savepath_esg);
        fname = ['epo_cleanclean_' cond_name{3} str_add '.set'];
        epo12_esg = pop_loadset('filename', fname, 'filepath', savepath_esg);
    else
        epo2_esg = []; epo12_esg = []; 
    end
    % esg-cca
    fname = ['epo_ccacleanclean_' cond_name{1} str_add '.set'];
    if exist([savepath_esg fname], 'file')
        cca1_esg = pop_loadset('filename', fname, 'filepath', savepath_esg);
        if length(cond_name) > 1
            fname = ['epo_ccacleanclean_' cond_name{2} str_add '.set'];
            cca2_esg = pop_loadset('filename', fname, 'filepath', savepath_esg);
            fname = ['epo_ccacleanclean_' cond_name{3} str_add '.set'];
            cca12_esg = pop_loadset('filename', fname, 'filepath', savepath_esg);
        else
            cca2_esg = []; cca12_esg = []; 
        end
        has_ccaesg = true;
    else
        has_ccaesg = false;
    end
    % eng
    fname = ['eng_epocleanfilt_' cond_name{1} str_add '.set'];
    epo1_eng = pop_loadset('filename', fname, 'filepath', savepath_other);
    if length(cond_name) > 1
        fname = ['eng_epocleanfilt_' cond_name{2} str_add '.set'];
        epo2_eng = pop_loadset('filename', fname, 'filepath', savepath_other);
        fname = ['eng_epocleanfilt_' cond_name{3} str_add '.set'];
        epo12_eng = pop_loadset('filename', fname, 'filepath', savepath_other);
    else
        epo2_eng = []; epo12_eng = []; 
    end
    
    
    %% load latencies
    % eeg
    fname = [savepath_eeg nerve_name '_extracted_latencies.mat'];
    load(fname, 'latency')
    if strcmp(str_stimulation, 'sensory')
        eeg1_potlatency.d1 = latency.(str_stimulation).d1.eeg;
        eeg2_potlatency.d1 = latency.(str_stimulation).d1.eeg_cca;
        eeg1_potlatency.d2 = latency.(str_stimulation).d2.eeg;
        eeg2_potlatency.d2 = latency.(str_stimulation).d2.eeg_cca;
        eeg1_potlatency.d12 = latency.(str_stimulation).d12.eeg;
        eeg2_potlatency.d12 = latency.(str_stimulation).d12.eeg_cca;
    else
        eeg1_potlatency.d1 = latency.(str_stimulation).eeg; % mixed nerve is named d1 here!
        eeg2_potlatency.d1 = latency.(str_stimulation).eeg_cca; % mixed nerve is named d1 here!
    end
    clear latency
    % bs
    fname = [savepath_bs2 nerve_name '_extracted_latencies.mat'];
    load(fname, 'latency')
    if strcmp(str_stimulation, 'sensory')
        bs_potlatency.d1 = latency.(str_stimulation).d1.bs;
        bs_potlatency.d2 = latency.(str_stimulation).d2.bs;
        bs_potlatency.d12 = latency.(str_stimulation).d12.bs;
    else
        bs_potlatency.d1 = latency.(str_stimulation).bs; % mixed nerve is named d1 here!
    end
    clear latency
    % esg
    fname = [savepath_esg nerve_name '_extracted_latencies.mat'];
    load(fname, 'latency')
    if strcmp(str_stimulation, 'sensory')
        esg1_potlatency.d1 = latency.(str_stimulation).d1.esg;
        esg1_potlatency.d2 = latency.(str_stimulation).d2.esg;
        esg1_potlatency.d12 = latency.(str_stimulation).d12.esg;
    else
        esg1_potlatency.d1 = latency.(str_stimulation).esg; % mixed nerve is named d1 here!
    end
    if has_ccaesg
        if strcmp(str_stimulation, 'sensory')
            esg2_potlatency.d1 = latency.(str_stimulation).d1.esg_cca;
            esg2_potlatency.d2 = latency.(str_stimulation).d2.esg_cca;
            esg2_potlatency.d12 = latency.(str_stimulation).d12.esg_cca;
        else
            esg2_potlatency.d1 = latency.(str_stimulation).esg_cca; % mixed nerve is named d1 here!
        end
    end
    clear latency
    % eng
    fname = [savepath_other nerve_name '_extracted_latencies.mat'];
    load(fname, 'latency')
    if strcmp(str_stimulation, 'sensory')
        eng_potlatency.d1 = latency.(str_stimulation).d1.eng;
        eng_potlatency.d2 = latency.(str_stimulation).d2.eng;
        eng_potlatency.d12 = latency.(str_stimulation).d12.eng;
    else
        eng_potlatency.d1 = latency.(str_stimulation).eng; % mixed nerve is named d1 here!
    end
    clear latency
    
    
    %% extract amplitude
    if ~exist('values', 'var')
        values = [];
    end
    % eeg
    chan_idx = find(ismember({epo1_eeg.chanlocs.labels}, target_eeg));
    values = get_values(epo1_eeg, epo2_eeg, epo12_eeg, chan_idx, eeg1_potlatency, ...
        cond_name, target_eeg, values, isubject);
    
    % eeg - cca
    chan_idx = 1;
    values = get_values(cca1_eeg, cca2_eeg, cca12_eeg, chan_idx, eeg2_potlatency, ...
        cond_name, 'eeg_cca', values, isubject);
    
    % bs
    if has_bs
        chan_idx = find(ismember({epo1_bs.chanlocs.labels}, target_bs));
        values = get_values(epo1_bs, epo2_bs, epo12_bs, chan_idx, bs_potlatency, ...
            cond_name, target_bs, values, isubject);
    else
        values = get_values([], [], [], [], [], ...
            cond_name, target_bs, values, isubject);
    end
    
    % esg
    chan_idx = find(ismember({epo1_esg.chanlocs.labels}, target_esg));
    values = get_values(epo1_esg, epo2_esg, epo12_esg, chan_idx, esg1_potlatency, ...
        cond_name, target_esg, values, isubject);
    
    % esg - cca
    if has_ccaesg
        chan_idx = 1;
        values = get_values(cca1_esg, cca2_esg, cca12_esg, chan_idx, esg2_potlatency, ...
            cond_name, 'esg_cca', values, isubject);%, false);
    end
    
    % eng - amp
    chan_idx = find(ismember({epo1_eng.chanlocs.labels}, target_eng));
    for ii = 1:length(chan_idx)
        potlatency.d1 = eng_potlatency.d1{ii};
        if strcmp(str_stimulation, 'sensory')
            potlatency.d2 = eng_potlatency.d2{ii};
            potlatency.d12 = eng_potlatency.d12{ii};
        end
        values = get_values(epo1_eng, epo2_eng, epo12_eng, chan_idx(ii), potlatency, ...
            cond_name, target_eng{ii}, values, isubject);
    end
    
    
end

%% save
eval([cond_name1 '_values = values;'])
fname = [savepath_ga 'amplitudeAndLatency_allSubjects.mat'];
if exist(fname, 'file')
    save(fname, [cond_name1 '_values'], '-append')
else
    save(fname, [cond_name1 '_values'])
end


end

%% ========================================================================
%% function: get values
%% ========================================================================
function values = get_values(epo1, epo2, epo12, chan_idx, potlatency, ...
    cond_name, chan_name, values, isubject)

max_events = 2000;
if length(cond_name) > 1
    max_events_d = 6000;
end
% add NaN
if length(cond_name) > 1
    values.amplitude.d1.(chan_name)(isubject,:) = nan(1,max_events);
    values.amplitude.d2.(chan_name)(isubject,:) = nan(1,max_events);
    values.amplitude.d12.(chan_name)(isubject,:) = nan(1,max_events);
    
    values.latency.d1.(chan_name)(isubject,:) = NaN;
    values.latency.d2.(chan_name)(isubject,:) = NaN;
    values.latency.d12.(chan_name)(isubject,:) = NaN;
    
else
    values.amplitude.mixed.(chan_name)(isubject,:,:) = nan(1,1,max_events);
    values.latency.mixed.(chan_name)(isubject,:) = NaN;
end

if ~isempty(potlatency)
    if ~isempty(potlatency.d1)
    
        if length(cond_name) > 1
            values = get_valuesDigits(epo1, epo2, epo12, chan_idx, potlatency, ...
                chan_name, values, isubject);
        else
            values = get_valuesMixed(epo1, chan_idx, potlatency, ...
                chan_name, values, isubject);
            
        end
    end
end

end

%% ========================================================================
%% function: values digits
%% ========================================================================
function values = get_valuesDigits(epo1, epo2, epo12, chan_idx, potlatency, ...
    chan_name, values, isubject)

if ~isnan(potlatency.d1(1))
    potlatency.d1 = potlatency.d1(1);
    % D1
    sample_idx1 = find(epo1.times == potlatency.d1);
    tmp_amp1 = squeeze(epo1.data(chan_idx, sample_idx1, :))';
    % add amplitudes to struct
    ntrials = size(tmp_amp1,2);
    values.amplitude.d1.(chan_name)(isubject,1:ntrials) = tmp_amp1;
    % add latencies to struct
    values.latency.d1.(chan_name)(isubject,:) = potlatency.d1;
end

if ~isnan(potlatency.d2(1))
    potlatency.d2 = potlatency.d2(1);
    % D2
    sample_idx2 = find(epo2.times == potlatency.d2);
    tmp_amp2 = squeeze(epo2.data(chan_idx, sample_idx2, :))';
    % add amplitudes to struct
    ntrials = size(tmp_amp2,2);
    values.amplitude.d2.(chan_name)(isubject,1:ntrials) = tmp_amp2;
    % add latencies to struct
    values.latency.d2.(chan_name)(isubject,:) = potlatency.d2;
end

if ~isnan(potlatency.d12(1))
    
    potlatency.d12 = potlatency.d12(1);
    % D12
    sample_idx12 = find(epo12.times == potlatency.d12);
    tmp_amp12 = squeeze(epo12.data(chan_idx, sample_idx12, :))';
    % add amplitudes to struct
    ntrials = size(tmp_amp12,2);
    values.amplitude.d12.(chan_name)(isubject,1:ntrials) = tmp_amp12;
    % add latencies to struct
    values.latency.d12.(chan_name)(isubject,:) = potlatency.d12;
    
end

end

%% ========================================================================
%% function: values mixed
%% ========================================================================
function values = get_valuesMixed(epo, chan_idx, potlatency, ...
    chan_name, values, isubject)%, is_peak2peak)


potlatency = potlatency.d1; % this is named d1 although it is mixed nerve!
if ~isnan(potlatency(1))
    potlatency = potlatency(1);
    sample_idx = find(epo.times == potlatency);
    tmp_amp = squeeze(epo.data(chan_idx, sample_idx, :))';
    % add amplitudes to struct
    ntrials = size(tmp_amp,2);
    values.amplitude.mixed.(chan_name)(isubject,1:ntrials) = tmp_amp;
    % add latencies to struct
    values.latency.mixed.(chan_name)(isubject,:) = potlatency;
    
end

end
