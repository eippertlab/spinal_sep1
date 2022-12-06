% Author: Birgit Nierula
% nierula@cbs.mpg.de

function prepro_extractSepParameters(subject, nerve, srmr_nr)


%% set variables
subject_id = sprintf('sub-%03i', subject);
savepath_eeg = [getenv('EEGDIR') subject_id '/'];
savepath_bs = [getenv('ANADIR') subject_id '/bs/prepro/'];
savepath_bs2 = [getenv('BSDIR') subject_id '/'];
savepath_esg = [getenv('ESGDIR') subject_id '/'];
savepath_other = [getenv('OTHERDIR') subject_id '/other/prepro/'];

% get condition info
if nerve == 1
    nerve_name = 'medianus';
    target_eeg = 'CP4';
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
if srmr_nr == 1
    cond_name = nerve_name(1:end-2);
elseif srmr_nr == 2
    cond_name = [nerve_name(1:3) '_mixed'];
    cond_name_d1 = [nerve_name(1:3) '_d1']; 
    cond_name_d2 = [nerve_name(1:3) '_d2'];
    cond_name_d12 = [nerve_name(1:3) '_d12'];
end

%% load data
% eeg
fname = ['epo_avgRef_cleanclean_' cond_name '.set'];
epo_eeg = pop_loadset('filename', fname, 'filepath', savepath_eeg);

% eeg-cca
fname = ['epo_ccacleanclean_' cond_name '.set'];
cca_eeg = pop_loadset('filename', fname, 'filepath', savepath_eeg);

% bs
fname = ['epo_bs_cleanclean_' cond_name '.set'];
if exist([savepath_bs fname], 'file') && nerve == 2
    epo_bs = pop_loadset('filename', fname, 'filepath', savepath_bs);
    has_bs = true;
else
    has_bs = false;
end

% esg
fname = ['epo_cleanclean_' cond_name '.set'];
epo_esg = pop_loadset('filename', fname, 'filepath', savepath_esg);

% esg-cca
fname = ['epo_ccacleanclean_' cond_name '.set'];
cca_esg = pop_loadset('filename', fname, 'filepath', savepath_esg);

% eng
fname = ['eng_filt_' cond_name '.set'];
epo_eng = pop_loadset('filename', fname, 'filepath', savepath_other);

if srmr_nr == 2
    % load digit data
    % eeg
    fname = ['epo_avgRef_cleanclean_' cond_name_d1 '.set'];
    epo_eeg_d1 = pop_loadset('filename', fname, 'filepath', savepath_eeg);
    fname = ['epo_avgRef_cleanclean_' cond_name_d2 '.set'];
    epo_eeg_d2 = pop_loadset('filename', fname, 'filepath', savepath_eeg);
    fname = ['epo_avgRef_cleanclean_' cond_name_d12 '.set'];
    epo_eeg_d12 = pop_loadset('filename', fname, 'filepath', savepath_eeg);
    
    % eeg-cca
    fname = ['epo_ccacleanclean_' cond_name_d1 '.set'];
    cca_eeg_d1 = pop_loadset('filename', fname, 'filepath', savepath_eeg);
    fname = ['epo_ccacleanclean_' cond_name_d2 '.set'];
    cca_eeg_d2 = pop_loadset('filename', fname, 'filepath', savepath_eeg);
    fname = ['epo_ccacleanclean_' cond_name_d12 '.set'];
    cca_eeg_d12 = pop_loadset('filename', fname, 'filepath', savepath_eeg);
    
    % bs
    fname = ['epo_bs_cleanclean_' cond_name_d1 '.set'];
    if has_bs && exist([savepath_bs fname], 'file')
        epo_bs_d1 = pop_loadset('filename', fname, 'filepath', savepath_bs);
        fname = ['epo_bs_cleanclean_' cond_name_d2 '.set'];
        epo_bs_d2 = pop_loadset('filename', fname, 'filepath', savepath_bs);
        fname = ['epo_bs_cleanclean_' cond_name_d12 '.set'];
        epo_bs_d12 = pop_loadset('filename', fname, 'filepath', savepath_bs);
        has_bs2 = true;
    else
        has_bs2 = false;
    end
    
    % esg
    fname = ['epo_cleanclean_' cond_name_d1 '.set'];
    epo_esg_d1 = pop_loadset('filename', fname, 'filepath', savepath_esg);
    fname = ['epo_cleanclean_' cond_name_d2 '.set'];
    epo_esg_d2 = pop_loadset('filename', fname, 'filepath', savepath_esg);
    fname = ['epo_cleanclean_' cond_name_d12 '.set'];
    epo_esg_d12 = pop_loadset('filename', fname, 'filepath', savepath_esg);
    
    % esg-cca
    fname = ['epo_ccacleanclean_' cond_name_d1 '.set'];
    cca_esg_d1 = pop_loadset('filename', fname, 'filepath', savepath_esg);
    fname = ['epo_ccacleanclean_' cond_name_d2 '.set'];
    cca_esg_d2 = pop_loadset('filename', fname, 'filepath', savepath_esg);
    fname = ['epo_ccacleanclean_' cond_name_d12 '.set'];
    cca_esg_d12 = pop_loadset('filename', fname, 'filepath', savepath_esg);
    
    % eng
    fname = ['eng_filt_' cond_name_d1 '.set'];
    epo_eng_d1 = pop_loadset('filename', fname, 'filepath', savepath_other);
    fname = ['eng_filt_' cond_name_d2 '.set'];
    epo_eng_d2 = pop_loadset('filename', fname, 'filepath', savepath_other);
    fname = ['eng_filt_' cond_name_d12 '.set'];
    epo_eng_d12 = pop_loadset('filename', fname, 'filepath', savepath_other);

