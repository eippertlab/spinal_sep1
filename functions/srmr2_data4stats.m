function srmr2_data4stats(subjects, conditions, has_allsubj)

%% set variables
savepath_ga = getenv('GADIR');
srmr_nr = 2;

% setup saved variable
wide.columns = {'id' 'nerve' 'stimType' 'stimLoc' 'eeg-cca' 'brainstem' 'esg-cca' ...
    'plexus-eng' 'eng'};
wide.coding.id = {'subject-id'};
wide.coding.nerve = {'median' 'tibial'};
wide.coding.stimType = {'sensory' 'mixed'};
wide.coding.stimLoc = {'D1'  'D2'  'D1+2'  'wrist/ankle'};
wide.data = nan(length(subjects)*8, length(wide.columns));

counter = 0;
for condition = conditions
    
    % get condition info
    [cond_info] = get_conditionInfo(condition, srmr_nr);
    cond_name = cond_info.cond_name;
    nerve = cond_info.nerve;
    if nerve == 1
        nerve_name = 'medianus';
        target_chans = {'eeg_cca' '' 'esg_cca' 'EP' 'Biceps'};
    elseif nerve == 2
        nerve_name = 'tibialis';
        target_chans = {'eeg_cca' 'S3' 'esg_cca' '' 'Knee'};
    end
    str_stimulation = cond_info.str_stimulation(2:end);
    if strcmp('digits', str_stimulation)
        str_stimulation = 'sensory';
    end

    [amp, lat, ~] = get_mergedData(condition, srmr_nr, subjects, has_allsubj);

    if strcmp('sensory', str_stimulation)
        stim_types = 3;
        extension_conds = {'d1' 'd2' 'd12'};
    else
        stim_types = 1;
        extension_conds = {'m'};
    end

    for istim = 1:stim_types
        eval(['amplitude_' extension_conds{istim} ' = amp.amplitude_' extension_conds{istim} ';'])
    end
    

    for istim = 1:stim_types
        nsubjects = numel(subjects);
        idx = counter+1 : counter+nsubjects;
        % subject id
        wide.data(idx, 1) = subjects';
        % nerve
        if nerve == 1
            wide.data(idx, 2) = ones(nsubjects, 1);
        elseif nerve == 2
            wide.data(idx, 2) = ones(nsubjects, 1) + 1;
        end
        % stimType
        if strcmp(str_stimulation, 'sensory')
            wide.data(idx, 3) = ones(nsubjects, 1); % 1 = sensory
        else
            wide.data(idx, 3) = ones(nsubjects, 1) + 1; % 2 = mixed
        end
        % stim location
        if strcmp(extension_conds{istim}, 'd1')
            wide.data(idx, 4) = ones(nsubjects, 1); % 1 = d1
        elseif strcmp(extension_conds{istim}, 'd2')
            wide.data(idx, 4) = ones(nsubjects, 1) + 1; % 2 = d2
        elseif strcmp(extension_conds{istim}, 'd12')
            wide.data(idx, 4) = ones(nsubjects, 1) + 2; % 3 = d12
        elseif strcmp(extension_conds{istim}, 'm')
            wide.data(idx, 4) = ones(nsubjects, 1) + 3; % 4 = mixed (wrist or ankle)
        end


        for ichan = 1:length(target_chans)
            if ~strcmp(target_chans{ichan}, '')
                eval(['dat = amplitude_' extension_conds{istim} '.' target_chans{ichan} ';'])
                wide.data(idx, ichan+4) = nanmean(dat, 2);
            else
                wide.data(idx, ichan+4) = nan(nsubjects, 1);
            end
        end
        counter = counter + nsubjects;
    end
    
end

save([savepath_ga 'data4stats.mat'], 'wide')