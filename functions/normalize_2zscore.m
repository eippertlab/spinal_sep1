% Author: Birgit Nierula
% nierula@cbs.mpg.de

function [norm_matrix] = normalize_2zscore(data_matrix)

% concutenate trials to continuous signal
tmp = NaN(1, size(data_matrix,1) * size(data_matrix, 2));
size_counter = 0;
for itrial = 1:size(data_matrix, 1)
    tmp(1, size_counter+1 : size_counter+size(data_matrix, 2)) = data_matrix(itrial, :); 
    size_counter = size_counter + size(data_matrix, 2);
end

% remove NaNs
idx = find(~isnan(tmp));
tmp2 = tmp(idx);

% z transformation
tmp_z2 = zscore(tmp2); % along first dimension

% add NaNs back to data matrix
tmp_z = nan(size(tmp,1), size(tmp,2));
tmp_z(idx) = tmp_z2;

% separate trials
norm_matrix = NaN(size(data_matrix));
size_counter = 0;
for itrial = 1:size(data_matrix, 1)
    norm_matrix(itrial, :) = tmp_z(1, size_counter+1 : size_counter+size(data_matrix, 2)); 
    size_counter = size_counter + size(data_matrix, 2);
end