end


%% load mixed nerve potential latency
% eeg
fname = [savepath_eeg 'potential_latency.mat'];
load(fname, [nerve_name(1:3) '_potlatency'])
eval(['eeg_potlatency = ' nerve_name(1:3) '_potlatency;']);
eval(['clear ' nerve_name(1:3) '_potlatency']);

% bs
if has_bs
    fname = [savepath_bs2 'potential_latency.mat'];
    load(fname, [nerve_name(1:3) '_potlatency'])
    eval(['bs_potlatency = ' nerve_name(1:3) '_potlatency;']);
    eval(['clear ' nerve_name(1:3) '_potlatency']);
end

% esg
fname = [savepath_esg 'potential_latency.mat'];
load(fname, [nerve_name(1:3) '_potlatency'])
eval(['esg_potlatency = ' nerve_name(1:3) '_potlatency;']);
eval(['clear ' nerve_name(1:3) '_potlatency']);

% other
fname = [savepath_other 'other_potential_latency.mat'];
load(fname, [cond_name '_potlatency'])
eval(['other_potlatency = ' cond_name '_potlatency;']);
eval(['clear ' cond_name '_potlatency']);

%% check if latency file exists already and load latencies
% eeg
fname = [savepath_eeg nerve_name '_extracted_latencies.mat'];
if exist(fname, 'file')
    load(fname, 'latency')
    eeg1_potlatency = latency.mixed.eeg;
    eeg2_potlatency = latency.mixed.eeg_cca;
    if srmr_nr == 2
        if isfield(latency.sensory,'d1')
            eeg1_potlatency_d1 = latency.sensory.d1.eeg;
            eeg1_potlatency_d2 = latency.sensory.d2.eeg;
            eeg1_potlatency_d12 = latency.sensory.d12.eeg;
            eeg2_potlatency_d1 = latency.sensory.d1.eeg_cca;
            eeg2_potlatency_d2 = latency.sensory.d2.eeg_cca;
            eeg2_potlatency_d12  = latency.sensory.d12.eeg_cca;
        else
            eeg1_potlatency_d1 = latency.sensory.eeg;
            eeg1_potlatency_d2 = latency.sensory.eeg;
            eeg1_potlatency_d12 = latency.sensory.eeg;
            eeg2_potlatency_d1 = latency.sensory.eeg_cca;
            eeg2_potlatency_d2 = latency.sensory.eeg_cca;
            eeg2_potlatency_d12  = latency.sensory.eeg_cca;
        end
    end
    clear latency
