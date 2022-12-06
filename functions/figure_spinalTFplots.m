% Author: Birgit Nierula
% nierula@cbs.mpg.de

function figure_spinalTFplots(subjects, condition, is_evoked)

% set path
savepath_ga = getenv('GADIR');

% condition info
srmr_nr = 1;
cond_info = get_conditionInfo(condition, srmr_nr);
cond_name = cond_info.cond_name;
nerve = cond_info.nerve;
trigger_name = cond_info.trigger_name;

if nerve == 2
    knee_chans = {'KneeM' 'Knee1' 'Knee2' 'Knee3' 'Knee4'};
    fname = [savepath_ga 'amplitudeAndLatency_allSubjects.mat'];
    load(fname, [cond_name '_values'])
end

% data level:
% 1 = eeg clean
% 2 = eeg cca
% 3 = esg clean TH6 ref
% 4 = esg clean anterior ref
% 5 = esg cca
% 6 = brainstem
% 7 = eng

% take single subject average
data_levels = 3; 
for dat_level = data_levels
    is_raw = false;
    out = ga_combineData(subjects, condition, srmr_nr, ...
        is_raw, dat_level);
    is_au = true;
    % all subjects
    for isubject = 1:length(subjects)
        if ~isempty(out{isubject})
            if isubject == length(subjects)
                epo_all.(['d' num2str(dat_level)]).times = out{isubject}.times;
                epo_all.(['d' num2str(dat_level)]).srate = out{isubject}.srate;
            end
            if dat_level == 3 % esg TH6-Ref
                if nerve == 1
                    chan_names = {'SC6'};
                elseif nerve == 2
                    chan_names = {'L1'};
                end
                epo_all.(['d' num2str(dat_level)]).title = chan_names;
            elseif dat_level == 4 % esg ant-Ref
                if nerve == 1
                    chan_names = {'SC6'};
                elseif nerve == 2
                    chan_names = {'L1'};
                end
                epo_all.(['d' num2str(dat_level)]).title = chan_names;
            elseif dat_level == 5 % esg cca
                chan_names = {NaN};
                if nerve == 1
                    epo_all.(['d' num2str(dat_level)]).title = {'cervical CCA'};
                elseif nerve == 2
                    epo_all.(['d' num2str(dat_level)]).title = {'lumbar CCA'};
                end
            end
            
            for ichan = 1:length(chan_names)
                if ~isnan(chan_names{ichan})
                    chan_idx = find(ismember({out{isubject}.chanlocs.labels},chan_names{ichan}));
                else
                    chan_idx = 1;
                end
                % normalize data
                dat(1,:,:) = normalize_2zscore(squeeze(out{isubject}.data(chan_idx,:,:)));
                if length(subjects) > 1
                    epo_all.(['d' num2str(dat_level)]).data(ichan,:,isubject) = nanmean(dat, 3);
                    clear dat
                else
                    epo_all.(['d' num2str(dat_level)]).data(ichan,:,:) = dat;
                end
                clear dat
            end
            epo_all.(['d' num2str(dat_level)]).potLatency = out{isubject}.potLatency;
            epo_all.(['d' num2str(dat_level)]).is_au = is_au;
        end
    end
end

%% make time-frequency plots
min_freq = 1;
max_freq = 500;
num_frex = 50;
color_range = [0 10];
is_normalized = true;

ichan = 1;

