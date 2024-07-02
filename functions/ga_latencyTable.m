function ga_latencyTable(subjects, conditions, srmr_nr)


%% all latecies in one table (for each potential: subject x condition)

% set paths
savepath_ga = getenv('GADIR');


clearvars -except subjects conditions srmr_nr savepath_ga
for icondition = conditions
    % get condition info
    [cond_info] = get_conditionInfo(icondition, srmr_nr);
    cond_name = cond_info.cond_name;
    nerve = cond_info.nerve;
    trigger_name = cond_info.trigger_name;
    str_stimulation = cond_info.str_stimulation;
    if strcmp(str_stimulation, '_digits')
        stim_type = 'sensory';
        stim_name = {'d1' 'd2' 'd12'};
    else
        stim_type = 'mixed';
        stim_name = {'mixed'};
    end
    if nerve == 1
        nerve_name = 'medianus';
        target_esg = 'SC6';
        target_eng = {'EP' 'Biceps'};
    elseif nerve == 2
        nerve_name = 'tibialis';
        target_esg = 'L1';
        target_eng = {'Knee'};
    end
    
    % extract individual latencies
    for isubject = subjects
        
        %% set variables
        subject_id = sprintf('sub-%03i', isubject);
        savepath_eeg = [getenv('EEGDIR') subject_id '/'];
        savepath_bs = [getenv('ANADIR') subject_id '/bs/prepro/'];
        savepath_bs2 = [getenv('BSDIR') subject_id '/'];
        savepath_esg = [getenv('ESGDIR') subject_id '/'];
        savepath_other = [getenv('OTHERDIR') subject_id '/other/prepro/'];
        nsubjects = length(subjects);

        %% get mean latencies over all subjects

        % eeg
        fname = [savepath_eeg nerve_name '_extracted_latencies.mat'];
        load(fname, 'latency')
        if strcmp(stim_type, 'sensory')
            eeg1_latencies.d1(isubject) = latency.(stim_type).d1.eeg(1);
            eeg2_latencies.d1(isubject) = latency.(stim_type).d1.eeg_cca(1);
            eeg1_latencies.d2(isubject) = latency.(stim_type).d2.eeg(1);
            eeg2_latencies.d2(isubject) = latency.(stim_type).d2.eeg_cca(1);
            eeg1_latencies.d12(isubject) = latency.(stim_type).d12.eeg(1);
            eeg2_latencies.d12(isubject) = latency.(stim_type).d12.eeg_cca(1);
        else
            eeg1_latencies.d1(isubject) = latency.(stim_type).eeg(1); % mixed nerve is named d1 here!
            eeg2_latencies.d1(isubject) = latency.(stim_type).eeg_cca(1); % mixed nerve is named d1 here!
        end
        clear latency
        % bs
        fname = [savepath_bs2 nerve_name '_extracted_latencies.mat'];
        load(fname, 'latency')
        if strcmp(stim_type, 'sensory')
            tmp = latency.(stim_type).d1.bs;
            if isempty(tmp)
                bs_latencies.d1(isubject) = NaN;
            else
                bs_latencies.d1(isubject) = tmp(1);
            end
            tmp = latency.(stim_type).d2.bs;
            if isempty(tmp)
                bs_latencies.d2(isubject) = NaN;
            else
                bs_latencies.d2(isubject) = tmp(1);
            end
            tmp = latency.(stim_type).d12.bs;
            if isempty(tmp)
                bs_latencies.d12(isubject) = NaN;
            else
                bs_latencies.d12(isubject) = tmp(1);
            end
        else
            tmp = latency.(stim_type).bs;
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
        if strcmp(stim_type, 'sensory')
            esg1_latencies.d1(isubject) = latency.(stim_type).d1.esg(1);
            esg1_latencies.d2(isubject) = latency.(stim_type).d2.esg(1);
            esg1_latencies.d12(isubject) = latency.(stim_type).d12.esg(1);
        else
            esg1_latencies.d1(isubject) = latency.(stim_type).esg(1); % mixed nerve is named d1 here!
        end
        % esg cca
        if strcmp(stim_type, 'sensory')
            esg2_latencies.d1(isubject) = latency.(stim_type).d1.esg_cca(1);
            esg2_latencies.d2(isubject) = latency.(stim_type).d2.esg_cca(1);
            esg2_latencies.d12(isubject) = latency.(stim_type).d12.esg_cca(1);
        else
            esg2_latencies.d1(isubject) = latency.(stim_type).esg_cca(1); % mixed nerve is named d1 here!
        end
        % esg antRef 
            if strcmp(stim_type, 'sensory')
                esg3_latencies.d1(isubject) = latency.(stim_type).d1.esg_antRef(1);
                esg3_latencies.d2(isubject) = latency.(stim_type).d2.esg_antRef(1);
                esg3_latencies.d12(isubject) = latency.(stim_type).d12.esg_antRef(1);
            else
                esg3_latencies.d1(isubject) = latency.(stim_type).esg_antRef(1); % mixed nerve is named d1 here!
            end
