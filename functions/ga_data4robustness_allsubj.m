% Author: Birgit Nierula
% nierula@cbs.mpg.de

function ga_data4robustness_allsubj(subjects, conditions, srmr_nr)


%% reorganize matrices

% set paths
savepath_ga = getenv('GADIR');

%% =================================
%% single trial data
% Merve's data = Number of Subject x Amplitude for each trial
%% =================================
    
clearvars -except subjects conditions srmr_nr savepath_ga
for icondition = conditions
    for isubject = subjects

        %% set variables
        subject_id = sprintf('sub-%03i', isubject);
        savepath_eeg = [getenv('EEGDIR') subject_id '/'];
        savepath_bs = [getenv('ANADIR') subject_id '/bs/prepro/'];
        savepath_bs2 = [getenv('BSDIR') subject_id '/'];
        savepath_esg = [getenv('ESGDIR') subject_id '/'];
        savepath_other = [getenv('OTHERDIR') subject_id '/other/prepro/'];
        nsubjects = length(subjects);

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
            delay = 4; % sensory is 4ms later than mixed SEP
        elseif nerve == 2
            nerve_name = 'tibialis';
            target_esg = 'L1';
            delay = 7; % sensory is 7ms later than mixed SEP
        end

        for istim = 1:length(stim_name)
            %% load data
            if strcmp(stim_type, 'sensory')
                % esg
                fname = ['epo_cleanclean_' cond_name(1:3) '_' stim_name{istim} '.set'];
                epo_esg = pop_loadset('filename', fname, 'filepath', savepath_esg);
                % esg-cca
                fname = ['epo_ccacleanclean_' cond_name(1:3) '_' stim_name{istim} '.set'];
                cca_esg = pop_loadset('filename', fname, 'filepath', savepath_esg);
            else
                % esg
                fname = ['epo_cleanclean_' cond_name '.set'];
                epo_esg = pop_loadset('filename', fname, 'filepath', savepath_esg);
                % esg-cca
                fname = ['epo_ccacleanclean_' cond_name '.set'];
                cca_esg = pop_loadset('filename', fname, 'filepath', savepath_esg);
            end


            %% load latencies
            % esg
            fname = [savepath_esg nerve_name '_extracted_latencies.mat'];
            load(fname, 'latency')
            if strcmp(stim_type, 'sensory')
                esg1_potlatency = latency.sensory.(stim_name{istim}).esg;
                esg2_potlatency = latency.sensory.(stim_name{istim}).esg_cca;
                if isnan(esg1_potlatency)
                    esg1_potlatency = latency.mixed.esg + delay;
                end
                if isnan(esg2_potlatency)
                    esg2_potlatency = latency.mixed.esg_cca + delay;
                end
            else
                esg1_potlatency = latency.mixed.esg;
                esg2_potlatency = latency.mixed.esg_cca;
            end
            clear latency


            %% extract amplitude
            if ~exist('amplitudes', 'var')
                amplitudes = [];
            end

            % esg - all channels
            [eeg_chans, esg_chans, bipolar_chans] = get_channels(20, false, false, srmr_nr);
            amplitudes = get_values_allChan(epo_esg, 'esg_allChan', esg1_potlatency, ...
                cond_name, amplitudes, isubject, nsubjects, esg_chans, stim_name{istim});

            % esg - target channel
            chan_idx = find(ismember({epo_esg.chanlocs.labels}, target_esg));
            epo_esg = pop_select(epo_esg, 'channel', chan_idx);
            amplitudes = get_values_allChan(epo_esg, 'esg_target', esg1_potlatency, ...
                cond_name, amplitudes, isubject, nsubjects, {target_esg}, stim_name{istim});

            % esg - cca
            amplitudes = get_values_allChan(cca_esg, 'esg_cca', esg2_potlatency, ...
                cond_name, amplitudes, isubject, nsubjects, {cca_esg.chanlocs.labels}, stim_name{istim});
        end

    end
end

%% save
fname = [savepath_ga 'robustness_amplitude_singleTrial_allsubj.mat'];
save(fname, 'amplitudes')


end


function amplitudes = get_values_allChan(epo, epo_name, potlatency, cond_name, ...
    amplitudes, isubject, nsubjects, chan_names, stim_name)

max_trials = 2000;

if ~isempty(potlatency) & ~isnan(potlatency) 
    
    if length(potlatency) > 1
        potlatency = potlatency(1);
    end
    sample_idx = find(epo.times >= potlatency & epo.times <= potlatency);
    if size(epo.data,1) > 1
        tmp1 = squeeze(mean(epo.data(:, sample_idx, :), 2)); % channel x time x epoch
        tmp_amp = tmp1'; % epoch x channel
    else
        tmp_amp = squeeze(mean(epo.data(:, sample_idx, :), 2)); % epochs
    end
    if isubject == 1
        amplitudes.(cond_name).(stim_name).(epo_name).data(1:nsubjects, 1:max_trials, 1:length(chan_names)) = NaN; % subject x epoch x target channel
        amplitudes.(cond_name).(stim_name).(epo_name).chanNames = chan_names;
    end
    for ichan = 1:length(chan_names)
        chan_idx = find(ismember({epo.chanlocs.labels}, chan_names{ichan}));
        if ~isempty(chan_idx)
            amplitudes.(cond_name).(stim_name).(epo_name).data(isubject, 1:size(tmp_amp,1), ichan) = tmp_amp(:, chan_idx);
        end
    end
    amplitudes.(cond_name).(stim_name).(epo_name).latency(isubject, 1) = potlatency;

else
    if isubject == 1
        amplitudes.(cond_name).(stim_name).(epo_name).data(1:nsubjects, 1:max_trials, 1) = NaN; % subject x epoch x target channel
        amplitudes.(cond_name).(stim_name).(epo_name).chanNames = chan_names;
    end
    for ichan = 1:length(chan_names)
        chan_idx = find(ismember({epo.chanlocs.labels}, chan_names{ichan}));
        if ~isempty(chan_idx)
            amplitudes.(cond_name).(stim_name).(epo_name).data(isubject, 1:max_trials, ichan) = NaN;
        end
    end
    amplitudes.(cond_name).(stim_name).(epo_name).latency(isubject, 1) = NaN;
end

    
end






