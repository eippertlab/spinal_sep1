% Author: Birgit Nierula
% nierula@cbs.mpg.de

function ga_amplitudeAndLatency_allSubjects(subjects, condition, srmr_nr)

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
    cond_name{4} = [cond_name1(1:5) '_all'];
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
    
%% get mean latencies over all subjects
for isubject = subjects
    
    %% set variables
    subject_id = sprintf('sub-%03i', isubject);
    savepath_eeg = [getenv('EEGDIR') subject_id '/'];
    savepath_bs = [getenv('ANADIR') subject_id '/bs/prepro/'];
    savepath_bs2 = [getenv('BSDIR') subject_id '/'];
    savepath_esg = [getenv('ESGDIR') subject_id '/'];
    savepath_other = [getenv('OTHERDIR') subject_id '/other/prepro/'];
    
    % eeg
    fname = [savepath_eeg nerve_name '_extracted_latencies.mat'];
    load(fname, 'latency')
    if strcmp(str_stimulation, 'sensory')
        eeg1_latencies.d1(isubject) = latency.(str_stimulation).d1.eeg(1);
        eeg2_latencies.d1(isubject) = latency.(str_stimulation).d1.eeg_cca(1);
        eeg1_latencies.d2(isubject) = latency.(str_stimulation).d2.eeg(1);
        eeg2_latencies.d2(isubject) = latency.(str_stimulation).d2.eeg_cca(1);
        eeg1_latencies.d12(isubject) = latency.(str_stimulation).d12.eeg(1);
        eeg2_latencies.d12(isubject) = latency.(str_stimulation).d12.eeg_cca(1);
    else
        eeg1_latencies.d1(isubject) = latency.(str_stimulation).eeg(1); % mixed nerve is named d1 here!
        eeg2_latencies.d1(isubject) = latency.(str_stimulation).eeg_cca(1); % mixed nerve is named d1 here!
    end
    clear latency
    % bs
    fname = [savepath_bs2 nerve_name '_extracted_latencies.mat'];
    load(fname, 'latency')
    if strcmp(str_stimulation, 'sensory')
        tmp = latency.(str_stimulation).d1.bs;
        if isempty(tmp)
            bs_latencies.d1(isubject) = NaN;
        else
            bs_latencies.d1(isubject) = tmp(1);
        end
        tmp = latency.(str_stimulation).d2.bs;
        if isempty(tmp)
            bs_latencies.d2(isubject) = NaN;
        else
            bs_latencies.d2(isubject) = tmp(1);
        end
        tmp = latency.(str_stimulation).d12.bs;
        if isempty(tmp)
            bs_latencies.d12(isubject) = NaN;
        else
            bs_latencies.d12(isubject) = tmp(1);
        end
    else
        tmp = latency.(str_stimulation).bs;
        if isempty(tmp)
            bs_latencies.d1(isubject) = NaN;
        else
            bs_latencies.d1(isubject) = tmp(1);
        end
    end
    clear latency tmp
    % esg
    fname = [savepath_esg nerve_name '_extracted_latencies.mat'];
    load(fname, 'latency')
    if strcmp(str_stimulation, 'sensory')
        esg1_latencies.d1(isubject) = latency.(str_stimulation).d1.esg(1);
        esg1_latencies.d2(isubject) = latency.(str_stimulation).d2.esg(1);
        esg1_latencies.d12(isubject) = latency.(str_stimulation).d12.esg(1);
    else
        esg1_latencies.d1(isubject) = latency.(str_stimulation).esg(1); % mixed nerve is named d1 here!
    end
    % esg cca
    if strcmp(str_stimulation, 'sensory')
        esg2_latencies.d1(isubject) = latency.(str_stimulation).d1.esg_cca(1);
        esg2_latencies.d2(isubject) = latency.(str_stimulation).d2.esg_cca(1);
        esg2_latencies.d12(isubject) = latency.(str_stimulation).d12.esg_cca(1);
    else
        esg2_latencies.d1(isubject) = latency.(str_stimulation).esg_cca(1); % mixed nerve is named d1 here!
    end
    % esg antRef --> calculate latencies + save
    tmp_latencies = get_newpotLatency(cond_name, esg1_latencies, str_stimulation, savepath_esg, str_add, isubject);
    esg3_latencies.d1(isubject) = tmp_latencies.d1(1);
    if strcmp(str_stimulation, 'sensory')
        esg3_latencies.d2(isubject) = tmp_latencies.d2(1);
        esg3_latencies.d12(isubject) = tmp_latencies.d12(1);
    end
    % save new values
    if strcmp(str_stimulation, 'sensory')
        latency.(str_stimulation).d1.esg_antRef = tmp_latencies.d1;
        latency.(str_stimulation).d2.esg_antRef = tmp_latencies.d2;
        latency.(str_stimulation).d12.esg_antRef = tmp_latencies.d12;
    else
        latency.(str_stimulation).esg_antRef = tmp_latencies.d1; % mixed nerve is named d1 here!
    end
    fname = [savepath_esg nerve_name '_extracted_latencies.mat'];
    save(fname, 'latency', '-append')
    clear latency
    % eng
    fname = [savepath_other nerve_name '_extracted_latencies.mat'];
    load(fname, 'latency')
    for ichan = 1:length(target_eng)
        if strcmp(str_stimulation, 'sensory')
            eng_latencies.d1{ichan}(isubject) = latency.(str_stimulation).d1.eng{ichan}(1);
            eng_latencies.d2{ichan}(isubject) = latency.(str_stimulation).d2.eng{ichan}(1);
            eng_latencies.d12{ichan}(isubject) = latency.(str_stimulation).d12.eng{ichan}(1);
        else
            eng_latencies.d1{ichan}(isubject) = latency.(str_stimulation).eng{ichan}(1); % mixed nerve is named d1 here!
        end
    end
    clear latency
