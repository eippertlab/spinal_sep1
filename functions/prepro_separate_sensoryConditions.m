function prepro_separate_sensoryConditions(subject, nerve)


%% set variables
srmr_nr = 2;
subject_id = sprintf('sub-%03i', subject);
savepath_eeg = [getenv('EEGDIR') subject_id '/'];
savepath_bs = [getenv('ANADIR') subject_id '/bs/prepro/'];
savepath_esg = [getenv('ESGDIR') subject_id '/'];
savepath_other = [getenv('OTHERDIR') subject_id '/other/prepro/'];
cfg_path = getenv('CFGDIR');


%% get condition info
if nerve == 1
    nerve_name = 'medianus';
elseif nerve == 2
    nerve_name = 'tibialis';
end
cond_name = [nerve_name(1:3) '_digits'];
cond_info = get_conditionInfo_byname(cond_name, srmr_nr);
trigger_name = cond_info.trigger_name;


%% load separate sensory conditions
% eeg
fname = ['epo_avgRef_cleanclean_' cond_name '.set'];
epo = pop_loadset('filename', fname, 'filepath', savepath_eeg);
proc_separateDigits(epo, fname, savepath_eeg, trigger_name);
clear epo fname

% eeg-cca
fname = ['epo_ccacleanclean_' cond_name '.set'];
epo = pop_loadset('filename', fname, 'filepath', savepath_eeg);
proc_separateDigits(epo, fname, savepath_eeg, trigger_name);
clear epo fname

% bs
fname = ['epo_bs_cleanclean_' cond_name '.set'];
if exist([savepath_bs fname], 'file')
    epo = pop_loadset('filename', fname, 'filepath', savepath_bs);
    proc_separateDigits(epo, fname, savepath_bs, trigger_name);
    clear epo fname
end
clear fname

% esg
fname = ['epo_cleanclean_' cond_name '.set'];
epo_esg1 = pop_loadset('filename', fname, 'filepath', savepath_esg);
proc_separateDigits(epo_esg1, fname, savepath_esg, trigger_name);
clear fname

% esg antRef
fname = ['epo_antRef_cleanclean_' cond_name '.set'];
epo_esg2 = pop_loadset('filename', fname, 'filepath', savepath_esg);
proc_separateDigits(epo_esg2, fname, savepath_esg, trigger_name);
clear fname

% esg-cca
fname = ['epo_ccacleanclean_' cond_name '.set'];
epo = pop_loadset('filename', fname, 'filepath', savepath_esg);
if ~isfield(epo.epoch, 'eventnumber')
    if length(epo.epoch) == length(epo_esg1.epoch)
        for ii = 1:length(epo.epoch)
            epo.epoch(ii).eventnumber = epo_esg1.epoch(ii).eventnumber;
        end
    else
        disp(['epo_esg:' num2str(length(epo_esg1.epoch))])
        disp(['cca_esg:' num2str(length(epo.epoch))])
        error('number of trials is not correct! ')
    end
end
proc_separateDigits(epo, fname, savepath_esg, trigger_name);
clear epo* fname

% eng
fname = ['eng_epocleanfilt_' cond_name '.set'];
epo = pop_loadset('filename', fname, 'filepath', savepath_other);
selected_epos = find(epo.selectedEpchs);
for ii = 1:epo.trials
    epo.epoch(ii).eventnumber = selected_epos(ii);
end
proc_separateDigits(epo, fname, savepath_other, trigger_name);
clear epo fname


