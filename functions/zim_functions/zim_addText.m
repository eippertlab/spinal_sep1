% Author: Birgit Nierula (Feb, 2020)
% nierula@cbs.mpg.de


function zim_addText(txt_filename, mytext, text_level)

%% input
% txt_filename = file name of text file
% mytext = text you want to add
% text_level: 1 = title1, 2 = title2, ..., 6 = title6, 0 = regular text

% open text file
fid = fopen(txt_filename, 'a+');

% write figure title
zim_writeLine(fid, text_level, mytext)
fprintf(fid, '\n');

fclose(fid);