end
if strcmp(str_stimulation, 'sensory')
    eeg1_meanlatency.d1 = round(nanmean(eeg1_latencies.d1));
    eeg1_meanlatency.d2= round(nanmean(eeg1_latencies.d2));
    eeg1_meanlatency.d12 = round(nanmean(eeg1_latencies.d12));clear eeg1_latencies
    eeg2_meanlatency.d1 = round(nanmean(eeg2_latencies.d1));
    eeg2_meanlatency.d2 = round(nanmean(eeg2_latencies.d2));
    eeg2_meanlatency.d12 = round(nanmean(eeg2_latencies.d12));clear eeg2_latencies
    bs_meanlatency.d1 = round(nanmean(bs_latencies.d1));
    bs_meanlatency.d2 = round(nanmean(bs_latencies.d2));
    bs_meanlatency.d12 = round(nanmean(bs_latencies.d12));clear bs_latencies
    esg1_meanlatency.d1 = round(nanmean(esg1_latencies.d1));
    esg1_meanlatency.d2 = round(nanmean(esg1_latencies.d2));
    esg1_meanlatency.d12 = round(nanmean(esg1_latencies.d12)); clear esg1_latencies
    esg2_meanlatency.d1 = round(nanmean(esg2_latencies.d1));
    esg2_meanlatency.d2 = round(nanmean(esg2_latencies.d2));
    esg2_meanlatency.d12 = round(nanmean(esg2_latencies.d12));clear esg2_latencies
    esg3_meanlatency.d1 = round(nanmean(esg3_latencies.d1));
    esg3_meanlatency.d2 = round(nanmean(esg3_latencies.d2));
    esg3_meanlatency.d12 = round(nanmean(esg3_latencies.d12));clear esg3_latencies
    for ichan = 1:length(target_eng)
        eng_meanlatency.d1{ichan} = round(nanmean(eng_latencies.d1{ichan})); 
        eng_meanlatency.d2{ichan} = round(nanmean(eng_latencies.d2{ichan})); 
        eng_meanlatency.d12{ichan} = round(nanmean(eng_latencies.d12{ichan})); 
    end
