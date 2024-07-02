function [cond_info] = get_conditionInfo_byname(cond_name, srmr_nr)

%% return info of the different conditions

if srmr_nr == 1
    % conditions:
    % 1 = rest,
    % 2 = median stimulation,
    % 3 = tibial stimulation,
    % 4 = alternating median and tibial stimulation
    if strcmp('rest', cond_name)
            nblocks = 1;
            nerve = [];
            stimulation = 0;
            trigger_name = [];
            str_stimulation = cond_name;
            str_nerve = [];
            condition = 1;
    elseif strcmp('median', cond_name)
            nblocks = 4;
            nerve = 1;
            stimulation = nerve;
            trigger_name = {'Median - Stimulation'};
            str_nerve = 'med';
            str_stimulation = '_mixed';
            condition = 2;
    elseif strcmp('tibial', cond_name)
            nblocks = 4;
            nerve = 2;
            stimulation = nerve;
            trigger_name = {'Tibial - Stimulation'};
            str_nerve = 'tib';
            str_stimulation = '_mixed';
            condition = 3;
    elseif strcmp('alternating', cond_name)
            nblocks = 2;
            nerve = 12;
            stimulation = 3;
            trigger_name = {'Median - Stimulation' 'Tibial - Stimulation'};
            str_nerve = 'alt';
            str_stimulation = '_mixed';
            condition = 4;
    end
    
    
elseif srmr_nr == 2
    % conditions:
    % 1 = rest,
    % 2 = median digits,
    % 3 = median mixed nerve,
    % 4 = tibial digits,
    % 5 = tibial mixed nerve
    
    if strcmp('rest', cond_name)
            nblocks = 1;
            nerve = 0;
            stimulation = 0;
            trigger_name = [];
            str_stimulation = 'rest';
            str_nerve = [];
            condition = 1;
    elseif strcmp('med_digits', cond_name)
            nblocks = 4;
            nerve = 1;
            str_nerve = 'med';
            str_stimulation = '_digits';
            condition = 2;
    elseif strcmp('med_mixed', cond_name)
            nblocks = 1;
            nerve = 1;
            str_nerve = 'med';
            str_stimulation = '_mixed';
            condition = 3;
    elseif strcmp('tib_digits', cond_name)
            nblocks = 4;
            nerve = 2;
            str_nerve = 'tib';
            str_stimulation = '_digits';
            condition = 4;
    elseif strcmp('tib_mixed', cond_name)
            nblocks = 1;
            nerve = 2;
            str_nerve = 'tib';
            str_stimulation = '_mixed';
            condition = 5;
    end
    
    if nerve > 0
        if strcmp(str_stimulation, '_mixed')
            stimulation = 1;
            trigger_name = {[str_nerve 'Mixed']};
        elseif strcmp(str_stimulation, '_digits')
            stimulation = 2;
            trigger_name = {[str_nerve '1'] [str_nerve '2'] [str_nerve '12']};
        end
    end
end

cond_info.nblocks = nblocks; 
cond_info.cond_name = cond_name;
cond_info.nerve = nerve;
cond_info.stimulation = stimulation;
cond_info.trigger_name = trigger_name;
cond_info.str_stimulation = str_stimulation;
cond_info.str_nerve = str_nerve;
cond_info.condition = condition;