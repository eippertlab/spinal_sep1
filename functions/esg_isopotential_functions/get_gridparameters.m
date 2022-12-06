% Author: Birgit Nierula 
% nierula@cbs.mpg.de

function [labels, elec_pos, grid_size, grid_pos] = get_gridparameters(subjects)


%% electrode positions in mm
% import electrode positions
for isubject = 1:length(subjects)
    subject_id = sprintf('sub-%03i', subjects(isubject));
    raw_path = [getenv('RAWDIR') subject_id '/eeg/'];
    fname = [raw_path subject_id '_space-Other_electrodes.tsv'];
    electrode_pos = readtable(fname, 'FileType', 'text', 'TreatAsEmpty', 'n/a');
    % remove electrode positions with NaN value
    x_idx = ~isnan(electrode_pos.x);
    y_idx = ~isnan(electrode_pos.y);
    z_idx = ~isnan(electrode_pos.z);
    elec_idx = find(sum([x_idx y_idx z_idx], 2) == 3); clear x_idx y_idx z_idx
    labels = electrode_pos.name(elec_idx);
    x_pos{isubject} = electrode_pos.x(elec_idx);
    z_pos{isubject} = electrode_pos.z(elec_idx); clear elec_idx
end
% take mean over all subjects
x = mean([x_pos{:}], 2);
z = mean([z_pos{:}], 2);
elec_pos = [z x];


%% define grid positions
grid_pos(:, 1) = abs(elec_pos(:, 1) - max(elec_pos(:,1))) + 10;
grid_pos(:, 2) = elec_pos(:, 2) + 60;
% grid_pos = grid_pos - 50;


%% define grid size
grid_size = max(grid_pos) + 10;