else
    eeg1_meanlatency.d1 = round(nanmean(eeg1_latencies.d1));
    eeg2_meanlatency.d1 = round(nanmean(eeg2_latencies.d1));
    bs_meanlatency.d1 = round(nanmean(bs_latencies.d1));
    esg1_meanlatency.d1 = round(nanmean(esg1_latencies.d1));
    esg2_meanlatency.d1 = round(nanmean(esg2_latencies.d1));    
    for ichan = 1:length(target_eng)
        eng_meanlatency.d1{ichan} = round(nanmean(eng_latencies.d1{ichan})); 
    end
end
clear eng_latencies

%% get individual latencies + amplitudes
for isubject = subjects
    
    %% set variables
    subject_id = sprintf('sub-%03i', isubject);
    savepath_eeg = [getenv('EEGDIR') subject_id '/'];
    savepath_bs = [getenv('ANADIR') subject_id '/bs/prepro/'];
    savepath_bs2 = [getenv('BSDIR') subject_id '/'];
    savepath_esg = [getenv('ESGDIR') subject_id '/'];
    savepath_other = [getenv('OTHERDIR') subject_id '/other/prepro/'];
    savepath_ga = getenv('GADIR'); if ~exist(savepath_ga,'dir'), mkdir(savepath_ga); end
    
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
    % esg - antRef
    fname = ['epo_antRef_cleanclean_' cond_name{1} str_add '.set'];
    epo1ar_esg = pop_loadset('filename', fname, 'filepath', savepath_esg);
    if length(cond_name) > 1
        fname = ['epo_antRef_cleanclean_' cond_name{2} str_add '.set'];
        epo2ar_esg = pop_loadset('filename', fname, 'filepath', savepath_esg);
        fname = ['epo_antRef_cleanclean_' cond_name{3} str_add '.set'];
        epo12ar_esg = pop_loadset('filename', fname, 'filepath', savepath_esg);
    else
        epo2ar_esg = []; epo12ar_esg = []; 
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
    if has_bs
        fname = [savepath_bs2 nerve_name '_extracted_latencies.mat'];
        load(fname, 'latency')
        if strcmp(str_stimulation, 'sensory')
            tmp = latency.(str_stimulation).d1.bs;
            if isempty(tmp)
                bs_potlatency.d1 = NaN;
            else
                bs_potlatency.d1 = tmp(1);
            end
            tmp = latency.(str_stimulation).d2.bs;
            if isempty(tmp)
                bs_potlatency.d2 = NaN;
            else
                bs_potlatency.d2 = tmp(1);
            end
            tmp = latency.(str_stimulation).d12.bs;
            if isempty(tmp)
                bs_potlatency.d12 = NaN;
            else
                bs_potlatency.d12 = tmp(1);
            end
        else
            tmp = latency.(str_stimulation).bs; % mixed nerve is named d1 here!
            if isempty(tmp)
                bs_potlatency.d1 = NaN;
            else
                bs_potlatency.d1 = tmp(1);
            end
        end
        clear latency tmp
    end
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
    % esg-cca
    if has_ccaesg
        if strcmp(str_stimulation, 'sensory')
            esg2_potlatency.d1 = latency.(str_stimulation).d1.esg_cca;
            esg2_potlatency.d2 = latency.(str_stimulation).d2.esg_cca;
            esg2_potlatency.d12 = latency.(str_stimulation).d12.esg_cca;
        else
            esg2_potlatency.d1 = latency.(str_stimulation).esg_cca; % mixed nerve is named d1 here!
        end
    end
    %esg-antRef
    if strcmp(str_stimulation, 'sensory')
        esg3_potlatency.d1 = latency.(str_stimulation).d1.esg_antRef;
        esg3_potlatency.d2 = latency.(str_stimulation).d2.esg_antRef;
        esg3_potlatency.d12 = latency.(str_stimulation).d12.esg_antRef;
    else
        esg3_potlatency.d1 = latency.(str_stimulation).esg_antRef; % mixed nerve is named d1 here!
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
    
    %% replace Nan or emtpy latencies with mean latency
    if strcmp(str_stimulation, 'sensory')
        % eeg1 (single chan)
        if isempty(eeg1_potlatency.d1), eeg1_potlatency.d1 = NaN; end
        if isnan(eeg1_potlatency.d1), eeg1_potlatency.d1 = eeg1_meanlatency.d1; end
        if isempty(eeg1_potlatency.d2), eeg1_potlatency.d2 = NaN; end
        if isnan(eeg1_potlatency.d2), eeg1_potlatency.d2 = eeg1_meanlatency.d2; end
        if isempty(eeg1_potlatency.d12), eeg1_potlatency.d12 = NaN; end
        if isnan(eeg1_potlatency.d12), eeg1_potlatency.d12 = eeg1_meanlatency.d12; end
        % eeg2 (cca)
        if isempty(eeg2_potlatency.d1), eeg2_potlatency.d1 = NaN; end
        if isnan(eeg2_potlatency.d1), eeg2_potlatency.d1 = eeg2_meanlatency.d1; end
        if isempty(eeg2_potlatency.d2), eeg2_potlatency.d2 = NaN; end
        if isnan(eeg2_potlatency.d2), eeg2_potlatency.d2 = eeg2_meanlatency.d2; end
        if isempty(eeg2_potlatency.d12), eeg2_potlatency.d12 = NaN; end
        if isnan(eeg2_potlatency.d12), eeg2_potlatency.d12 = eeg2_meanlatency.d12; end
        % bs
        if has_bs
            if isempty(bs_potlatency.d1), bs_potlatency.d1 = NaN; end
            if isnan(bs_potlatency.d1), bs_potlatency.d1 = bs_meanlatency.d1; end
            if isempty(bs_potlatency.d2), bs_potlatency.d2 = NaN; end
            if isnan(bs_potlatency.d2), bs_potlatency.d2 = bs_meanlatency.d2; end
            if isempty(bs_potlatency.d12), bs_potlatency.d12 = NaN; end
            if isnan(bs_potlatency.d12), bs_potlatency.d12 = bs_meanlatency.d12; end
        end
        % esg1 (single chan)
        if isempty(esg1_potlatency.d1), esg1_potlatency.d1 = NaN; end
        if isnan(esg1_potlatency.d1), esg1_potlatency.d1 = esg1_meanlatency.d1; end
        if isempty(esg1_potlatency.d2), esg1_potlatency.d2 = NaN; end
        if isnan(esg1_potlatency.d2), esg1_potlatency.d2 = esg1_meanlatency.d2; end
        if isempty(esg1_potlatency.d12), esg1_potlatency.d12 = NaN; end
        if isnan(esg1_potlatency.d12), esg1_potlatency.d12 = esg1_meanlatency.d12; end
        % esg2 (cca)
        if isempty(esg2_potlatency.d1), esg2_potlatency.d1 = NaN; end
        if isnan(esg2_potlatency.d1), esg2_potlatency.d1 = esg2_meanlatency.d1; end
        if isempty(esg2_potlatency.d2), esg2_potlatency.d2 = NaN; end
        if isnan(esg2_potlatency.d2), esg2_potlatency.d2 = esg2_meanlatency.d2; end
        if isempty(esg2_potlatency.d12), esg2_potlatency.d12 = NaN; end
        if isnan(esg2_potlatency.d12), esg2_potlatency.d12 = esg2_meanlatency.d12; end
        % esg3 (anterior Ref)
        if isempty(esg3_potlatency.d1), esg3_potlatency.d1 = NaN; end
        if isnan(esg3_potlatency.d1), esg3_potlatency.d1 = esg3_meanlatency.d1; end
        if isempty(esg3_potlatency.d2), esg3_potlatency.d2 = NaN; end
        if isnan(esg3_potlatency.d2), esg3_potlatency.d2 = esg3_meanlatency.d2; end
        if isempty(esg3_potlatency.d12), esg3_potlatency.d12 = NaN; end
        if isnan(esg3_potlatency.d12), esg3_potlatency.d12 = esg3_meanlatency.d12; end
        % eng
        for ichan = 1:length(target_eng)
            if isempty(eng_potlatency.d1{ichan}), eng_potlatency.d1{ichan} = NaN; end
            if isnan(eng_potlatency.d1{ichan}), eng_potlatency.d1{ichan} = eng_meanlatency.d1{ichan}; end
            if isempty(eng_potlatency.d2{ichan}), eng_potlatency.d2{ichan} = NaN; end
            if isnan(eng_potlatency.d2{ichan}), eng_potlatency.d2{ichan} = eng_meanlatency.d2{ichan}; end
            if isempty(eng_potlatency.d12{ichan}), eng_potlatency.d12{ichan} = NaN; end
            if isnan(eng_potlatency.d12{ichan}), eng_potlatency.d12{ichan} = eng_meanlatency.d12{ichan}; end
        end
    else
        % eeg1 (single chan)
        if isempty(eeg1_potlatency.d1), eeg1_potlatency.d1 = NaN; end
        if isnan(eeg1_potlatency.d1), eeg1_potlatency.d1 = eeg1_meanlatency.d1; end
        % eeg2 (cca)
        if isempty(eeg2_potlatency.d1), eeg2_potlatency.d1 = NaN; end
        if isnan(eeg2_potlatency.d1), eeg2_potlatency.d1 = eeg2_meanlatency.d1; end
        % bs
        if has_bs
            if isempty(bs_potlatency.d1), bs_potlatency.d1 = NaN; end
            if isnan(bs_potlatency.d1), bs_potlatency.d1 = bs_meanlatency.d1; end
        end
        % esg1 (single chan)
        if isempty(esg1_potlatency.d1), esg1_potlatency.d1 = NaN; end
        if isnan(esg1_potlatency.d1), esg1_potlatency.d1 = esg1_meanlatency.d1; end
        % esg2 (cca)
        if isempty(esg2_potlatency.d1), esg2_potlatency.d1 = NaN; end
        if isnan(esg2_potlatency.d1), esg2_potlatency.d1 = esg2_meanlatency.d1; end
        % esg3 (anterior Ref)
        if isempty(esg3_potlatency.d1), esg3_potlatency.d1 = NaN; end
        if isnan(esg3_potlatency.d1), esg3_potlatency.d1 = esg3_meanlatency.d1; end
        % eng
        for ichan = 1:length(target_eng)
            if isempty(eng_potlatency.d1{ichan}), eng_potlatency.d1{ichan} = NaN; end
            if isnan(eng_potlatency.d1{ichan}), eng_potlatency.d1{ichan} = eng_meanlatency.d1{ichan}; end
        end
    end
    
    
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
    
    % esg - TH6
    chan_idx = find(ismember({epo1_esg.chanlocs.labels}, target_esg));
    values = get_values(epo1_esg, epo2_esg, epo12_esg, chan_idx, esg1_potlatency, ...
        cond_name, target_esg, values, isubject);
    
    % esg - antRef
    chan_idx = find(ismember({epo1ar_esg.chanlocs.labels}, target_esg));
    values = get_values(epo1ar_esg, epo2ar_esg, epo12ar_esg, chan_idx, esg3_potlatency, ...
        cond_name, [target_esg '_antRef'], values, isubject);

    % esg - cca
    if has_ccaesg
        chan_idx = 1;
        values = get_values(cca1_esg, cca2_esg, cca12_esg, chan_idx, esg2_potlatency, ...
            cond_name, 'esg_cca', values, isubject);
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
fname = [savepath_ga 'amplitudeAndLatency_allSubjects_noNaN.mat'];
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


