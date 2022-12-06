% Author: Birgit Nierula
% nierula@cbs.mpg.de

function bad_channels = prepro_esg_check4badChannels(epo, trigger_name, wait4input)
%% check for bad channels
% input: epoched data

if ndims(epo.data) == 2
    
    cnt = epo; clear epo
    load([getenv('CFGDIR') 'cfg.mat'], 'iv_epoch', 'iv_baseline')
    epoch_ival = iv_epoch/1000;
    baseline_ival = iv_baseline;

    % epoch data
    epo = pop_epoch( cnt, trigger_name, epoch_ival, 'newname', 'SpinalSEP Epochs', 'epochinfo', 'yes' );

    % remove baseline
    % interval for baseline
    epo = pop_rmbase( epo, baseline_ival );
    epo = eeg_checkset( epo );
    
end

figure('units','normalized','outerposition',[0 0 1 1])

% % take natural logarithm
% dat = mean( log( abs(epo.data).^2 ), 2); dat=squeeze(dat);

% take root mean square
dat = squeeze(rms(epo.data, 2));

% set range from min to max
range(1) = min(min(dat)); range(2) = max(max(dat));

% plot
imagesc(dat, range); colorbar; zoom on
set(gca, 'YTick', 1:size(epo.data, 1));
set(gca,'YTickLabel', {epo.chanlocs.labels});
xlabel('trials');
ylabel('channels');
title('root mean square of each trial')

if wait4input
    % update plot until range = [] is entered
    range = input('range for plotting [1 xx], [] = skip   ');
    while ~isempty(range)
        imagesc(dat, range); colorbar; zoom on
        set(gca, 'YTick', 1:size(epo.data, 1));
        set(gca,'YTickLabel', {epo.chanlocs.labels});
        xlabel('trials');
        ylabel('channels');
        title('root mean square of each trial')
        range = input('range for plotting [1 xx], [] = skip   ');
    end



    % store selected bad channels in variable
    bad_channels = input('enter label of bad channels in {}, [] for nothing   ');
else
    bad_channels = [];
end

