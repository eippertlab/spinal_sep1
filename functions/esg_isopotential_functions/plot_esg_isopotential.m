% Author: Birgit Nierula 
% nierula@cbs.mpg.de

function plot_esg_isopotential(chanvalues, gridsize, chan_pos_grid, labels)

%% Input arguments:
% chanvalues = data values for each channel
% gridsize = size of grid
% chan_grid_pos = in matrix indexes
% labels = channel labels

%% create electrode grid
chan_grid = zeros(round(gridsize));


% fill grid with channels
for ichan = 1:size(chan_pos_grid, 1)
    chan_grid(round(chan_pos_grid(ichan, 1)), round(chan_pos_grid(ichan, 2))) = 1;
end
% figure; imagesc(chan_grid);
            
%% create meshgrid
% x-positions
x = chan_pos_grid(:,2)';
% y-positions
y = chan_pos_grid(:,1)';
% regrid and interpolate
[xq,yq] = meshgrid(1:1:gridsize(2), 1:1:gridsize(1));
vq = griddata(x, y, chanvalues, xq, yq, 'v4');

%% plot
%figure; surf(xq, yq, vq);
n_contourlines = 6;
imagesc(vq); hold on; 
% contour(vq, '-k');
contour(vq, n_contourlines, '-k');

% plot electrode position and name
plotax = gca;
axis off

pos = get(gca,'position');
set(plotax,'position',pos);

xlm = get(gca,'xlim');
set(plotax,'xlim',xlm);

ylm = get(gca,'ylim');
set(plotax,'ylim',ylm);

EMARKERSIZE = 10;

ELECTRODE_HEIGHT = 2.1;  % z value for plotting electrode information (above the surf)

EFSIZE = get(0,'DefaultAxesFontSize');

hp2 = plot3(x, y, ones(size(x)) * ELECTRODE_HEIGHT, '.', ...
    'Color', [0 0 0], 'markersize', EMARKERSIZE, 'linewidth', 1);

if ~isempty(labels)
    for i = 1:size(labels, 2)
        hh(i) = text(double(x(i) + 1), double(y(i)),...
            ELECTRODE_HEIGHT, labels{i}, 'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', 'Color', [0 0 0], 'userdata', num2str(i), ...
            'FontSize', EFSIZE, 'buttondownfcn', ...
            ['tmpstr = get(gco, ''userdata'');'...
            'set(gco, ''userdata'', get(gco, ''string''));' ...
            'set(gco, ''string'', tmpstr); clear tmpstr;'] );
    end
end
colormap(jet)