% add NaN
if length(cond_name) > 1
    max_events = 6000;
    
    values.amplitude.d1.(chan_name)(isubject,:) = nan(1, max_events);
    values.amplitude.d2.(chan_name)(isubject,:) = nan(1, max_events);
    values.amplitude.d12.(chan_name)(isubject,:) = nan(1, max_events);
    
    values.latency.d1.(chan_name)(isubject,:) = NaN;
    values.latency.d2.(chan_name)(isubject,:) = NaN;
    values.latency.d12.(chan_name)(isubject,:) = NaN;

    values.rms.d1.(chan_name).signal(isubject,:) = NaN;
    values.rms.d2.(chan_name).signal(isubject,:) = NaN;
    values.rms.d12.(chan_name).signal(isubject,:) = NaN;
    values.rms.d1.(chan_name).noise(isubject,:) = NaN;
    values.rms.d2.(chan_name).noise(isubject,:) = NaN;
    values.rms.d12.(chan_name).noise(isubject,:) = NaN;
    
else
    max_events = 2000;
    values.amplitude.mixed.(chan_name)(isubject,:) = nan(1, max_events);
    values.latency.mixed.(chan_name)(isubject,:) = NaN;
    values.rms.mixed.(chan_name).signal(isubject,:) = NaN;
    values.rms.mixed.(chan_name).noise(isubject,:) = NaN;
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
    if length(potlatency.d1) > 1
        potlatency.d1 = potlatency.d1(1);
    end
    % D1
    % add amplitudes to struct
    [amp, RMS, lat] = extract_values(epo1, potlatency.d1, chan_idx);
    ntrials = size(amp,2);
    values.amplitude.d1.(chan_name)(isubject,1:ntrials) = amp;
    % add rms
    values.rms.d1.(chan_name).signal(isubject,:) = RMS.signal;
    values.rms.d1.(chan_name).noise(isubject,:) = RMS.noise;
    % add latencies to struct
    values.latency.d1.(chan_name)(isubject,:) = lat;
    clear amp RMS lat
