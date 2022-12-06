% Author: Birgit Nierula (Feb, 2020)
% nierula@cbs.mpg.de


function zim_writeLine(fid, headerLevel, mytext)
%% input: 
% fid = file identifier
% headerLevel: 1 = title1, 2 = title2, ..., 6 = title6, 0 = regular text
% mytext = text you want to add

if headerLevel > 6
    headerLevel = 0;
elseif headerLevel < 1
    headerLevel = 0;
end
    
nLines = 7 - headerLevel;

% create headerLines
str_lines = [];
for ii = 1:nLines
    str_lines = [str_lines '='];
end

% combine headerlines with text
if headerLevel ~= 0
    newline = [str_lines ' ' mytext ' ' str_lines];
else
    newline = mytext;
end

% print new line in text file
fprintf(fid, '%s\n', newline);