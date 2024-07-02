function prepro_mixedLong(subject, nerve, srmr_nr)


%% set variables
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
if srmr_nr == 1
    cond_name = nerve_name(1:6);
elseif srmr_nr == 2
    cond_name = [nerve_name(1:3) '_mixed'];
end
cond_info = get_conditionInfo_byname(cond_name, srmr_nr);
trigger_name = cond_info.trigger_name;


%% load separate sensory conditions
% eeg
fname = ['epo_avgRef_cleanclean_' cond_name '.set'];
epo = pop_loadset('filename', fname, 'filepath', savepath_eeg);
proc_createMixedLong(epo, fname, savepath_eeg, trigger_name, cond_name);
clear epo fname

% eeg-cca
fname = ['epo_ccacleanclean_' cond_name '.set'];
epo = pop_loadset('filename', fname, 'filepath', savepath_eeg);
proc_createMixedLong(epo, fname, savepath_eeg, trigger_name, cond_name);
clear epo fname

% bs
fname = ['epo_bs_cleanclean_' cond_name '.set'];
if exist([savepath_bs fname], 'file')
    epo = pop_loadset('filename', fname, 'filepath', savepath_bs);
    proc_createMixedLong(epo, fname, savepath_bs, trigger_name, cond_name);
    clear epo fname
end
clear fname

% esg
fname = ['epo_cleanclean_' cond_name '.set'];
epo_esg = pop_loadset('filename', fname, 'filepath', savepath_esg);
proc_createMixedLong(epo_esg, fname, savepath_esg, trigger_name, cond_name);
clear fname

% esg - antRef
fname = ['epo_antRef_cleanclean_' cond_name '.set'];
epo_esg = pop_loadset('filename', fname, 'filepath', savepath_esg);
proc_createMixedLong(epo_esg, fname, savepath_esg, trigger_name, cond_name);
clear fname

% esg-cca
fname = ['epo_ccacleanclean_' cond_name '.set'];
epo = pop_loadset('filename', fname, 'filepath', savepath_esg);
if ~isfield(epo.epoch, 'eventnumber')
    if length(epo.epoch) == length(epo_esg.epoch)
        for ii = 1:length(epo.epoch)
            epo.epoch(ii).eventnumber = epo_esg.epoch(ii).eventnumber;
        end
    else
        disp(['epo_esg:' num2str(length(epo_esg.epoch))])
        disp(['cca_esg:' num2str(length(epo.epoch))])
        error('number of trials is not correct! ')
    end
end
proc_createMixedLong(epo, fname, savepath_esg, trigger_name, cond_name);
clear epo* fname

% eng
fname = ['eng_epocleanfilt_' cond_name '.set'];
epo = pop_loadset('filename', fname, 'filepath', savepath_other);
selected_epos = find(epo.selectedEpchs);
for ii = 1:epo.trials
    epo.epoch(ii).eventnumber = selected_epos(ii);
end
proc_createMixedLong(epo, fname, savepath_other, trigger_name, cond_name);
clear epo fname