end

if ~isnan(potlatency.d2(1))
    if length(potlatency.d2) > 1
        potlatency.d2 = potlatency.d2(1);
    end
    % D2
    % add amplitudes to struct
    [amp, RMS, lat] = extract_values(epo2, potlatency.d2, chan_idx);
    ntrials = size(amp,2);
    values.amplitude.d2.(chan_name)(isubject,1:ntrials) = amp;
    % add rms
    values.rms.d2.(chan_name).signal(isubject,:) = RMS.signal;
    values.rms.d2.(chan_name).noise(isubject,:) = RMS.noise;
    % add latencies to struct
    values.latency.d2.(chan_name)(isubject,:) = lat;
    clear amp RMS lat
end

if ~isnan(potlatency.d12(1))
    
    if length(potlatency.d12) > 1
        potlatency.d12 = potlatency.d12(1);
    end
    % D12
    % add amplitudes to struct
    [amp, RMS, lat] = extract_values(epo12, potlatency.d12, chan_idx);
    ntrials = size(amp,2);
    values.amplitude.d12.(chan_name)(isubject,1:ntrials) = amp;
    % add rms
    values.rms.d12.(chan_name).signal(isubject,:) = RMS.signal;
    values.rms.d12.(chan_name).noise(isubject,:) = RMS.noise;
    % add latencies to struct
    values.latency.d12.(chan_name)(isubject,:) = lat;
    clear amp RMS lat
