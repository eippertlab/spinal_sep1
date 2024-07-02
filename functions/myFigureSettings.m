% Author: Birgit Nierula
% nierula@cbs.mpg.de

function fset = myFigureSettings()

%% size
fset.fig_size = [6.8 5.1];

%% font
fset.font_name = 'Roboto';
fset.font_size = 9;


%% color
% mixed nerve
fset.mixed = [99 99 99]/255; % black
fset.mixed2 = [189 189 189]/255; % gray

% sensory nerves
fset.digits1 = [27 158 119]/255; % green
fset.digits2 = [117 112 179]/255; % purple
fset.digits12 = [217 95 2]/255; % red

% late potentials
fset.late1 = [178 24 43]/255; % red
fset.late2 = [77 77 77]/255; % dark gray
