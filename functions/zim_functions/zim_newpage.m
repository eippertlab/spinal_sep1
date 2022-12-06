% Author: Birgit Nierula (Feb, 2020)
% nierula@cbs.mpg.de


function zim_newpage(page_path, page_name, my_title)

% make sure the path ends with /
if ~strcmp(page_path(end), '/')
    page_path = [page_path '/'];
end

% create text file
if ~exist([page_path page_name])
    mkdir([page_path page_name])
end
fid = fopen([page_path page_name '.txt'], 'w+');


% write first lines
line1 = 'Content-Type: text/x-zim-wiki';
line2 = 'Wiki-Format: zim 0.4';
zim_writeLine(fid, 0, line1); 
zim_writeLine(fid, 0, line2); 

fprintf(fid, '\n');

% write title line
if isempty(my_title)    
    idx = findstr(page_name, '_');
    new_title = page_name;
    new_title(idx) = ' ';
    zim_writeLine(fid, 1, new_title)
else
    zim_writeLine(fid, 1, my_title)
end

% write date
tt = datestr(datetime('now','TimeZone','local','Format','eeee d MMMM y'));
line4 = ['Created  ' tt];
zim_writeLine(fid, 0, line4)

fprintf(fid, '\n');

fclose(fid);