end

end


%% ========================================================================
%% function: values mixed
%% ========================================================================
function values = get_valuesMixed(epo, chan_idx, potlatency, ...
    chan_name, values, isubject)


potlatency = potlatency.d1; % this is named d1 although it is mixed nerve!
if ~isnan(potlatency(1))
    potlatency = potlatency(1);
    % add amplitudes to struct
    [amp, RMS, lat] = extract_values(epo, potlatency, chan_idx);
    ntrials = size(amp,2);
    values.amplitude.mixed.(chan_name)(isubject,1:ntrials) = amp;
    % add rms
    values.rms.mixed.(chan_name).signal(isubject,:) = RMS.signal;
    values.rms.mixed.(chan_name).noise(isubject,:) = RMS.noise;
    % add latencies to struct
    values.latency.mixed.(chan_name)(isubject,:) = lat;
    clear amp RMS lat
    
end

end


%% ========================================================================
%% function: extract values
%% ========================================================================
function [amp, RMS, lat] = extract_values(epo, potential_latency, chan_idx)

% add amplitudes to struct
sample_idx = find(epo.times == potential_latency);
amp = squeeze(epo.data(chan_idx, sample_idx, :))';
dat_signal = nanmean(epo.data(chan_idx, sample_idx-1:sample_idx+1, :), 3);
RMS.signal = rms(dat_signal);
sample_idx_noise = find(epo.times == -potential_latency);
dat_noise = nanmean(epo.data(chan_idx, sample_idx_noise-1:sample_idx_noise+1, :), 3);
RMS.noise = rms(dat_noise);
lat = potential_latency;

