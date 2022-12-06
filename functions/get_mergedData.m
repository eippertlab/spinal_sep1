% Author: Birgit Nierula
% nierula@cbs.mpg.de

function [amp, lat, snr] = get_mergedData(condition, srmr_nr, subjects, has_allsubj)

%% set variables
loadpath_ga = getenv('GADIR');

% get condition info
[cond_info] = get_conditionInfo(condition, srmr_nr);
cond_name = cond_info.cond_name;
nerve = cond_info.nerve;
str_stimulation = cond_info.str_stimulation(2:end);
if strcmp('digits', str_stimulation)
    str_stimulation = 'sensory';
end

if nerve == 1
    nerve_name = 'medianus';
    target_eeg = 'CP4';
    target_bs = 'SC1';
    target_esg = 'SC6';
    target_eng = {'EP' 'Biceps'};
    x_lim = [-20 40];
elseif nerve == 2
    nerve_name = 'tibialis';
    target_eeg = 'Cz';
    target_bs = 'S3';
    target_esg = 'L1';
    target_eng = {'KneeM' 'Knee1' 'Knee2' 'Knee3' 'Knee4'};
    x_lim = [-20 60];
end

if strcmp('sensory', str_stimulation)
    extension_conds = {'d1' 'd2' 'd12'};
else
    extension_conds = {'m'};
end
stim_types = length(extension_conds);

%% load data
if has_allsubj
    load_fname = [loadpath_ga 'amplitudeAndLatency_allSubjects_noNaN.mat'];
else
    load_fname = [loadpath_ga 'amplitudeAndLatency_allSubjects.mat'];
end
load(load_fname, [cond_name '_values'])
eval(['values = ' cond_name '_values;'])

