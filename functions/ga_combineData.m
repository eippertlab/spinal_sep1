% Author: Birgit Nierula
% nierula@cbs.mpg.de

function [out] = ga_combineData(subjects, condition, srmr_nr, is_raw, dat_level)

out = {};

% get condition info
[cond_info] = get_conditionInfo(condition, srmr_nr);
cond_name = cond_info.cond_name;
nerve = cond_info.nerve;
trigger_name = cond_info.trigger_name;
str_stimulation = cond_info.str_stimulation(2:end);
if strcmp(str_stimulation, 'digits')
    str_stimulation = 'sensory';
end

load([getenv('CFGDIR') 'cfg.mat'], 'iv_baseline')

if nerve == 1
    nerve_name = 'medianus';
elseif nerve == 2
    nerve_name = 'tibialis';
end

for iloop = 1:length(subjects)
    
    isubject = subjects(iloop);
    %% set variables
    subject_id = sprintf('sub-%03i', isubject);

    % set paths
    if ~is_raw
        if dat_level == 1 % eeg clean
                load_path = [getenv('EEGDIR') subject_id '/'];
                fname = ['epo_avgRef_cleanclean_' cond_name '.set'];
                ref = 'avg';
        elseif dat_level == 2 % eeg cca
                load_path = [getenv('EEGDIR') subject_id '/'];
                fname = ['epo_ccacleanclean_' cond_name '.set'];
                ref = 'avg';
        elseif dat_level == 3 % esg clean TH6 ref
                load_path = [getenv('ESGDIR') subject_id '/'];
                fname = ['epo_cleanclean_' cond_name '.set'];
                ref = 'TH6';
        elseif dat_level ==  4 % esg clean anterior ref
                load_path = [getenv('ESGDIR') subject_id '/'];
                fname = ['epo_antRef_cleanclean_' cond_name '.set'];
                ref = 'ant';
        elseif dat_level ==  5 % esg cca
                load_path = [getenv('ESGDIR') subject_id '/'];
                fname = ['epo_ccacleanclean_' cond_name '.set'];
                if exist([load_path fname], 'file')
                    has_ccaesg = true;
                end
                ref = 'ant';
        elseif dat_level ==  6 % brainstem
                load_path = [getenv('ANADIR') subject_id '/bs/prepro/'];
                fname = ['epo_bs_cleanclean_' cond_name '.set'];
                ref = 'FPz';
        elseif dat_level ==  7 % eng
                load_path = [getenv('OTHERDIR') subject_id '/other/prepro/'];
                fname = ['eng_filt_' cond_name '.set'];
                ref = 'bp';
        end
    end
    
    % load potential latencies
    if dat_level == 1 % eeg clean
        load_path1 = [getenv('EEGDIR') subject_id '/'];
        fname1 = [load_path1 nerve_name '_extracted_latencies.mat'];
        latency = load(fname1, 'latency');
        if strcmp(str_stimulation,'mixed')
            potlatency = latency.latency.mixed.eeg;
        elseif strcmp(str_stimulation,'sensory')
            potlatency.d1 = latency.latency.sensory.d1.eeg;
            potlatency.d2 = latency.latency.sensory.d2.eeg;
            potlatency.d12 = latency.latency.sensory.d12.eeg;
        end
    
    elseif dat_level == 2 % eeg cca
        load_path1 = [getenv('EEGDIR') subject_id '/'];
        fname1 = [load_path1 nerve_name '_extracted_latencies.mat'];
        latency = load(fname1, 'latency');
        if strcmp(str_stimulation,'mixed')
            potlatency = latency.latency.mixed.eeg_cca;
        elseif strcmp(str_stimulation,'sensory')
            potlatency.d1 = latency.latency.sensory.d1.eeg_cca;
            potlatency.d2 = latency.latency.sensory.d2.eeg_cca;
            potlatency.d12 = latency.latency.sensory.d12.eeg_cca;
        end
    
    elseif dat_level == 3 % esg clean TH6 ref
        load_path1 = [getenv('ESGDIR') subject_id '/'];
        fname1 = [load_path1 nerve_name '_extracted_latencies.mat'];
        latency = load(fname1, 'latency');
        if strcmp(str_stimulation,'mixed')
            potlatency = latency.latency.mixed.esg;
        elseif strcmp(str_stimulation,'sensory')
            potlatency.d1 = latency.latency.sensory.d1.esg;
            potlatency.d2 = latency.latency.sensory.d2.esg;
            potlatency.d12 = latency.latency.sensory.d12.esg;
        end
    
    elseif dat_level ==  4 % esg clean anterior ref
        load_path1 = [getenv('ESGDIR') subject_id '/'];
        fname1 = [load_path1 nerve_name '_extracted_latencies.mat'];
        latency = load(fname1, 'latency');
        if strcmp(str_stimulation,'mixed')
            potlatency = latency.latency.mixed.esg;
        elseif strcmp(str_stimulation,'sensory')
            potlatency.d1 = latency.latency.sensory.d1.esg;
            potlatency.d2 = latency.latency.sensory.d2.esg;
            potlatency.d12 = latency.latency.sensory.d12.esg;
        end
    
    elseif dat_level ==  5 % esg cca
        load_path1 = [getenv('ESGDIR') subject_id '/'];
        fname1 = [load_path1 nerve_name '_extracted_latencies.mat'];
        latency = load(fname1, 'latency');
        if has_ccaesg
            if strcmp(str_stimulation,'mixed')
                potlatency = latency.latency.mixed.esg_cca;
            elseif strcmp(str_stimulation,'sensory')
                potlatency.d1 = latency.latency.sensory.d1.esg_cca;
                potlatency.d2 = latency.latency.sensory.d2.esg_cca;
                potlatency.d12 = latency.latency.sensory.d12.esg_cca;
            end
        end
    
    elseif dat_level ==  6 % brainstem
        load_path1 = [getenv('BSDIR') subject_id '/'];
        fname1 = [load_path1 nerve_name '_extracted_latencies.mat'];
        latency = load(fname1, 'latency');
        if strcmp(str_stimulation,'mixed')
            potlatency = latency.latency.mixed.bs;
        elseif strcmp(str_stimulation,'sensory')
            potlatency.d1 = latency.latency.sensory.d1.bs;
            potlatency.d2 = latency.latency.sensory.d2.bs;
            potlatency.d12 = latency.latency.sensory.d12.bs;
        end
    
    elseif dat_level ==  7 % eng
        load_path1 = [getenv('OTHERDIR') subject_id '/other/prepro/'];
        fname1 = [load_path1 nerve_name '_extracted_latencies.mat'];
        latency = load(fname1, 'latency');
        if strcmp(str_stimulation,'mixed')
            potlatency = latency.latency.mixed.eng(1);
        elseif strcmp(str_stimulation,'sensory')
            potlatency.d1 = latency.latency.sensory.d1.eng{1};
            potlatency.d2 = latency.latency.sensory.d2.eng{1};
            potlatency.d12 = latency.latency.sensory.d12.eng{1};
        end
    end

    
    %% load data
    if exist([load_path fname],'file')
        epo = pop_loadset('filename', fname, 'filepath', load_path);
        epo.ref = ref;
        has_data = true;
        % remove reference channel  from data
        if strcmp(epo.ref,'ant') || strcmp(epo.ref,'TH6')
            if strcmp(epo.ref,'ant')
                if nerve == 1
                    ref_name = 'AC';
                elseif nerve == 2
                    ref_name = 'AL';
                end
            else
                ref_name = epo.ref;
            end
            chan_idx = find(ismember({epo.chanlocs.labels}, ref_name));
            epo = pop_select(epo, 'nochannel', chan_idx);
        end
    else
        epo.data = [];
        has_data = false;
    end
    if dat_level ==  10
        epo.data = abs(epo.data);
    end
    
    %% separate digit conditions
    if strcmp(str_stimulation, 'sensory')
        max_events = 3 * 2000;
        % logical array with events
        if isfield(epo.epoch, 'eventnumber')
            events = zeros(1, max_events);
            has_eventnumber = true;
        else
            events = ones(1,max_events);
            has_eventnumber = false;
            if length(epo.epoch) < max_events
                events(length(epo.epoch)+1:end) = 0;
            end
        end
        
        for itrial = 1:epo.trials
            % find correct trigger postition
            stim_idx = find([epo.epoch(itrial).eventlatency{:}] == 0);
            if length(stim_idx) > 1
                tmp_idx = find(ismember({ epo.epoch(itrial).eventtype{stim_idx} }, trigger_name));
                stim_idx = stim_idx(tmp_idx);
            end
            % make logical array for each trigger name
            if strcmp(epo.epoch(itrial).eventtype{stim_idx}, trigger_name{1})
                epo_logical1(itrial) = 1;
            elseif strcmp(epo.epoch(itrial).eventtype{stim_idx}, trigger_name{2})
                epo_logical2(itrial) = 1;
            elseif strcmp(epo.epoch(itrial).eventtype{stim_idx}, trigger_name{3})
                epo_logical12(itrial) = 1;
            end
            % logical array with events
            if has_eventnumber
                try
                    events(1, epo.epoch(itrial).eventnumber{stim_idx}) = 1;
                catch
                    events(1, epo.epoch(itrial).eventnumber) = 1;
                end
            end
        end
        event_idx = find(events);
        
        idx1 = event_idx(find(epo_logical1));
        epo1 = pop_select(epo, 'trial', find(epo_logical1));
        epo1 = pop_rmbase(epo1, iv_baseline);
        epo1.potLatency = potlatency.d1;
        
        idx2 = event_idx(find(epo_logical2));
        epo2 = pop_select(epo, 'trial', find(epo_logical2));
        epo2 = pop_rmbase(epo2, iv_baseline);
        epo2.potLatency = potlatency.d2;
        
        idx12 = event_idx(find(epo_logical12));
        epo12 = pop_select(epo, 'trial', find(epo_logical12));
        epo12 = pop_rmbase(epo12, iv_baseline);
        epo12.potLatency = potlatency.d12;
        
        clear epo_logical*
    else
        epo.potLatency = potlatency;
    end
            
    
    %% add to cell
    if has_data
        if strcmp(str_stimulation, 'sensory')
            out{iloop, 1} = epo1;
            out{iloop, 2} = epo2;
            out{iloop, 3} = epo12;
        else
            out{iloop, 1} = epo;
        end
    else
        out{iloop, 1} = [];
    end
end

end