else
    eeg1_potlatency = [];
    eeg2_potlatency = [];
    if srmr_nr == 2
        eeg1_potlatency_d1 = [];
        eeg1_potlatency_d2 = [];
        eeg1_potlatency_d12 = [];
        eeg2_potlatency_d1 = [];
        eeg2_potlatency_d2 = [];
        eeg2_potlatency_d12  = [];
    end
end

% bs
fname = [savepath_bs2 nerve_name '_extracted_latencies.mat'];
if exist(fname, 'file')
    load(fname, 'latency')
    bs1_potlatency = latency.mixed.bs;
    if srmr_nr == 2
        if isfield(latency.sensory,'d1')
            bs1_potlatency_d1 = latency.sensory.d1.bs;
            bs1_potlatency_d2 = latency.sensory.d2.bs;
            bs1_potlatency_d12 = latency.sensory.d12.bs;
        else
            bs1_potlatency_d1 = latency.sensory.bs;
            bs1_potlatency_d2 = latency.sensory.bs;
            bs1_potlatency_d12 = latency.sensory.bs;
        end
    end
    clear latency
else
    bs1_potlatency = [];
    if srmr_nr == 2
        bs1_potlatency_d1 = [];
        bs1_potlatency_d2 = [];
        bs1_potlatency_d12 = [];
    end
end

% esg
fname = [savepath_esg nerve_name '_extracted_latencies.mat'];
if exist(fname, 'file')
    load(fname, 'latency')
    esg1_potlatency = latency.mixed.esg;
    esg2_potlatency = latency.mixed.esg_cca;
    if srmr_nr == 2
        if isfield(latency.sensory,'d1')
            esg1_potlatency_d1 = latency.sensory.d1.esg;
            esg1_potlatency_d2 = latency.sensory.d2.esg;
            esg1_potlatency_d12 = latency.sensory.d12.esg;
            esg2_potlatency_d1 = latency.sensory.d1.esg_cca;
            esg2_potlatency_d2 = latency.sensory.d2.esg_cca;
            esg2_potlatency_d12 = latency.sensory.d12.esg_cca;
        else
            esg1_potlatency_d1 = latency.sensory.esg;
            esg1_potlatency_d2 = latency.sensory.esg;
            esg1_potlatency_d12 = latency.sensory.esg;
            esg2_potlatency_d1 = latency.sensory.esg_cca;
            esg2_potlatency_d2 = latency.sensory.esg_cca;
            esg2_potlatency_d12 = latency.sensory.esg_cca;
        end
    end
    clear latency
else
    esg1_potlatency = [];
    esg2_potlatency = [];
    if srmr_nr == 2
        esg1_potlatency_d1 = [];
        esg1_potlatency_d2 = [];
        esg1_potlatency_d12 = [];
        esg2_potlatency_d1 = [];
        esg2_potlatency_d2 = [];
        esg2_potlatency_d12 = [];
    end
    clear latency
end

% eng
fname = [savepath_other nerve_name '_extracted_latencies.mat'];
if exist(fname, 'file')
    load(fname, 'latency')
    eng1_potlatency = latency.mixed.eng;
    if srmr_nr == 2
        if isfield(latency.sensory,'d1')
            eng1_potlatency_d1 = latency.sensory.d1.eng;
            eng1_potlatency_d2 = latency.sensory.d2.eng;
            eng1_potlatency_d12 = latency.sensory.d12.eng;
        else
            eng1_potlatency_d1 = latency.sensory.eng;
            eng1_potlatency_d2 = latency.sensory.eng;
            eng1_potlatency_d12 = latency.sensory.eng;
        end
    end
    clear latency
else
    eng1_potlatency = [];
    if srmr_nr == 2
        eng1_potlatency_d1 = [];
        eng1_potlatency_d2 = [];
        eng1_potlatency_d12 = [];
    end
end



%% plot mixed signal
f1 = figure('Units','normalized','Position',[0 0 0.5 1]);
is_digit = false;
is_eng = false;
% eeg
sp1 = subplot(5, 1, 1); 
eeg1_potlatency = plot_traces(sp1, epo_eeg, target_eeg, x_lim, false, eeg_potlatency, is_digit, is_eng, true, nerve, eeg1_potlatency);

