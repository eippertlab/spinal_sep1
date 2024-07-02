% Author: Birgit Nierula
% nierula@cbs.mpg.de

function mrmr_esg_isopotentialplot(subjects, chanvalues, colorbar_axes, chan_labels)

%% isopotential maps


%% get grid parameters
[labels, elec_pos, grid_size, grid_pos] = get_gridparameters(subjects);

%% sort channels + reduce to actual channel size
allchan_idx = find(~isnan(chanvalues));
target_chans = chan_labels(allchan_idx);
ordered_chanvalues = zeros(1, size(target_chans, 1));
chan_counter = 0;
for ichan = 1:size(target_chans, 2)
    chan_idx = find( ismember( labels, target_chans(ichan) ) );
    if ~isempty(chan_idx)
        chan_counter = chan_counter + 1;
        ordered_chanvalues(1, chan_counter) = chanvalues(ichan);
        ordered_gridpos(chan_counter, :) = grid_pos(chan_idx, :);
        ordered_elecpos(chan_counter, :) = elec_pos(chan_idx, :);
        ordered_labels(chan_counter, 1) = labels(chan_idx);
    end
end

%% create isopotential plot
ordered_labels = []; % set to empty if you do not want to plot the labels
plot_esg_isopotential(ordered_chanvalues, grid_size, ordered_gridpos, ordered_labels);

h1 = colorbar;
if ~isempty(colorbar_axes)
    caxis(colorbar_axes)
else 
    caxis('auto')
end
ylabel(h1, 'Amplitude [\muV]')


end