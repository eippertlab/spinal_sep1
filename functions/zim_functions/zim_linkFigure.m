% Author: Birgit Nierula (Feb, 2020)
% nierula@cbs.mpg.de


function zim_linkFigure(fid, figure_filename, figure_width)

%% input
% fid = file identifier
% figure_fileName = file name of the figure, should be png or (??), should
% be in the accoring zim folder structure!

% link figure
figure_link = ['{{./' figure_filename '?width=' num2str(figure_width) '}}'];
zim_writeLine(fid, 0, figure_link)