% eeg - cca
sp2 = subplot(5, 1, 2); 
eeg2_potlatency = plot_traces(sp2, cca_eeg, cca_eeg.chanlocs.labels, x_lim, true, eeg_potlatency, is_digit, is_eng, true, nerve, eeg2_potlatency);

% bs
if has_bs
    sp3 = subplot(5, 1, 3); 
    bs1_potlatency = plot_traces(sp3, epo_bs, target_bs, x_lim, false, bs_potlatency, is_digit, is_eng, false, nerve, bs1_potlatency);
end

% esg
sp4 = subplot(5, 1, 4); 
esg1_potlatency = plot_traces(sp4, epo_esg, target_esg, x_lim, false, esg_potlatency, is_digit, is_eng, false, nerve, esg1_potlatency);

% esg - cca
sp5 = subplot(5, 1, 5); 
esg2_potlatency = plot_traces(sp5, cca_esg, cca_esg.chanlocs.labels, x_lim, true, esg_potlatency, is_digit, is_eng, false, nerve, esg2_potlatency);

% eng
f2 = figure('Units','normalized','Position',[0 0 0.5 1]);
chan_counter = 0;
for iplot = 6:6+length(target_eng)-1
    chan_counter = chan_counter + 1;
    is_eng = true;
    str_plot = num2str(iplot);
    eval(['sp' str_plot ' = subplot(5, 1, chan_counter);'])
    eval(['eng1_potlatency{chan_counter} = plot_traces(sp' str_plot ', epo_eng, target_eng{chan_counter}, x_lim, true, other_potlatency.' target_eng{chan_counter} ', is_digit, is_eng, false, nerve, eng1_potlatency{chan_counter});'])
end


