% Author: Birgit Nierula
% nierula@cbs.mpg.de

function esg_preprocessing_loops(loop_number, subjects, conditions, srmr_nr, sampling_rate)

switch loop_number
    
    case 1
        %% loop 1: prepares data
        % loads raw bids data
        % removes stimulus artifact
        % downsample to sampling rate of R-peak data
        % adds previously detected R-peak info
        % downsamples to sampling_rate
        % prepare and save variables for next step
        p = parpool(length(subjects));
        parfor isubject = 1:length(subjects)
            subject = subjects(isubject);
            for condition = conditions
                esg_prepro_loop1(subject, condition, srmr_nr, sampling_rate)
            end
        end
        delete(p)
        
        
    case 2
        %% loop 2: removes heart artifact
        p = parpool(40);
        for isubject = 1:length(subjects)
            subject = subjects(isubject);
            for condition = conditions
                esg_prepro_loop2(subject, condition, srmr_nr, sampling_rate)
            end
        end
        delete(p)
        
    case 3
        %% loop 3: checks for bad channels
        % 30 Hz highpass filter to remove remainders of heart artifact
        % checks for bad channels
        % saves figures
        for isubject = subjects
            esg_prepro_loop3(isubject, conditions, srmr_nr);
        end
        
    case 4
        %% loop 4: double check identified participants (based on figures from previous step)
        % saves for each participant if channels need to be excluded
        inspect_subjects = false;
        esg_prepro_loop4(inspect_subjects, srmr_nr);
        
    case 5
        %% loop 5: TF plots --> to make sure we select correct filtering range
        % load data from loop 2
        % cut epochs
        % set epochs to baseline
        % TF plots over all blocks of one condition
        p = parpool(length(subjects));
        parfor isubject = 1:length(subjects)
            subject = subjects(isubject);
            for condition = conditions
                esg_prepro_loop5(subject, condition, srmr_nr)
            end
        end
        delete(p)
        
    case 6
        %% loop 6: epoch data
        % load data from loop 2
        % remove bad channels
        % rereference data (3 data sets: TH6 ref, anterior ref and Fz ref)
        % filtering: bandpass: 30-400, notch: srmr1 48-52 / srmr2 comb, 4th order Butterworth filter
        % identify bad intervals (amplitudes > 100 uV) + save them
        % remove bad intervals
        % cut epochs from -200 to 700 ms
        % set epochs to baseline (-110 to -10 ms)
        for isubject = 1:length(subjects)
            subject = subjects(isubject);
            for condition = conditions
                % loop 6
                esg_prepro_loop6(subject, condition, srmr_nr);
            end
        end
        
        for isubject = 1:length(subjects)
            for condition = conditions
                [cond_info] = get_conditionInfo(condition, srmr_nr);
                cond_name = cond_info.cond_name;
                subject = subjects(isubject);
                subject_id = sprintf('sub-%03i', subject);
                fname = [getenv('ESGDIR') subject_id '/artifacts.mat'];
                load(fname, [cond_name '_artifact_info'])
                eval(['art_info =' cond_name '_artifact_info;']);
                eval([cond_name '_nepos(isubject,1) = length(find(art_info.epochincluded));'])
                eval([cond_name '_threshold(isubject) = art_info.lf_threshold;'])
                if isempty(art_info.rejectedChannels)
                    eval([cond_name '_removedChans(isubject) = 0;'])
                else
                    eval([cond_name '_removedChans(isubject) = length(art_info.rejectedChannels);'])
                end
                if isempty(art_info.rejectedSeconds)
                    art_info.rejectedSeconds = 0;
                end
                eval([cond_name '_rejectedSeconds(isubject) = art_info.rejectedSeconds;'])
                if isempty(art_info.addedBoundaries)
                    art_info.addedBoundaries = 0;
                end
                eval([cond_name '_addedBoundaries(isubject) = art_info.addedBoundaries;'])
                if isempty(art_info.rejectedPercentage)
                    art_info.rejectedPercentage = 0;
                end
                eval([cond_name '_rejectedPercentage(isubject) = art_info.rejectedPercentage;'])
                load(fname, 'bad_channels')
                if exist('bad_channels','var')
                    all_badchans{isubject,condition} = bad_channels;
                end
            end
        end
        % overview removed data points
        overview.colname{1} = 'subject_number';
        overview.data(:, 1) = subjects';
        save_path = getenv('ESGDIR');
        counter = 1;
        for icondition = 1:length(conditions)
            [cond_info] = get_conditionInfo(conditions(icondition), srmr_nr);
            cond_name = cond_info.cond_name;
            eval([cond_name '_rejectedPoints = array2table([subjects'' round(' cond_name '_threshold)'' round(' cond_name '_rejectedSeconds)'' round(' cond_name '_addedBoundaries)'' round(' cond_name '_rejectedPercentage)'' ' cond_name '_nepos], ''VariableNames'', {''subjects'' ''threshold'' ''rejectedSeconds'' ''addedBoundaries'' ''rejectedPercentage'' ''remainingEpochs''})']);
            eval([cond_name '_rejectedChans = array2table([subjects'' ' cond_name '_removedChans''], ''VariableNames'', {''subjects'' ''rjectedChannels''})']);
            if icondition == 1
                save([save_path 'tables_rejectedPoints.mat'], [cond_name '_rejectedPoints'], [cond_name '_rejectedChans'])
            else
                save([save_path 'tables_rejectedPoints.mat'], [cond_name '_rejectedPoints'], [cond_name '_rejectedChans'], '-append')
            end
            % overview remaining epochs
            counter = counter + 1;
            overview.colname{counter} = cond_name;
            eval(['overview.data(:, counter) = ' cond_name '_nepos;']);
            counter = counter + 1;
            overview.colname{counter} = [cond_name '-removedChans'];
            eval(['overview.data(:, counter) = ' cond_name '_removedChans;']);
        end
        % overview remaining epochs
        overview.colname
        overview.data
        
        
    case 7
        %% loop 7: find SEP peak latency in cleaned mixed nerve condition
        for isubject = subjects
            for nerve = 1:2
                tmp = esg_prepro_loop7_potentialLatency(isubject, nerve, srmr_nr);
                mixednerve_latency.x(isubject, [1 nerve+1]) = [isubject tmp];
            end
        end
        mixednerve_latency.colname = {'subj_id' 'mixed_median' 'mixed_tibial'}
        fname = [getenv('ESGDIR') 'mixed_sepLatency.mat'];
        if exist(fname)
            save(fname, 'mixednerve_latency', '-append')
        else
            save(fname, 'mixednerve_latency')
        end
    case 8
        %% loop 8 run CCA on mixed nerve condition
        % plot CCA filters trained on mixed nerve condition and for SRMR2
        % applied to sensory nerve condition
        for isubject = 1:length(subjects)
            subject = subjects(isubject);
            plot_graphs = true;
            for nerve = 1:2
                esg_prepro_loop8_cca(subject, nerve, srmr_nr, plot_graphs);
            end
        end
        
        for isubject = subjects
            selected_components.subject{isubject} = sprintf('sub-%03i', isubject);
            selected_components.medianus{isubject} = 1;
            selected_components.tibialis{isubject} = 1;
        end
        save([getenv('CFGDIR') 'cca_components.mat'], 'selected_components')
        
    case 9
        %% loop 9
        % apply CCA filters of mixed condition to all other conditions
        is_eeg = false;
        for isubject = 1:length(subjects)
            subject = subjects(isubject);
            for nerve = 1:2
                prepro_applyCCAfilters(subject, nerve, srmr_nr, is_eeg);
            end
        end
end

end