for istim = 1:stim_types
    amplitude = [];
    latency = [];
    snr1 = [];
    
    
    %% amplitude
    if strcmp('sensory', str_stimulation)
        tmp1 = values.amplitude.(extension_conds{istim});
    else
        tmp1 = values.amplitude.(str_stimulation);
    end
    field = fieldnames(tmp1);
    
    if nerve == 2
        if strcmp('mixed', str_stimulation)
            load(load_fname, 'name_kneemax')
            if ~exist('name_kneemax','var')
                % define channel with strongest knee potential in mixed condition
                for isubject = 1:length(subjects)
                    % find strongest knee potential
                    for iknee = 1:length(target_eng)
                        knee_idx(iknee) = find(ismember(field, target_eng{iknee}));
                        tmp_amp(iknee) = abs(nanmean(tmp1.(field{knee_idx(iknee)})(isubject,:)));
                    end
                    [~, idx_max] = max(tmp_amp);
                    name_kneemax{isubject,1} = target_eng{idx_max};
                    knee_max_amp(isubject,:) = tmp1.(name_kneemax{isubject,1})(isubject,:);                    
                end
                % save name knee max
                save(load_fname, 'name_kneemax', '-append')
            end
            for isubject = 1:length(subjects)
                knee_max_amp(isubject,:) = tmp1.(name_kneemax{isubject,1})(isubject,:);
            end
            tmp1.Knee = knee_max_amp;
            clear tmp_amp knee* field
            if has_allsubj
                field = {target_eeg 'eeg_cca' target_bs target_esg [target_esg '_antRef'] 'esg_cca' 'Knee'}';
            else
                field = {target_eeg 'eeg_cca' target_bs target_esg 'esg_cca' 'Knee'}';
            end
            
        else
            % use strongest knee potential from mixed condition
            load(load_fname, 'name_kneemax')
            for isubject = 1:length(subjects)
                knee_max_amp(isubject,:) = tmp1.(name_kneemax{isubject,1})(isubject,:);
            end
            tmp1.Knee = knee_max_amp;
            clear tmp_amp knee* field
            if has_allsubj
                field = {target_eeg 'eeg_cca' target_bs target_esg [target_esg '_antRef'] 'esg_cca' 'Knee'}';           
            else
                field = {target_eeg 'eeg_cca' target_bs target_esg  'esg_cca' 'Knee'}';           
            end
        end
    end
    
    for ifield = 1:size(field,1)
        
        amplitude = setfield(amplitude, field{ifield}, {1:length(subjects),1:2000}, nan(length(subjects),2000));
        dat = tmp1.(field{ifield});
        dims = {subjects,1:size(dat,2)};
        field_name = field{ifield};
        if size(dat,2) ~= 1 & ~isnan(nanmean(nanmean(dat,2),1))
            amplitude = setfield(amplitude, field_name, dims, dat);
        end
        
        clear dat dims field_name
    end
    clear tmp1

    if has_allsubj
        %% SNR
        if strcmp('sensory', str_stimulation)
            tmp1 = values.rms.(extension_conds{istim});
        else
            tmp1 = values.rms.(str_stimulation);
        end
        field = fieldnames(tmp1);
        
        if nerve == 2
            if strcmp('mixed', str_stimulation)
                load(load_fname, 'name_kneemax')
                for isubject = 1:length(subjects)
                    knee_max_signal(isubject,:) = tmp1.(name_kneemax{isubject,1}).signal(isubject,:);
                    knee_max_noise(isubject,:) = tmp1.(name_kneemax{isubject,1}).noise(isubject,:);
                end
                tmp1.Knee.signal = knee_max_signal;
                tmp1.Knee.noise = knee_max_noise;
                clear knee* field
                field = {target_eeg 'eeg_cca' target_bs target_esg [target_esg '_antRef'] 'esg_cca' 'Knee'}';
                    
                
            else
                % use strongest knee potential from mixed condition
                load(load_fname, 'name_kneemax')
                for isubject = 1:length(subjects)
                    knee_max_signal(isubject,:) = tmp1.(name_kneemax{isubject,1}).signal(isubject,:);
                    knee_max_noise(isubject,:) = tmp1.(name_kneemax{isubject,1}).noise(isubject,:);
                end
                tmp1.Knee.signal = knee_max_signal;
                tmp1.Knee.noise = knee_max_noise;
                clear knee* field
                field = {target_eeg 'eeg_cca' target_bs target_esg [target_esg '_antRef'] 'esg_cca' 'Knee'}';           
            end
        end
        
        for ifield = 1:size(field,1)
            
            snr1 = setfield(snr1, field{ifield}, {1:length(subjects),1}, nan(length(subjects), 1));
            dat = [tmp1.(field{ifield}).signal] ./ [tmp1.(field{ifield}).noise];
            dims = {subjects, 1:size(dat, 2)};
            field_name = field{ifield};
            if ~isnan(nanmean(dat))
                snr1 = setfield(snr1, field_name, dims, dat);
            else
                snr1 = setfield(snr1, field{ifield}, {subjects,1}, NaN);
            end
            clear dat dims field_name
        end
        clear tmp1
    end
    
    %% latency
    if strcmp('sensory', str_stimulation)
        tmp1 = values.latency.(extension_conds{istim});
    else
        tmp1 = values.latency.(str_stimulation);
    end
    
    if nerve == 2
        for isubject = 1:length(subjects)
            knee_max_amp(isubject,:) = tmp1.(name_kneemax{isubject,1})(isubject,:);
        end
        tmp1.Knee = knee_max_amp;
        clear tmp_amp knee* field
        if has_allsubj
            field = {target_eeg 'eeg_cca' target_bs target_esg [target_esg '_antRef'] 'esg_cca' 'Knee'}';
        else
            field = {target_eeg 'eeg_cca' target_bs target_esg 'esg_cca' 'Knee'}';
        end
    end
    
    for ifield = 1:length(field)
        dat = tmp1.(field{ifield});
        dims = {subjects, 1:size(dat, 2)};
        field_name = field{ifield};
        if ~isnan(nanmean(dat))
            latency = setfield(latency, field_name, dims, dat);
        else
            latency = setfield(latency, field{ifield}, {subjects,1}, NaN);
        end
    end
    
    %% assign output vars
    eval(['amp.amplitude_' extension_conds{istim} ' = amplitude;'])
    eval(['snr.snr_' extension_conds{istim} ' = snr1;'])
    eval(['lat.latency_' extension_conds{istim} ' = latency;'])
    clear amplitude latency snr1
end