%% plot sensory signal
if srmr_nr == 2
    is_digit = true;
    is_eng = false;
    % eeg
    figure(f1)
    eeg1_potlatency_d12 = plot_traces(sp1, epo_eeg_d12, target_eeg, x_lim, false, eeg_potlatency, is_digit, is_eng, true, nerve, eeg1_potlatency_d12);    
    eeg1_potlatency_d1 = plot_traces(sp1, epo_eeg_d1, target_eeg, x_lim, false, eeg_potlatency, is_digit, is_eng, true, nerve, eeg1_potlatency_d1);
    eeg1_potlatency_d2 = plot_traces(sp1, epo_eeg_d2, target_eeg, x_lim, false, eeg_potlatency, is_digit, is_eng, true, nerve, eeg1_potlatency_d2);
    
    
    % eeg - cca
    figure(f1)
    eeg2_potlatency_d12 = plot_traces(sp2, cca_eeg_d12, cca_eeg_d12.chanlocs.labels, x_lim, true, eeg_potlatency, is_digit, is_eng, true, nerve, eeg2_potlatency_d12);
    eeg2_potlatency_d1 = plot_traces(sp2, cca_eeg_d1, cca_eeg_d1.chanlocs.labels, x_lim, true, eeg_potlatency, is_digit, is_eng, true, nerve, eeg2_potlatency_d1);
    eeg2_potlatency_d2 = plot_traces(sp2, cca_eeg_d2, cca_eeg_d2.chanlocs.labels, x_lim, true, eeg_potlatency, is_digit, is_eng, true, nerve, eeg2_potlatency_d2);
    
    
    % bs
    if has_bs2
        figure(f1)
        bs1_potlatency_d12 = plot_traces(sp3, epo_bs_d12, target_bs, x_lim, false, bs_potlatency, is_digit, is_eng, false, nerve, bs1_potlatency_d12);
        bs1_potlatency_d1 = plot_traces(sp3, epo_bs_d1, target_bs, x_lim, false, bs_potlatency, is_digit, is_eng, false, nerve, bs1_potlatency_d1);
        bs1_potlatency_d2 = plot_traces(sp3, epo_bs_d2, target_bs, x_lim, false, bs_potlatency, is_digit, is_eng, false, nerve, bs1_potlatency_d2);
        
    end 
    
    % esg
    figure(f1)
    esg1_potlatency_d12 = plot_traces(sp4, epo_esg_d12, target_esg, x_lim, false, esg_potlatency, is_digit, is_eng, false, nerve, esg1_potlatency_d12);
    esg1_potlatency_d1 = plot_traces(sp4, epo_esg_d1, target_esg, x_lim, false, esg_potlatency, is_digit, is_eng, false, nerve, esg1_potlatency_d1);
    esg1_potlatency_d2 = plot_traces(sp4, epo_esg_d2, target_esg, x_lim, false, esg_potlatency, is_digit, is_eng, false, nerve, esg1_potlatency_d2);
    
    
    % esg - cca
    figure(f1)
    esg2_potlatency_d12 = plot_traces(sp5, cca_esg_d12, cca_esg_d12.chanlocs.labels, x_lim, true, esg_potlatency, is_digit, is_eng, false, nerve, esg2_potlatency_d12);
    esg2_potlatency_d1 = plot_traces(sp5, cca_esg_d1, cca_esg_d1.chanlocs.labels, x_lim, true, esg_potlatency, is_digit, is_eng, false, nerve, esg2_potlatency_d1);
    esg2_potlatency_d2 = plot_traces(sp5, cca_esg_d2, cca_esg_d2.chanlocs.labels, x_lim, true, esg_potlatency, is_digit, is_eng, false, nerve, esg2_potlatency_d2);
     
    
    % eng
    chan_counter = 0;
    for iplot = 6:6+length(target_eng)-1
        chan_counter = chan_counter + 1;
        is_eng = true;
        str_plot = num2str(iplot);
        figure(f2)
        eval(['eng1_potlatency_d12{chan_counter} = plot_traces(sp' str_plot ', epo_eng_d12, target_eng{chan_counter}, x_lim, true, other_potlatency.' target_eng{chan_counter} ', is_digit, is_eng, false, nerve, eng1_potlatency_d12{chan_counter});'])
        eval(['eng1_potlatency_d1{chan_counter} = plot_traces(sp' str_plot ', epo_eng_d1, target_eng{chan_counter}, x_lim, true, other_potlatency.' target_eng{chan_counter} ', is_digit, is_eng, false, nerve, eng1_potlatency_d1{chan_counter});'])
        eval(['eng1_potlatency_d2{chan_counter} = plot_traces(sp' str_plot ', epo_eng_d2, target_eng{chan_counter}, x_lim, true, other_potlatency.' target_eng{chan_counter} ', is_digit, is_eng, false, nerve, eng1_potlatency_d2{chan_counter});'])
    end

end

%% save latencies
% eeg
latency.mixed.eeg = eeg1_potlatency;
latency.mixed.eeg_cca = eeg2_potlatency;
if srmr_nr == 2
    latency.sensory.d1.eeg = eeg1_potlatency_d1;
    latency.sensory.d2.eeg = eeg1_potlatency_d2;
    latency.sensory.d12.eeg = eeg1_potlatency_d12;
    latency.sensory.d1.eeg_cca = eeg2_potlatency_d1;
    latency.sensory.d2.eeg_cca = eeg2_potlatency_d2;
    latency.sensory.d12.eeg_cca = eeg2_potlatency_d12;
end
fname = [savepath_eeg nerve_name '_extracted_latencies.mat'];
save(fname, 'latency')
clear latency
% bs
if exist('bs1_potlatency', 'var')
    latency.mixed.bs = bs1_potlatency;
else
    latency.mixed.bs = [];
end
if srmr_nr == 2
    if exist('bs1_potlatency_d1', 'var')
        latency.sensory.d1.bs = bs1_potlatency_d1;
    else
        latency.sensory.d1.bs = [];
    end
    if exist('bs1_potlatency_d2', 'var')
        latency.sensory.d2.bs = bs1_potlatency_d2;
    else
        latency.sensory.d2.bs = [];
    end
    if exist('bs1_potlatency_d12', 'var')
        latency.sensory.d12.bs = bs1_potlatency_d12;
    else
        latency.sensory.d12.bs = [];
    end
