% Author: Birgit Nierula
% nierula@cbs.mpg.de

function bs_preprocessing_loops(srmr_nr, loop_number, subjects, conditions)

switch loop_number
    
    case 1
        %% combine selected EEG and ESG channels
        % load cleaned EEG + ESG data
        % load excluded epochs
        % select epochs that are present in both data sets
        % combine EEG + ESG
        % select channels of interest
        for isubject = subjects
            for icondition = conditions
                bs_prepro_loop1(isubject, icondition, srmr_nr)
            end
        end
        
        
        
    case 2
        %% find peak
        % select mixed nerve conditions
        if srmr_nr == 1
            conditions = 2:3;
        elseif srmr_nr == 2
            conditions = [3 5];
        end
        
        for isubject = subjects
            for icondition = conditions
                bs_prepro_loop2(isubject, icondition, srmr_nr)
            end
        end
        
        for isubject = subjects
            counter = 1;
            for icondition = conditions
                subject_id = sprintf('sub-%03i', isubject);
                load_path = [getenv('BSDIR') subject_id '/'];
                cond_info = get_conditionInfo(icondition, srmr_nr);
                cond_name = cond_info.cond_name;
                fpath = [load_path 'potential_latency.mat'];
                if exist(fpath, 'file')
                    load(fpath, [cond_name(1:3) '_potlatency'])
                    eval(['pot_latency = ' cond_name(1:3) '_potlatency;'])
                else
                    pot_latency = NaN;
                end
                counter = counter + 1;
                mixednerve_latency.x(isubject, [1 counter]) = [isubject pot_latency];
                mixednerve_latency.colname = {'subj_id' 'mixed_median' 'mixed_tibial'};
            end
        end
        fname = [getenv('BSDIR') 'bs_mixed_sepLatency.mat'];
        if exist(fname, 'file')
            save(fname, 'mixednerve_latency', '-append')
        else
            save(fname, 'mixednerve_latency')
        end
        mixednerve_latency.colname
        mixednerve_latency.x
    case 3
        %% cca 
        % --> not working - no consistent and clear spatial patterns 
end