%         end
        clear latency
        fname = [savepath_other nerve_name '_extracted_latencies.mat'];
        load(fname, 'latency')
        for ichan = 1:length(target_eng)
            if strcmp(stim_type, 'sensory')
                eng_latencies.d1{ichan}(isubject) = latency.(stim_type).d1.eng{ichan}(1);
                eng_latencies.d2{ichan}(isubject) = latency.(stim_type).d2.eng{ichan}(1);
                eng_latencies.d12{ichan}(isubject) = latency.(stim_type).d12.eng{ichan}(1);
            else
                eng_latencies.d1{ichan}(isubject) = latency.(stim_type).eng{ichan}(1); % mixed nerve is named d1 here!
            end
        end
        clear latency
    end

    if nerve == 1
        chan_names = {'CP4' 'eeg_cca' 'SC1' 'SC6' 'esg_cca' 'esg_antRef' 'EP' 'Biceps'};
    else
        chan_names = {'Cz' 'eeg_cca' 'SC3' 'L1' 'esg_cca' 'esg_antRef' 'Knee'};
    end
    if strcmp(stim_type, 'sensory')
        lat.(nerve_name(1:3)).(stim_type).(chan_names{1}) = [eeg1_latencies.d1' eeg1_latencies.d2' eeg1_latencies.d12'];
        lat.(nerve_name(1:3)).(stim_type).(chan_names{2}) = [eeg2_latencies.d1' eeg2_latencies.d2' eeg2_latencies.d12'];
        lat.(nerve_name(1:3)).(stim_type).(chan_names{3}) = [bs_latencies.d1' bs_latencies.d2' bs_latencies.d12'];
        lat.(nerve_name(1:3)).(stim_type).(chan_names{4}) = [esg1_latencies.d1' esg1_latencies.d2' esg1_latencies.d12'];
        lat.(nerve_name(1:3)).(stim_type).(chan_names{5}) = [esg2_latencies.d1' esg2_latencies.d2' esg2_latencies.d12'];
        lat.(nerve_name(1:3)).(stim_type).(chan_names{6}) = [esg3_latencies.d1' esg3_latencies.d2' esg3_latencies.d12'];
        for ichan = 1:length(target_eng)
            lat.(nerve_name(1:3)).(stim_type).(target_eng{ichan}) = [eng_latencies.d1{ichan}' eng_latencies.d2{ichan}' eng_latencies.d12{ichan}'];
        end
    else
        lat.(nerve_name(1:3)).(stim_type).(chan_names{1}) = eeg1_latencies.d1';
        lat.(nerve_name(1:3)).(stim_type).(chan_names{2}) = eeg2_latencies.d1';
        lat.(nerve_name(1:3)).(stim_type).(chan_names{3}) = bs_latencies.d1';
        lat.(nerve_name(1:3)).(stim_type).(chan_names{4}) = esg1_latencies.d1';
        lat.(nerve_name(1:3)).(stim_type).(chan_names{5}) = esg2_latencies.d1';
        lat.(nerve_name(1:3)).(stim_type).(chan_names{6}) = esg3_latencies.d1';
        for ichan = 1:length(target_eng)
            lat.(nerve_name(1:3)).(stim_type).(target_eng{ichan}) = [eng_latencies.d1{ichan}'];
        end
    end
    clear eeg1_latencies eeg2_latencies bs_latencies esg1_latencies esg2_latencies esg3_latencies eng_latencies
end