end

%% ========================================================================
%% function: get_newpotLatency
%% ========================================================================
function new_potlatency = get_newpotLatency(cond_name, potlatency, str_stimulation, savepath_esg, str_add, isubject)

% load data for esg - antRef
fname = ['epo_antRef_cleanclean_' cond_name{1} str_add '.set'];
epo1 = pop_loadset('filename', fname, 'filepath', savepath_esg);
if length(cond_name) > 1
    fname = ['epo_antRef_cleanclean_' cond_name{2} str_add '.set'];
    epo2 = pop_loadset('filename', fname, 'filepath', savepath_esg);
    fname = ['epo_antRef_cleanclean_' cond_name{3} str_add '.set'];
    epo12 = pop_loadset('filename', fname, 'filepath', savepath_esg);
else
    epo2 = []; epo12 = [];
end
    
% only for esg anterior ref --> potential is always negative
is_negative = true;

% D1 / Mixed
chan_idx = find(ismember({epo1.chanlocs.labels}, 'SC6'));
if ~isnan(potlatency.d1(isubject))
    latency = potlatency.d1(isubject);
    new_latency = get_newPeak(epo1, chan_idx, latency);
else
    new_latency = NaN;
end
new_potlatency.d1 = new_latency; clear new_latency latency
     
if strcmp(str_stimulation, 'sensory')
    % D2
    if ~isnan(potlatency.d2(isubject))
        latency = potlatency.d2(isubject);
        new_latency = get_newPeak(epo2, chan_idx, latency);
    else
        new_latency = NaN;
    end
    new_potlatency.d2 = new_latency; clear new_latency latency

    % D12
    if ~isnan(potlatency.d12(isubject))
        latency = potlatency.d12(isubject);
        new_latency = get_newPeak(epo12, chan_idx, latency);
    else
        new_latency = NaN;
    end
    new_potlatency.d12 = new_latency; clear new_latency latency
end

end


function new_latency = get_newPeak(epo, chan_idx, latency)

% new_latency = latency;

if isnan(latency)
    new_latency = latency;
else
    % finds previous peak idex
    sample_idx = find(epo.times == latency);
    nsamples = 1; %vallue to subtract or add
    sample_ival = sample_idx-nsamples:sample_idx+nsamples;
    dat_signal = nanmean(epo.data(chan_idx, sample_ival, :), 3);
    [~, peak_idx] = min(dat_signal);
    old_amp = squeeze(nanmean(epo.data(chan_idx, sample_idx, :), 3));
    new_amp = squeeze(nanmean(epo.data(chan_idx, sample_ival(peak_idx), :), 3));
    if old_amp <= new_amp
        new_latency = latency;
    else
        new_latency = epo.times(sample_ival(peak_idx));
    end
end


end