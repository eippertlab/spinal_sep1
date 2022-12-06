% Author: Birgit Nierula
% nierula@cbs.mpg.de

function eeg_preprocessing_loops(srmr_nr, loop_number, subjects, conditions, ...
    subject_idx, condition_idx, chan_name, display_time, iso_latency)

  


switch loop_number
    
    case 1 
        %% loop 1
        % 1) loads bids data
        % 2) selects EEG + ECG + EOG channels
        % 3) adds channel location file
        % 4) removes stimulus artifact from -1.5 to 4 ms
        % 5) downsamples to 5000 Hz (R-peak-detection sampling rate)
        % 6) adds R-peak triggers (qrs)
        % 7) saves single blocks
        % 8) downsamples to ica sampling rate (250 Hz)
        % 9) plots spectrum and log-RMS for bad channel identification (all
        % subjects in one pdf)
        % 10) saves single blocks
        for subject = subjects
            for condition = conditions
                eeg_prepro_loop1(subject, condition, srmr_nr)
            end
        end
        
        

    case 2  
        %% loop 2
        % "manual" + automatic check of suspicious datasets + check if it includes bad channels
        % mark and reject bad channels if needed   
        if srmr_nr == 1
            subj_inspect = {
%                 'sub-002', 'tibial', '1'; ...
%                 'sub-004', 'rest', '1'; ... % nothing removed
%                 'sub-004', 'alternating', '1'; ... % nothing removed
%                 'sub-004', 'alternating', '2'; ... % nothing removed
%                 'sub-008', 'alternating', '1'; ... % nothing removed
                'sub-012', 'tibial', '1'; ... % remove in block 2 channel 'C3'
                'sub-012', 'alternating', '1'; ... % remove in Block 1 channel 'C3'
                'sub-012', 'alternating', '2'; ... % remove in Block 2 channel 'C3'
%                 'sub-016', 'median', '1'; ...
%                 'sub-016', 'tibial', '1'; ...
%                 'sub-016', 'rest', '1'; ... % nothing removed
%                 'sub-016', 'alternating', '1'; ... % nothing removed
%                 'sub-016', 'alternating', '2'; ... % nothing removed
%                 'sub-017', 'alternating', '1'; ... % nothing removed
                'sub-017', 'alternating', '2'; ... % remove in block 2 channel 'Pz'
                'sub-021', 'median', '4'; ... % remove in Block 4 channel 'C5'
%                 'sub-021', 'alternating', '1'; ... % nothing removed
                'sub-023', 'median', '1'; ... % remove in Block 1&2 channel 'FT10'
                'sub-023', 'median', '2'; ... % remove in Block 1&2 channel 'FT10'
                'sub-023', 'tibial', '2'; ... % remove in Block 2 channel 'FT10'
                'sub-023', 'alternating', '1'; ... % remove in block 1 channel 'FT10'
%                 'sub-025', 'rest', '1'; ... % nothing removed
                'sub-025', 'tibial', '2'; ... % F7 removed
%                 'sub-029', 'median', '1'; ... % nothing removed
%                 'sub-029', 'tibial', '1'; ... % nothing removed
%                 'sub-032', 'tibial', '1'; ... % nothing removed
%                 'sub-033', 'rest', '1'; ... % nothing removed
%                 'sub-033', 'alternating', '1'; ... % nothing removed
%                 'sub-033', 'alternating', '2'; ... % nothing removed
                };
        elseif srmr_nr == 2
            subj_inspect = { 
%                 'S03', 'tib_digits', '4'; ... % nothing removed
                'sub-004', 'rest', '1'; ... % auto rejection: remove channel 'CP3' - bridging
                'sub-004', 'med_digits', '4'; ... % auto rejection: remove channel 'CP3' - bridging
                'sub-004', 'tib_digits', '1'; ... % auto rejection: remove channel 'CP3' - bridging
                'sub-004', 'tib_digits', '2'; ... % auto rejection: remove channel 'CP3' - bridging
                'sub-004', 'tib_digits', '3'; ... % auto rejection: remove channel 'CP3' - bridging
                'sub-004', 'tib_digits', '4'; ... % auto rejection: remove channel 'CP3' - bridging
                'sub-004', 'tib_mixed', '1'; ... % auto rejection: remove channel 'CP3' - bridging
%                 'sub-005', 'med_digits', '2'; ... % nothing removed
%                 'sub-005', 'med_digits', '4'; ... % nothing removed
                'sub-005', 'med_mixed', '1'; ...  % remove in block 1 channel 'C1'
                'sub-005', 'tib_mixed', '1'; ...  % remove in block 1 channel 'C1'
%                 'sub-009', 'med_digits', '2'; ... % nothing removed
%                 'sub-009', 'tib_digits', '3'; ... % nothing removed
%                 'sub-010', 'med_digits', '1'; ... % nothing removed
%                 'sub-010', 'med_mixed', '1'; ...  % nothing removed
%                 'sub-013', 'tib_digits', '1'; ... % nothing removed
%                 'sub-013', 'tib_digits', '2'; ... % nothing removed
                'sub-015', 'med_digits', '1'; ... % remove in block 1 Channel 'Cz'   
                'sub-015', 'med_digits', '2'; ... % remove in block 2 Channel 'Cz'   
				'sub-017', 'tib_digits', '4'; ... % first inspection: remove in block 4 Channel 'FC3' → to declare - result after auto rejection!?!?%                 'S18', 'med_mixed', '1'; ...  % nothing removed
%                 'sub-019', 'med_digits', '1'; ... % nothing removed
                'sub-021', 'med_mixed', '1'; ...  % remove in block 1 Channel 'P3'
                'sub-023', 'tib_digits', '4'; ... % auto rejection: remove in block 4 Channel 'FC2'
                };
        end
        
        make_plot = true; % plots selected channels
        
        for subject = subjects(subject_idx)
            for condition = conditions
                [cond_info] = get_conditionInfo(condition, srmr_nr);
                nblocks = cond_info.nblocks;
                for iblock = 1:nblocks
                    eeg_prepro_loop2(subj_inspect, subject, condition, iblock, srmr_nr, make_plot);
                end
            end
        end
        
        
        
    case 3  
        %% loop 3
        % 1) remove identified bad channels 
        % 2) interpolate removed channels
        for subject = subjects(subject_idx)
            for condition = conditions
                eeg_prepro_loop3(subject, condition, srmr_nr);
            end
        end
        
        
    case 4
        %% loop 4
        % 1) high pass filter at 0.5 Hz (4th order highpass digital
        % Butterworth filter)
        % 2) low pass filter at 45 Hz (4th order lowpass digital
        % Butterworth filter)
        % 3) saves data
        % 4) plots spectrum and saves it
        
        for subject = subjects(subject_idx)
            for condition = conditions(condition_idx)
                eeg_prepro_loop4(subject, condition, srmr_nr);
            end
        end
        
    case 5
        %% loop 5
        % inspect how many percent of the data got excluded - this loop
        % creates dummy variable so that other scripts work
        % in loop 4 we did not remove very bad time points before ICA (see
        % variable preICAtrim = false) because removing very bad time points
        % from data distorted the detection of heart artifacts by ICA
        blocks = eeg_prepro_loop5(subjects, conditions, srmr_nr);

        % save
        save([getenv('ANADIR') 'included_blocks.mat'], 'blocks')
        save([getenv('EEGDIR') 'included_blocks.mat'], 'blocks')
        
    case 6
        %% loop 6
        % 1) load data from loop 4
        % 2) merge all blocks from one participant
        % 3) run ICA (Infomax)
        % 4) save data
        eeg_prepro_loop6_allBlocks(subjects, conditions, srmr_nr)
        
    case 7
        %% loop 7
        % 1) load data from loop 6
        % 2) epoch data to R-peak (epoch window: -100 to 1000 ms)
        % 3) select artifact ICs using the SASICA plugin
        % 4) save selected artifact ICs sorted as eye, heart, and other
        % components
        if srmr_nr == 1
            veog_channames = {'Fp1'};
            heog_channames = {'F7' 'F8'};
        elseif srmr_nr == 2
            veog_channames = {'Fp1' 'EOGV'};
            heog_channames = {'F7' 'EOGH'};
        end
        load([getenv('ANADIR') 'included_blocks.mat'], 'blocks')
        for subject = subjects(subject_idx)
            [EEGorig, EEG, cfg] = eeg_prepro_loop7_1_allBlocks(subject, veog_channames, heog_channames);
            EEG1 = EEG;
            [EEG, cfg] = eeg_SASICA(EEG, cfg);
            sasica_comps = find(EEG.reject.gcompreject);
            % pause script until components are inspected & rejected
            disp('Press a key after rejection!')
            pause;
            disp('######')
            % save components 
            eeg_prepro_loop7_2_allBlocks(subject, sasica_comps)
            % compare raw signal with and without ICA cleaning
            check_ica_plots_allBlocks(subject, chan_name, srmr_nr, display_time)
        end
        
    case 8
        %% apply preprocessing
        sampling_rate = 1000;
        if srmr_nr == 1
            conditions = conditions(2:3);
        elseif srmr_nr == 2
            conditions = conditions(2:5);
        end
        
        for isubject = 1:length(subjects(subject_idx))
            subject = subjects(subject_idx(isubject));
            for condition = conditions
                eeg_prepro_loop8(subject, condition, srmr_nr, ...
                    sampling_rate);
            end
        end

        for isubject = 1:length(subjects)
            for condition = conditions
                [cond_info] = get_conditionInfo(condition, srmr_nr);
                cond_name = cond_info.cond_name;
                subject = subjects(isubject);
                subject_id = sprintf('sub-%03i', subject);
                fname = [getenv('EEGDIR') subject_id '/artifacts.mat'];
                load(fname, [cond_name '_artifact_info'])
                eval(['art_info = ' cond_name '_artifact_info;'])
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
            end 
        end
        % overview removed data points
        overview.colname{1} = 'subject_number';
        overview.data(:, 1) = subjects';
        save_path = getenv('EEGDIR');
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
        
    case 9
        %% get latency of max amplitude
        ref_chan = 'avgRef';
        is_eeg = true;
        for isubject = 1:length(subjects)
            subject = subjects(isubject);
            for nerve = 1:2
                tmp = prepro_loop_sepLatency(subject, nerve, srmr_nr, ...
                    ref_chan, is_eeg);
                mixednerve_latency.x(isubject, [1 nerve+1]) = [isubject tmp];
            end
        end
        mixednerve_latency.colname = {'subj_id' 'mixed_median' 'mixed_tibial'}
        fname = [getenv('EEGDIR') 'mixed_sepLatency.mat'];
        if exist(fname)
            save(fname, 'mixednerve_latency', '-append')
        else
            save(fname, 'mixednerve_latency')
        end
        
    case 10
        %% run CCA
        ref_chan = 'avgRef';
        plot_graphs = false;
        for isubject = 1:length(subjects)
            subject = subjects(isubject);
            for nerve = 1:2
                eeg_prepro_loop_calc_cca(subject, nerve, srmr_nr, ref_chan, ...
                    plot_graphs)
            end
        end
        
        for isubject = subjects
            selected_components.subject{isubject} = sprintf('sub-%03i', isubject);
            selected_components.medianus{isubject} = 1;
            selected_components.tibialis{isubject} = 1;
        end
        % in these subjects the second CCA component was selected, 
        % in all other subjects the first component was selected:
        if srmr_nr == 1
            selected_components.medianus{1} = 2;
            selected_components.medianus{11} = 2;
            selected_components.medianus{15} = 2;
            selected_components.medianus{30} = 2;
            selected_components.medianus{31} = 2;
            selected_components.tibialis{36} = 2;
        elseif srmr_nr == 2
            selected_components.medianus{1} = 2;
            selected_components.medianus{6} = 2;
            selected_components.medianus{9} = 2;
            selected_components.medianus{17} = 2;
            selected_components.medianus{19} = 2;
            selected_components.tibialis{14} = 2;
            selected_components.tibialis{17} = 2;
        end
        save([getenv('CFGDIR') 'eeg_cca_components.mat'], 'selected_components')
        
    case 11
        %% loop 11
        % SRMR1: apply CCA filters of mixed condition 
        % SRMR2: apply CCA filters of mixed condition to mixed and digit
        % conditions of the same nerve
        is_eeg = true;
        for isubject = 1:length(subjects)
            subject = subjects(isubject);
            for nerve = 1:2
                prepro_applyCCAfilters(subject, nerve, srmr_nr, is_eeg)
            end
        end
end

end