for isubject = 1:length(subjects)
    
    subj_dat = epo_all.(['d' num2str(dat_level)]).data(ichan,:,isubject);
    srate = epo_all.(['d' num2str(dat_level)]).srate;
    subj_times = epo_all.(['d' num2str(dat_level)]).times;
    
    %  Wavelet parameters
    time = -0.01 : 1/srate : 0.01;

    % Logarithmic frequency scaling
    frex = logspace(log10(min_freq), log10(max_freq), num_frex);
    s    = logspace(log10(3), log10(10), num_frex) ./ (2 * pi * frex);

    % convolution parameters
    pnts_wavelet            = length(time);
    pnts_pnts               = size(subj_dat,2);  % number of time points in data
    pnts_convolution        = pnts_wavelet + pnts_pnts - 1;
    pnts_conv_pow2          = pow2(nextpow2(pnts_convolution));
    half_of_wavelet_size = (pnts_wavelet - 1) / 2;

    % initialize
    tempamp = []; 
    new = zeros(num_frex, pnts_pnts);


    for fi = 1:num_frex

        if is_evoked % evoked activity
            avg_subj_dat = mean(subj_dat, 3);
            eegfft = fft((avg_subj_dat(ichan, :)), pnts_conv_pow2);
            wavelet = fft(exp(2*1i*pi*frex(fi).*time) .* exp(-time.^2./(2*(s(fi)^2))), pnts_conv_pow2);
            % convolution
            eegconv = ifft(wavelet .* eegfft);
            eegconv = eegconv(1:pnts_convolution);
            eegconv= eegconv(half_of_wavelet_size+1:end-half_of_wavelet_size);
            avg_tempamp = abs(eegconv);
        else % induced activity
            for tr = 1:size(subj_dat, 3)
                eegfft = fft((subj_dat(ichan, :, tr)), pnts_conv_pow2);
                wavelet = fft(exp(2*1i*pi*frex(fi).*time) .* exp(-time.^2./(2*(s(fi)^2))), pnts_conv_pow2);
                % convolution
                eegconv = ifft(wavelet .* eegfft);
                eegconv = eegconv(1:pnts_convolution);
                eegconv= eegconv(half_of_wavelet_size+1:end-half_of_wavelet_size);
                tempamp(:, tr) = abs(eegconv);
            end
            % Average power over trials
            avg_tempamp = mean(tempamp, 2);
        end

        if is_normalized
            bs_ival = [-200 -10]; % ival that Gunnar uses
            bs_idx = find(subj_times >= bs_ival(1) & subj_times <= bs_ival(2));
            pre_av = mean(avg_tempamp(bs_idx));
            avg_tempamp_n = avg_tempamp/pre_av;
            new(fi,:) = avg_tempamp_n;
        else
            new(fi,:) = avg_tempamp;
        end

    end

    all_TF(:, :, isubject) = new;

end


%% make plots
%% ------------
fset = myFigureSettings(); % input: size(1) = width, size(2) = hight
fig_size = fset.fig_size;
font_size = fset.font_size;

% ==================== FIGURE SETTINGS ========================
figure;
set(gcf, 'units', 'centimeters', 'position', [1 1 fig_size(1) fig_size(2)])


% % ==================== COLOR SETTINGS ========================
% color_code = {fset.mixed2 fset.mixed};
% face_alpha = 0.3;


% ==================== GRAPH SETTINGS ========================
line_width = 1;
font_name = 'Roboto';

if nerve == 1
    x_lim = [-20 60];
%     xtickpoints = -20:10:60;
%     xticklabels = {'-20' '' '0' '' '20' '' '40' '' '60'}';
elseif nerve == 2
    x_lim = [-20 80];
%     xtickpoints = -20:10:80;
%     xticklabels = {'-20' '' '0' '' '20' '' '40' '' '60' '' '80'}';
end

set(gca,'linewidth',1)
set(gca,'FontSize', font_size)
set(gca,'FontName', font_name)

% ==================== PLOT FIGURE ============================
hold on,

% take TF average over all subjects
ga_TF = mean(all_TF, 3);

contourf(subj_times, frex, ga_TF, 40,'linestyle','none');
c = colorbar; c.Label.String = 'Log power [\muV^2/Hz]';
c.Label.FontSize = 12;
if ~isempty(color_range)
    caxis(color_range);
else
    caxis('auto');
end
set(gca,'ColorScale','log')
xlim(x_lim)
xlabel('Time [ms]'); ylabel('Frequency (Hz)')
title(['TF Plot ' chan_names{1}]);

%% save
if is_evoked
    str_evoked = '_evoked';
else
    str_evoked = '_induced';
end
if length(subjects) > 1
    fname = ['tf_spinal_' cond_name '_grndAvg' str_evoked];
else
    fname = ['tf_spinal_' cond_name sprintf('_sub-%03i', subjects) str_evoked];
end
print([getenv('FIGUREPATH') fname], '-dpng', '-painters') 
print([getenv('FIGUREPATH') fname], '-dsvg', '-painters')  


 
end

