% Author: Birgit Nierula (Feb, 2020)
% nierula@cbs.mpg.de

function zim_addFigure(txt_filename, figure_filename, figure_title, title_level, figure_width)

%% input
% txt_filename = file name of text file (including the path)
% figure_filename = file name of the figure, should be png or (??), zim 
% works with relative files --> figure has to be in a folder with the same
% name as txt_filename and at the same subfolder level!!
% figure_title = figure title displayed on zim page (default: figure_filename)
% title_level = title level on zim page
% figure_width = width of figure, default: 1500

% open text file
fid = fopen(txt_filename, 'a+');

% write figure title
if isempty(figure_title)
    figure_title = figure_filename;
end
zim_writeLine(fid, title_level, figure_title)
fprintf(fid, '\n');

% link figure
if isempty(figure_width)
    figure_width = 1500;
end

zim_linkFigure(fid, figure_filename, figure_width)
fprintf(fid, '\n');

fclose(fid);