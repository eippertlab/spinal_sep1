% Author: Birgit Nierula
% nierula@cbs.mpg.de

function other_preprocessing_loops(srmr_nr, loop_number, subjects, conditions, sampling_rate)

switch loop_number
    
    case 1
        %% separate ENG channels
        % load data
        % select ENG channels 
        % bandpass + notch filter
        % save
        for isubject = subjects
            for icondition = conditions
                other_prepro_loop1(isubject, icondition, srmr_nr, sampling_rate)
            end
        end
        
        
    case 3
        %% find peak latencies
        for isubject = subjects
            for icondition = conditions
                other_prepro_findpeak(isubject, icondition, srmr_nr)
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
        fname = [getenv('OTHERDIR') 'other_mixed_sepLatency.mat'];
        if exist(fname, 'file')
            save(fname, 'mixednerve_latency', '-append')
        else
            save(fname, 'mixednerve_latency')
        end
        mixednerve_latency.colname
        mixednerve_latency.x


end