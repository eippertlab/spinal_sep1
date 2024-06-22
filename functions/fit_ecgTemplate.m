function [fitted_art, post_idx_nextPeak] = fit_ecgTemplate(cnt, pca_template, ch, aPeak_idx, peak_range, pre_range, post_range, baseline_range, midP, fitted_art, post_idx_previousPeak, n_samples_fit)

% select window of template
template = double( pca_template( midP-peak_range : midP+peak_range, : ) );

% select window of data and detrend it
% [detrended_data, trend] = mydetrend(cnt.data(ch, aPeak_idx-peak_range : aPeak_idx+peak_range)', 'linear');
detrended_data = double(detrend(cnt.data(ch, aPeak_idx-peak_range:aPeak_idx+peak_range)', 'constant'));

% maps data on template and then maps it again back to the sensor space
pad_fit = template * (template \ detrended_data);
%     double(detrend(cnt.data(ch, aPeak_idx-peak_range:aPeak_idx+peak_range)', 'constant')));

% % return trend
% pad_fit = pad_fit + trend;

% % set pad_fit to baseline
% baseline = mean(pad_fit(baseline_range(1):baseline_range(2)));
% pad_fit = pad_fit - baseline;

% fit artifact
fitted_art(ch, aPeak_idx-pre_range:aPeak_idx+post_range) = ...
        pad_fit(midP-pre_range:midP+post_range)';

post_idx_nextPeak = aPeak_idx + post_range;
if ~isempty(post_idx_previousPeak)
    % interpolate time between peaks
    intpol_window = ceil([post_idx_previousPeak aPeak_idx-pre_range]); % interpolation window 
    if intpol_window(1) < intpol_window(2)
        % Piecewise Cubic Hermite Interpolating Polynomial (PCHIP) + replace EEG data
%         n_samples_fit = 2; %+1;  number of samples before and after cut used for interpolation fit

        x_fit = [intpol_window(1)-n_samples_fit : 1 : intpol_window(1), intpol_window(2) : 1 : intpol_window(2)+n_samples_fit];
        x_interpol = intpol_window(1) : 1 : intpol_window(2); % points to be interpolated; in pt
        y_fit = fitted_art(ch, x_fit); % y values to be fitted
        y_interpol = pchip(x_fit, y_fit, x_interpol); % calculate pchip, obtain values in t_cut interval

        fitted_art(ch, post_idx_previousPeak:aPeak_idx-pre_range) = y_interpol;
    end
end

