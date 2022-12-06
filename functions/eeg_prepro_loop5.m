% Author: Birgit Nierula
% nierula@cbs.mpg.de

function blocks = eeg_prepro_loop5(subjects, conditions, srmr_nr)

%% loop 5: inspect how many percent of the data got excluded

art_rej_all = struct();
c = 0; % dataset index
for subject = subjects
    subject_id = sprintf('SRMR%01i_S%02i', srmr_nr, subject); % this is the subject id
    analysis_path = [getenv('ANADIR') subject_id '/eeg/prepro/'];

    for condition = conditions

        % define stimulation conditions
        [cond_info] = get_conditionInfo(condition, srmr_nr);
        nblocks = cond_info.nblocks;
        cond_name = cond_info.cond_name;

        for iblock = 1:nblocks
            %load artifact information
            load([analysis_path cond_name '_' num2str(iblock) '_automatic_artifacts_beforeICA.mat'], 'rejectDataIntervals', 'badPointsInSec', 'badPointsPerc', 'params_autoclean')

            %put in overall variable
            c = c+1;
            art_rej_all(c).subj_name = subject_id;
            art_rej_all(c).stim_name = cond_name;
            art_rej_all(c).stim_block = iblock;
            art_rej_all(c).rejectDataIntervals = rejectDataIntervals;
            art_rej_all(c).badPointsInSec = badPointsInSec;
            art_rej_all(c).badPointsPerc = badPointsPerc * 100; % badPointsPerc is actually not percent but ratio (badPointsPerc/100)
            art_rej_all(c).params_autoclean = params_autoclean;
        end
    end
end

%% visualize rejected portions
ix0 = find(cellfun('isempty', {art_rej_all.badPointsPerc})); % find empty cells
for k=ix0, art_rej_all(k).badPointsPerc = 0; end % and put in 0

figure
hist([art_rej_all.badPointsPerc])
xlabel('Rejected points [%]')
ylabel('data set count')

%% save group variable
if srmr_nr == 1
    save([getenv('ANADIR') 'Auto_artifacts_all_beforeICA_part2.mat'], 'art_rej_all')
elseif srmr_nr == 2
    save([getenv('ANADIR') 'Auto_artifacts_all_beforeICA.mat'], 'art_rej_all')
end

%% display datasets with more than 10 percent rejection
threshold = 10;
disp(['##### datasets where more than ' num2str(threshold) '% of data points were removed']) 
noisy_datasets = [{art_rej_all( [art_rej_all.badPointsPerc] > threshold ).subj_name}; {art_rej_all( [art_rej_all.badPointsPerc] > threshold ).stim_name}; {art_rej_all( [art_rej_all.badPointsPerc] > threshold ).stim_block}; {art_rej_all( [art_rej_all.badPointsPerc] > threshold ).badPointsPerc}]';
disp(noisy_datasets) % 4th column contains rejection rate (Subject index, condition, block, rejection rate)


threshold = 1;
disp(['##### datasets where more than ' num2str(threshold) '% of data points were removed'])
noisy_datasets = [{art_rej_all( [art_rej_all.badPointsPerc] > threshold ).subj_name}; {art_rej_all( [art_rej_all.badPointsPerc] > threshold ).stim_name}; {art_rej_all( [art_rej_all.badPointsPerc] > threshold ).stim_block}; {art_rej_all( [art_rej_all.badPointsPerc] > threshold ).badPointsPerc}]';
disp(noisy_datasets) 


%% save variable with all blocks in all conditions and for all subjects
if srmr_nr == 1
    conditions = 1:4;
elseif srmr_nr == 2
    conditions = 1:5;
end
for subject = subjects
    for condition = conditions
        [cond_info] = get_conditionInfo(condition, srmr_nr);
        nblocks = cond_info.nblocks;
        blocks{subject}{condition} = 1:nblocks;
    end
end
% saving happens in wrapper script
