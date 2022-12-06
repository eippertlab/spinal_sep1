% Author: Birgit Nierula
% nierula@cbs.mpg.de
% Code adapted from Sencer Melih Deniz

function new = proc_tf_plots(epo, min_freq, max_freq, num_frex, chan_names, ...
    color_range, is_normalized)

if ~isempty(chan_names)
    %% select channels
    chan_idx = find(ismember({epo.chanlocs.labels}, chan_names ));
    epo = pop_select(epo, 'channel', chan_idx); 
end

%%  Wavelet parameters
time = -0.01 : 1/epo.srate : 0.01;

% Logarithmic frequency scaling
frex = logspace(log10(min_freq), log10(max_freq), num_frex);
s    = logspace(log10(3), log10(10), num_frex) ./ (2 * pi * frex);

%%
% convolution parameters
pnts_wavelet            = length(time);
pnts_data               = epo.pnts;  %cnt.pnts is the number of time points in your data
pnts_convolution        = pnts_wavelet + pnts_data - 1;
pnts_conv_pow2          = pow2(nextpow2(pnts_convolution));
half_of_wavelet_size = (pnts_wavelet - 1) / 2;

% initialize
tempamp = []; % or you can create zero matrix. I dont know your matrix size, so i left as []
new = zeros(num_frex, epo.pnts);
cnt_TF = zeros(size(epo.data, 1), num_frex, epo.pnts);


for ichan = 1:epo.nbchan
    for fi = 1:num_frex
        for tr = 1:size(epo.data, 3)
            eegfft = fft((epo.data(ichan, :, tr)), pnts_conv_pow2);
            wavelet = fft(exp(2*1i*pi*frex(fi).*time) .* exp(-time.^2./(2*(s(fi)^2))), pnts_conv_pow2);
            % convolution
            eegconv = ifft(wavelet .* eegfft);
            eegconv = eegconv(1:pnts_convolution);
            eegconv= eegconv(half_of_wavelet_size+1:end-half_of_wavelet_size);
            tempamp(:, tr) = abs(eegconv);
        end
        % Average power over trials
        avg_tempamp = mean(tempamp, 2);
        if is_normalized
            bs_ival = [-200 -10]; % ival that Gunnar uses
            bs_idx = find(epo.times >= bs_ival(1) & epo.times <= bs_ival(2));
            pre_av = mean(avg_tempamp(bs_idx));
            avg_tempamp_n = avg_tempamp/pre_av;
            new(fi,:) = avg_tempamp_n;
        else
            new(fi,:) = avg_tempamp;
        end
    end
    cnt_TF(ichan, :, :) = new;
    
    if size(chan_names,2) > 1
        figure
    end
    contourf(epo.times, frex, new, 40,'linestyle','none');
    c = colorbar; c.Label.String = 'Power [\muV^2/Hz]';
    c.Label.FontSize = 12;
    if ~isempty(color_range)
        caxis(color_range); 
    else
        caxis('auto');
    end
    xlabel('Time [ms]'); ylabel('Frequency (Hz)')
    title(['TF Plot ' epo.chanlocs(ichan).labels]);
%     waitforbuttonpress
    
end  % END of channels
