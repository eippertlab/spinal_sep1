% Author: Birgit Nierula
% nierula@cbs.mpg.de

function check_ica_plots_allBlocks(subject, chan_name, srmr_nr, display_time)

subject_id = sprintf('SRMR%01i_S%02i', srmr_nr, subject);
analysis_path = [getenv('ANADIR') subject_id '/eeg/prepro/'];


load([getenv('CFGDIR') 'cfg.mat'], 'srate_ica')

% load ICA info
fname = ['allConditions_sr' num2str(srate_ica) 'Hz_ICA.set'];
cnt0 = pop_loadset('filename', fname, 'filepath', analysis_path);

load([analysis_path 'allConditions_ICAcomps_marked_for_rejection.mat'], 'marked_comps_SASICA')
cnt0.comprej = marked_comps_SASICA.all;


% remove ECG and EOG channels
cnt0 = pop_select( cnt0, 'nochannel',{'ECG' 'EOGH' 'EOGV'});

% remove selected ICA components
cnt = pop_subcomp(cnt0, [cnt0.comprej], 0);

% rereference to average reference
cnt0a = cnt0;
cnt0a.nbchan = cnt0a.nbchan+1;
cnt0a.data(end+1,:) = zeros(1, cnt0a.pnts);
cnt0a.chanlocs(1, cnt0a.nbchan).labels = 'initialReference';
cnt0a = pop_reref( cnt0a, []);
cnt0a = pop_select( cnt0a, 'nochannel', {'initialReference'});

cnta = cnt;
cnta.nbchan = cnta.nbchan+1;
cnta.data(end+1,:) = zeros(1, cnta.pnts);
cnta.chanlocs(1, cnta.nbchan).labels = 'initialReference';
cnta = pop_reref( cnta, []);
cnta = pop_select( cnta, 'nochannel', {'initialReference'});

% select channel to inspect
chan_idx = find(ismember({cnt.chanlocs.labels}, chan_name));


% plot continuous data
chan_select = input('Check continous data - Which channels do you want to see ? 1 = selected channels, 2 = all, 3 = none ?   ');
while chan_select == 1 || chan_select == 2 
    
    if chan_select == 2
        chan_idx = 1:length({cnt.chanlocs.labels});
    elseif chan_select == 1
        chan_names = input('Enter which channels you want to see in {}, i.e. {''F1'' ''F2'' ''T7'' ''T8''}:'  );
        chan_idx = find(ismember({cnt.chanlocs.labels}, chan_names));
    else
        chan_select = [];
    end
    
    if ~isempty(chan_select)
        for ii = chan_idx
            figure('units','normalized','outerposition',[0 0 1 1]); hold on
            plot(cnt0.times, cnt0.data(ii, :), 'k')
            plot(cnt.times, cnt.data(ii, :), 'r')
            ylim([-150 150])
            xlabel('time [ms]'); ylabel('amplitude [\muV]')
            legend({'raw' 'ica'})
            title([cnt.chanlocs(ii).labels ', all conditions+blocks'] )
            pause(display_time)
            close
        end
    end
    
    chan_select = input('Check continous data - Which channels do you want to see ? 1 = selected channels, 2 = all, 3 = none ?   ');
end

% select channel to inspect
chan_idx = find(ismember({cnt.chanlocs.labels}, chan_name));

% plot data epoched to R-peak
ivH = [-0.5 1];
ivBase = [-100 0];
epoH = make_epochs(cnt, {'qrs'}, ivH, ivBase);
epoH0 = make_epochs(cnt0, {'qrs'}, ivH, ivBase);
epoHa = make_epochs(cnta, {'qrs'}, ivH, ivBase);
epoH0a = make_epochs(cnt0a, {'qrs'}, ivH, ivBase);


figure; 
% recording ref
subplot(2, 2, 1); hold on
plot(epoH0.times, mean(epoH0.data(chan_idx, :, :), 3), 'k')
plot(epoH.times, mean(epoH.data(chan_idx, :, :), 3), 'r')
xlabel('time [ms]'); ylabel('amplitude [\muV]')
legend({'raw' 'ica'})
title('recording ref')
% isopotential plot recording ref
subplot(2, 2, 2); hold on
pop_topoplot( epoH, 1, 0 , ', recording ref' );
    
% average ref
subplot(2, 2, 3); hold on
plot(epoH0a.times, mean(epoH0a.data(chan_idx, :, :), 3), 'k')
plot(epoHa.times, mean(epoHa.data(chan_idx, :, :), 3), 'r')
xlabel('time [ms]'); ylabel('amplitude [\muV]')
legend({'raw' 'ica'})
title('average ref')
suptitle([cnt.chanlocs(chan_idx).labels ', all conditions + blocks, epoched to R-peak and averaged'])
% isopotential plot avg ref
subplot(2, 2, 4); hold on
pop_topoplot( epoHa, 1, 0, 'latency 0, average ref' );


end

function epo = make_epochs(cnt, trigger_name, ival, ivalBase)
    epo = pop_epoch(cnt, trigger_name, ival);
    epo = pop_rmbase(epo, ivalBase);
end
