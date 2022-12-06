% Author: Birgit Nierula
% nierula@cbs.mpg.de

function bad_channels = prepro_check4badChannels(epo, trigger_name, wait4input, auto_badchan_labels)
%% check for bad channels
% input: epoched data

if ndims(epo.data) == 2
    cnt = epo; clear epo
    load([getenv('CFGDIR') 'cfg.mat'], 'iv_epoch', 'iv_baseline') % in ms
    epoch_ival = iv_epoch / 1000; % convert to seconds
    baseline_ival = iv_baseline;

    % epoch data
    if isempty(trigger_name)
        % define triggers
        trigger_name = {'manual'};
        isi = round( str2num(cnt.group(end-2:end)) / 1000 * cnt.srate );
        remaining = size(cnt.data, 2);
        new_latency = 0;
        event = cnt.event;
        while remaining > isi
            new_latency = new_latency + isi;
            event(end+1).type = trigger_name{1};
            event(end).latency = new_latency;
            remaining = remaining - isi;
        end
        cnt.event = event;
        cnt = eeg_checkset(cnt);
    end
    epo = pop_epoch(cnt, trigger_name, epoch_ival, 'newname', ...
        'SpinalSEP Epochs', 'epochinfo', 'yes' );

    % remove baseline
    % interval for baseline
    epo = pop_rmbase( epo, baseline_ival );
    epo = eeg_checkset( epo );
    
end

figure('units','normalized','outerposition',[0 0 1 1])

% take natural logarithm
dat = mean( log( abs(epo.data).^2 ), 2); dat=squeeze(dat);

% set range from min to max
range(1) = min(min(dat)); range(2) = max(max(dat));

% plot
imagesc(dat, range); colorbar; zoom on
set(gca, 'YTick', 1:size(epo.data, 1));
set(gca,'YTickLabel', {epo.chanlocs.labels});
title('Mean Log Square')
xlabel('trials');
ylabel('channels');
bad_channels = [];

if wait4input

    range = input('range for plotting [1 xx], [] = skip   ');
    
    % update plot until range = [] is entered
    while ~isempty(range)
        imagesc(dat, range); colorbar; zoom on
        set(gca, 'YTick', 1:size(epo.data, 1));
        set(gca,'YTickLabel', {epo.chanlocs.labels});
        title('Mean Log Square')
        xlabel('trials');
        ylabel('channels');
        range = input('range for plotting [1 xx], [] = skip   ');
    end
    
    
    % store selected bad channels in variable
    disp('##################')
    disp('automatic detection bad channels:')
    auto_badchan_labels
    bad_channels = input(['Enter label of bad channels in {} (for example, {''Fz'' ''Pz''}) OR [] for nothing   : \n']);
    unique(bad_channels)
    
    disp('##################')
    disp([num2str(length(bad_channels)) ' channels marked to be removed'])
end