end
fname = [savepath_bs2 nerve_name '_extracted_latencies.mat'];
save(fname, 'latency')
clear latency
% esg
latency.mixed.esg = esg1_potlatency;
latency.mixed.esg_cca = esg2_potlatency;
if srmr_nr == 2
    latency.sensory.d1.esg = esg1_potlatency_d1;
    latency.sensory.d2.esg = esg1_potlatency_d2;
    latency.sensory.d12.esg = esg1_potlatency_d12;
    latency.sensory.d1.esg_cca = esg2_potlatency_d1;
    latency.sensory.d2.esg_cca = esg2_potlatency_d2;
    latency.sensory.d12.esg_cca = esg2_potlatency_d12;
end
fname = [savepath_esg nerve_name '_extracted_latencies.mat'];
save(fname, 'latency')
clear latency
% eng
latency.mixed.eng = eng1_potlatency;
if srmr_nr == 2
    latency.sensory.d1.eng = eng1_potlatency_d1;
    latency.sensory.d2.eng = eng1_potlatency_d2;
    latency.sensory.d12.eng = eng1_potlatency_d12;
end
fname = [savepath_other nerve_name '_extracted_latencies.mat'];
save(fname, 'latency')
clear latency

end





function new_potlatency = plot_traces(subplot_handle, epo, target_chan, x_lim, arb_unit, ...
    pot_latency, is_digit, is_eng, is_eeg, nerve, new_potlatency)

    axes(subplot_handle)
    hold on
    % plot trace
    chan_idx = find(ismember({epo.chanlocs.labels}, target_chan));
    plot(epo.times, mean(epo.data(chan_idx, :, :), 3))
    title([epo.subject ' - ' epo.condition ' - ' target_chan])
    % plot peak
    if isempty(new_potlatency)
        if ~isnan(pot_latency)
            if is_digit
                t_idx = find(epo.times >= pot_latency);
                if nerve == 1 
                    t_win = t_idx(1):t_idx(1)+7;
                elseif nerve == 2
                    t_win = t_idx(1):t_idx(1)+15;
                end
            else
                t_idx = find(epo.times >= pot_latency-1 & epo.times <= pot_latency+1);
                t_win = t_idx(1)-2:t_idx(2)+5;
            end
            if is_eeg && nerve == 2
                [~, idx_peak] = max(mean(epo.data(chan_idx, t_win, :), 3), [], 2);
            else
                [~, idx_peak] = min(mean(epo.data(chan_idx, t_win, :), 3), [], 2);
            end
            time_idx = t_win(idx_peak);
            plot(epo.times(time_idx), mean(epo.data(chan_idx, time_idx, :), 3), 'r*')
            pot_latency = epo.times(time_idx);
        end
    else
        if ~isnan(new_potlatency(1))
            t_idx = find(epo.times >= new_potlatency(1));
            time_idx = t_idx(1);
            plot(epo.times(time_idx), mean(epo.data(chan_idx, time_idx, :), 3), 'r*')
            pot_latency(1) = epo.times(time_idx);
        end
            
    end
    xlim(x_lim)
    xlabel('time [ms]')
    if arb_unit
        ylabel('magnitude [a.u.]') %arbitrary unit
    else
       ylabel(['magnitude [' char(181) 'V]'])
    end
    
    if isempty(new_potlatency)
        if ~isnan(pot_latency)
            new_potlatency(1) = pot_latency
        else
            new_potlatency(1) = 0
        end
    else 
        disp(new_potlatency)
    end
        
    tt = input('peak detected? no = 0: ');
    shg
    if tt == 0
        while tt == 0
            disp('enter peak for amplitude extraction:  ')
            [x,y] = ginput(1)
            new_potlatency(1) = round(x * (epo.srate/1000)) / (epo.srate/1000) ;
            disp(new_potlatency(1));
            tt = input('peak detected? no = 0, enter manually = 1, not usable = 2: ');
        end
    end
    if tt == 1
        new_potlatency(1) = input('enter latency manually: ');
    elseif tt == 2
        new_potlatency(1) =  NaN;
    end
    
   
    dcm.Enable = 'off';
    hold off

end


