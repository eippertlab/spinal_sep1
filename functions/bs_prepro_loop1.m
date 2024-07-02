% Author: Birgit Nierula
% nierula@cbs.mpg.de

function bs_prepro_loop1(isubject, icondition, srmr_nr)

%% combines selected EEG and ESG channels to one data structure

%% set variables
subject_id = sprintf('sub-%03i', isubject);
load_eegpath = [getenv('EEGDIR') subject_id '/'];
load_esgpath = [getenv('ESGDIR') subject_id '/'];
analysis_path = [getenv('ANADIR') subject_id '/bs/prepro/'];
if ~exist(analysis_path,'dir'); mkdir(analysis_path); end

% get condition info
cond_info = get_conditionInfo(icondition, srmr_nr);
cond_name = cond_info.cond_name;
nstimuli = sum(cond_info.nstimuli);
trigger_name = cond_info.trigger_name;


%% load data cleaned EEG + ESG data
fname = ['epo_avgRef_cleanclean_' cond_name '.set'];
epo_eeg = pop_loadset('filename', fname, 'filepath', load_eegpath);
fname = ['epo_cleanclean_' cond_name '.set'];
epo_esg = pop_loadset('filename', fname, 'filepath', load_esgpath);
    

%% get excluded epochs
eeg_epoincluded = zeros(1, nstimuli);
eeg_epoincluded = get_includedEpochs(epo_eeg, eeg_epoincluded, trigger_name);
esg_epoincluded = zeros(1, nstimuli);
esg_epoincluded = get_includedEpochs(epo_esg, esg_epoincluded, trigger_name);

%% select epochs that are present in both data sets
both_idx = find(sum([eeg_epoincluded; esg_epoincluded]) == 2);
tmp_eeg = eeg_epoincluded; tmp_eeg(both_idx) = 2;
tmp_esg = esg_epoincluded; tmp_esg(both_idx) = 2;
non0eeg_idx = find(tmp_eeg); non0_eeg = tmp_eeg(non0eeg_idx);
non0esg_idx = find(tmp_esg); non0_esg = tmp_esg(non0esg_idx);
bothidx_eeg = find(non0_eeg == 2);
bothidx_esg = find(non0_esg == 2);

epo_eeg = pop_select(epo_eeg, 'trial', bothidx_eeg);
epo_esg = pop_select(epo_esg, 'trial', bothidx_esg);

%% combine EEG + ESG
%% rereference to Fz
has_fz = false;
fz_idx = find(ismember({epo_eeg.chanlocs.labels}, 'Fz'));
if ~isempty(fz_idx)
    epo_eeg = pop_reref(epo_eeg, fz_idx);
    has_fz = true;
else
    disp('participant has no Fz channel in cortical setup')
end
fz_idx = find(ismember({epo_esg.chanlocs.labels}, 'Fz-TH6'));
if ~isempty(fz_idx)
    epo_esg = pop_reref(epo_esg, fz_idx);
else
    has_fz = false;
    disp('participant has no Fz-TH6 channel in spinal setup')
end

if has_fz
    %% combine to one structure
    epo = epo_eeg;
    epo.nbchan = epo_eeg.nbchan + epo_esg.nbchan;
    for ii = epo_eeg.nbchan+1 : epo.nbchan; epo.chanlocs(ii).labels = {}; end
    for ii = 1:epo_esg.nbchan
        chanlocs(ii).labels = epo_esg.chanlocs(ii).labels;
        chanlocs(ii).ref = epo_esg.chanlocs(ii).ref;
        chanlocs(ii).theta = epo_esg.chanlocs(ii).theta;
        chanlocs(ii).radius = epo_esg.chanlocs(ii).radius;
        chanlocs(ii).X = epo_esg.chanlocs(ii).X;
        chanlocs(ii).Y = epo_esg.chanlocs(ii).Y;
        chanlocs(ii).Z = epo_esg.chanlocs(ii).Z;
        chanlocs(ii).sph_theta = epo_esg.chanlocs(ii).sph_theta;
        chanlocs(ii).sph_phi = epo_esg.chanlocs(ii).sph_phi;
        chanlocs(ii).sph_radius = epo_esg.chanlocs(ii).sph_radius;
        chanlocs(ii).type = epo_esg.chanlocs(ii).type;
        chanlocs(ii).urchan = epo_esg.chanlocs(ii).urchan;
    end
    epo.chanlocs(epo_eeg.nbchan+1 : epo_eeg.nbchan+epo_esg.nbchan) = chanlocs;
    epo.data(epo_eeg.nbchan+1 : epo_eeg.nbchan+epo_esg.nbchan, :, :) = epo_esg.data;
    epo = eeg_checkset(epo)
    
    %% rereference to Fpz or Fp1/Fp2
    has_fpz = false;
    if srmr_nr == 1
        ref_chan = 'FPz';
    elseif srmr_nr == 2
        ref_chan = {'Fp1' 'Fp2'};
    end
    fpz_idx = find(ismember({epo_eeg.chanlocs.labels}, ref_chan));
    if ~isempty(fpz_idx)
        epo_eeg = pop_reref(epo_eeg, fpz_idx);
        has_fpz = true;
    else
        disp('participant has no Fz channel in cortical setup')
    end
    
    if has_fpz
        %% select channels
        [brainstem_chans, ~, ~, ~] = get_esg_channels();
        bs_chans = [brainstem_chans {'S3' 'S5' 'S6' 'S7' 'S9' 'SC6' 'S11' 'AC'} {'O1' 'O2' 'PO3' 'PO4' 'PO7' 'PO8' 'LM' 'RM'}];
        bs_idx = find(ismember({epo.chanlocs.labels}, bs_chans));
        epo = pop_select(epo, 'channel', bs_idx);


        %% save
        fname = ['epo_bs_cleanclean_' cond_name '.set'];
        epo = pop_saveset(epo, 'filename', fname, 'filepath', analysis_path);
    end
end

end

function epo_included = get_includedEpochs(epo, epo_included, trigger_name)

for ii = 1:length(epo.epoch)
    idx = find(ismember(epo.epoch(ii).eventtype, trigger_name));
    if ~isempty(idx)
        if iscell(epo.epoch(ii).eventnumber)
            stim_number = epo.epoch(ii).eventnumber{idx};
        else
            stim_number = epo.epoch(ii).eventnumber(idx);
        end
        epo_included(stim_number(1)) = 1;
    end
end

end