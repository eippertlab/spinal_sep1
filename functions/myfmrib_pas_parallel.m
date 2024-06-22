% fmrib_pas() - Remove pulse
%   artifacts from EEG data collected inside an MRI machine.
%
%   This program removes pulse artifacts from EEG data collected
%   collected inside the MRI scanner. A choice of methods is available.
%
%   The first choice is Optimal Basis Set [Niazy06].
%   This method aligns all the pulse artifacts, in each EEG channel
%   separately, in a matrix and performs a Principal Component Analysis
%   (PCA) on the data.  The first N PCs (the Optimal Basis Set) are then
%   fitted to each artifact in that channel. The process is repeated for
%   each channel.  The other three methods are based on [Allen98] with
%   improvements to better capture and subtract the artifacts.
%   Basically, in these methods a statistical measurement is used to find a
%   template for the artifact  at each heart beat.  A window of 30 artifacts
%   centred around the artifact being processed is used.  The 30 artifacts
%   are processed by taking the mean ('mean' method), the median
%   ('median' method) or a Gaussian-weighted
%   ('gmean' method to emphasise shape of current artifact) mean.  It is
%   recommended to use the first ('obs') method as it generally better
%   fits the true artifact.
%
% Usage:
%    >> EEGOUT= fmrib_pas(EEG,qrsevents,method)
% or >> EEGOUT= fmrib_pas(EEG,qrsevents,method,npc)
%
% Inputs:
%   EEG: EEGLAB data structure
%   qrsevents: vector of QRS event locations specified in samples.
%   method: 'obs' for artifact principal components.  You need to specify
%               'npc', which is the number of PC to use in fitting the
%               artifacts.  If unsure, use 4.
%           'mean' for simple mean averaging.
%           'gmean' for Gaussian weighted mean.
%           'median' for median filter.
%
%
% [Niazy06] R.K. Niazy, C.F. Beckmann, G.D. Iannetti, J.M. Brady, and
%   S.M. Smith (2005) Removal of FMRI environment artifacts from EEG data
%   using optimal basis sets. NeuroImage 28 (3), pages 720-737.
%
%
% [Allen98] Allen et.al., 1998, Identification of EEG events in the MR
%   scanner: the problem of pulse artifact and a method for its
%   subtraction. NeuroImage8,229-239.
%
%
%
% Also See pop_fmrib_pas
%
%   Author:  Rami K. Niazy
%
%   Copyright (c) 2006 University of Oxford

%123456789012345678901234567890123456789012345678901234567890123456789012
%
% Copyright (C) 2006 University of Oxford
% Author:   Rami K. Niazy, FMRIB Centre
%           rami@fmrib.ox.ac.uk
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% SEP 20, 2005
% Template range now based on median instead of mean

% AUG 16, 2005
% Fixed bug dealing with single precision data.

% JUN 3, 2005
% Released

% APR 20, 2005
% in OBS mode artifact matrix now 'constant'  demeaned instead
%  of linear trend removal

% DEC 23, 2004
% updated (c)

% DEC 22, 2004
% fixed end artifact bug
% fixed copyright

% Dec16, 2004
% Added RAPCO
% re-written help

% Nov 4, 2004
% Updated brog bar
% for extra steps

% Oct 26, 2004
% Changed input to accept
% vector of event location
% instead of event type to
% allow for scripting.





function [cnt] = myfmrib_pas_parallel(cnt, QRSevents, method, fwts, ...
    save_name2, channelNames, subject_id, figure_path, cnt_nointerpol)

debug_mode = true;

nargchk(3,4,nargin);

switch method
    
    %% Method: Optimal Basis Set [Niazy06]
    case 'obs'
        
        if nargin < 4
            error('Incorrect number of input arguments');
        end
        
        %init
        %-----
        fs = cnt.srate;
        [channels samples] = size(cnt.data);
        
        % standard delay between QRS peak and artifact (allen,1998)
        delay = 0; %round(0.21*fs); % changed by BN - 13.05.2019
        
        Gwindow = 2; %20;  % adapted by BN 13.05.2019
        GHW = floor(Gwindow/2);
        rcount = 0;
        firstplot = 1;
        
        
        %% memory allocation
        %------------------
        fitted_art = zeros(channels, samples);
        peakplot = zeros(1, samples);
        

        %% set cnt to baseline
        %------------------
        % set to baseline
        cnt.data = cnt.data - mean(cnt.data, 2);
        if ~isempty(cnt_nointerpol)
            cnt_nointerpol.data = cnt_nointerpol.data - mean(cnt.data, 2);
        end
        

        
        %% Extract QRS events
        %-------------------
        peakplot(QRSevents) = 1; %logical indexed locations of qrs events
        sh = zeros(1, delay);
        np = length(peakplot);
        peakplot = [sh peakplot(1:np-delay)]; %shifts indexed array by the delay
        peak_idx = find(peakplot > 0);
        peak_count = length(peak_idx);
        
        
%         %% make filter --> moved outside function for performance reasons
%         %------------
%         a = [0 0 1 1];
%         f = [0 0.4/(fs/2) 0.9/(fs/2) 1]; % 0.4Hz highpass filter
%         ord = round(3*fs/0.5);
%         fwts = firls(ord, f, a);
        
 
        %% Artifact Subtraction
        %----------------------
        
        % for the first window/2 points use arthemitic mean for averageing.
        % findg mean QRS peak-to-peak (R-to-R) interval
        for ch = 1:channels
            
            if ch == 1
                %init waitbar
                %------------
                barth = 5;
                barth_step = barth;
                Flag25 = 0;
                Flag50 = 0;
                Flag75 = 0;
                fprintf('\nPulse artifact subtraction in progress...Please wait!\n');
            end
            
            % define peak range based on RR
            RR = diff(peak_idx);
            mRR = median(RR);
            peak_range = round(mRR / 2);
            midP = peak_range + 1;
            baseline_range = [1 round((peak_range/8))]; %[1 round((peak_range/8)*3)];   
            n_samples_fit = round((peak_range/8)); %sample fit for interpolation between fitted artifact windows

            
            % make sure array is long enough for PArange (if not cut off  last ECG peak)
            pa = peak_count;
            if ch == 1
                while (peak_idx(pa)+ peak_range > samples)
                    pa = pa - 1;
                end
                steps = channels * pa;
                peak_count = pa;
            end
            
            
            %% Filter
            % filter channel
            eegchan = filtfilt(fwts, 1, cnt.data(ch,:));
            
            
            %% PCA
            % build PCA matrix (heart-beat-epoch x window-length)
            pcamat = zeros(peak_count-1, 2*peak_range+1); % [epoch x time]
            dpcamat = pcamat; % [epoch x time]
            for p = 2:peak_count
                pcamat(p-1,:) = eegchan(peak_idx(p)-peak_range:peak_idx(p)+peak_range);
            end
            
            % detrending matrix (twice - why?)
            pcamat = detrend(pcamat', 'constant')'; % [epoch x time] - detrended along the epo
            mean_effect = mean(pcamat); % [1 x time], contains the mean over all epochs
            std_effect = std(pcamat);
            dpcamat = detrend(pcamat, 'constant'); % [time x epoch]
            
            % run PCA (performs SVD (singular value decomposition))
            [eigen_vectors, factor_loadings, eigen_values, pca_info] = mypca_calc(dpcamat'); 
            
            % define selected number of components using profile likelihood
            pca_info.nComponents = 4;

            
            if debug_mode
                % plot pca variables
                figure;
                comp2plot = pca_info.nComponents;
                subplot(2, 3, 1); 
                plot(pca_info.U(:, 1:comp2plot)); title('Us'); xlabel('time'), legend() 
                subplot(2, 3, 2); 
                bar(1:comp2plot, sum(pca_info.S(:, 1:comp2plot), 1)); title('S'); xlabel('components'),
                subplot(2, 3, 4); 
                plot(pca_info.EVec(:, 1:comp2plot)); title('Evec'); xlabel('??'), 
                subplot(2, 3, 3); 
                plot(1:length(pca_info.explVar), pca_info.explVar, 'r*'),
                xlabel('components')
                ylabel('var explained [%]')
                cum_explained = cumsum(pca_info.explVar);
                title(['first ' num2str(pca_info.nComponents) ' comp, ' num2str(cum_explained(pca_info.nComponents)) '% var'])

                subplot(2, 3, 5); 
                plot(pca_info.factorLoadings(:, 1:comp2plot)); title('factor loadings'); xlabel('time'),
                subplot(2, 3, 6); 
                plot(pca_info.eigenValues); title('eigenvalues'); xlabel('components')
                suptitle([subject_id ', thresholds PCA vars channel ' cnt.chanlocs.labels])
                % suptitle(['profile likelihood PCA vars ' cnt.chanlocs.labels])
                slash_idx = strfind(save_name2, '/');
                savefig([figure_path 'pcaVars' save_name2(slash_idx(end)+1:end) '.fig'])
                close
            end

            
            pca_info.chan = cnt.chanlocs.labels;
            pca_info.meanEffect = mean_effect';
            nComponents = pca_info.nComponents;
            save(save_name2, 'pca_info')
            
            
            %% Template
            % make template of ECG artifact
            pca_template = [mean_effect' factor_loadings(:, 1:nComponents)]; % [time x 1] [time x principle components]
            
            if debug_mode
                % plot template vars
                figure; hold on;
                pcatime = (-peak_range:peak_range) / fs;
                fill([pcatime fliplr(pcatime)], [mean_effect + std_effect fliplr(mean_effect - std_effect)], 'k', 'FaceAlpha', 0.2, 'linestyle', 'none');
                plot(pcatime, mean_effect', 'k'); 
                plot(pcatime, factor_loadings(:, 1:nComponents))
                myLegend = {'std effect' 'mean effect'};
                for ii = 1:nComponents
                    myLegend{ii+2} = ['priciple comp ' num2str(ii)];
                end
                legend(myLegend)
                title([subject_id ', papc channel ' cnt.chanlocs.labels])
                slash_idx = strfind(save_name2, '/');
                savefig([figure_path 'templateVars_' save_name2(slash_idx(end)+1:end) '.fig'])
                close
            end
            
            
            %% data fitting
            %-----------------------------------------------------
            % try to fit to first ECG-epoch (might not be possible due to
            % window length)
            p_counter = 0;
            for p = 1:peak_count
                if p == 1 
                    pre_range = peak_range;
                    post_range = ceil((peak_idx(p+1)-peak_idx(p))/2);
                    if post_range > peak_range
                        post_range = peak_range;
                    end
                    try
                        post_idx_nextPeak = [];
                        [fitted_art, post_idx_nextPeak] = fit_ecgTemplate(cnt, ...
                            pca_template, ch, peak_idx(p), peak_range, ...
                            pre_range, post_range, baseline_range, midP, ...
                            fitted_art, post_idx_nextPeak, n_samples_fit);
                        p_counter = p_counter + 1;
                        window_start_idx(p_counter) = peak_idx(p) - peak_range;
                        window_end_idx(p_counter) = peak_idx(p) + peak_range;
                    catch
                    end
                elseif p == peak_count
                    try
                        pre_range = ceil((peak_idx(p)-peak_idx(p-1))/2);
                        post_range = peak_range;
                        if pre_range > peak_range
                            pre_range = peak_range;
                        end
                        [fitted_art, ~] = fit_ecgTemplate(cnt, pca_template, ...
                            ch, peak_idx(p), peak_range, pre_range, post_range, ...
                            baseline_range, midP, fitted_art, post_idx_nextPeak, ...
                            n_samples_fit);
                        p_counter = p_counter + 1;
                        window_start_idx(p_counter) = peak_idx(p) - peak_range;
                        window_end_idx(p_counter) = peak_idx(p) + peak_range;
                    catch
                    end
                else
                    %---------------- Processing of central data ---------------------
                    % cycle through peak artifacts identified by peakplot
                    pre_range = ceil((peak_idx(p)-peak_idx(p-1))/2);
                    post_range = ceil((peak_idx(p+1)-peak_idx(p))/2);
                    if pre_range >= peak_range
                        pre_range = peak_range;%peak_range-2
                    end
                    if post_range > peak_range
                        post_range = peak_range;
                    end

                    aTemplate = pca_template(midP-peak_range:midP+peak_range, :);
                    [fitted_art, post_idx_nextPeak] = fit_ecgTemplate(cnt, ...
                        aTemplate, ch, peak_idx(p), peak_range, pre_range, ...
                        post_range, baseline_range, midP, fitted_art, ...
                        post_idx_nextPeak, n_samples_fit);
                    p_counter = p_counter + 1;
                    window_start_idx(p_counter) = peak_idx(p) - peak_range;
                    window_end_idx(p_counter) = peak_idx(p) + peak_range;
                end
                
                
                % update bar
                %----------
                percentdone = floor( ((ch-1)*peak_count+p) * 100 / steps );
                if floor(percentdone) >= barth
                    if percentdone >= 25 & Flag25 == 0
                        fprintf('25%% ')
                        Flag25 = 1;
                    elseif percentdone >= 50 & Flag50 == 0
                        fprintf('50%% ')
                        Flag50 = 1;
                    elseif percentdone >= 75 & Flag75 == 0
                        fprintf('75%% ')
                        Flag75 = 1;
                    elseif percentdone == 100
                        fprintf('100%%\n')
                    else
                        fprintf('.')
                    end
                    
                    while barth <= percentdone
                        barth = barth+barth_step;
                    end
                    if barth > 100
                        barth = 100;
                    end
                end
            end
        end
        if debug_mode
            % check with plot what has been done
            plotChannel = 0;
            for ii = 1:size(channelNames, 2)
                if strcmp(cnt.chanlocs.labels, channelNames{ii})
                    plotChannel = 1;
                end
            end
            %if plotChannel == 1
                figure; hold on
                plot(cnt.times/1000, cnt.data(1, :))
                plot(cnt.times/1000, eegchan, 'r')
                plot(cnt.times/1000, fitted_art, 'g')
                plot(cnt.times/1000, cnt.data(1, :) - fitted_art, 'm')
                legend({'raw data' 'filtered' 'fitted_art' 'clean'})
                ylabel('amplitude [\muV]'), xlabel('time [s]')
                title(['Subject ' cnt.subject(end-1:end) ', channel ' cnt.chanlocs.labels])
                slash_idx = strfind(save_name2, '/');
                savefig([figure_path 'cleanVsRaw_' save_name2(slash_idx(end)+1:end) '.fig'])
%                 close
            %end
        end
        
        
        % remove fitted artifact from EEG data
        if ~isempty(cnt_nointerpol)
            cnt = cnt_nointerpol;
        end
        cnt.data = cnt.data - fitted_art;
        
        
        % add start of fitting windows
        tt_start_start = size(cnt.event, 2) + 1;
        tt_start_end = size(cnt.event, 2) + length(window_start_idx);
        counter = 0;
        for ievent = tt_start_start:tt_start_end
            counter = counter + 1;
            cnt.event(ievent).latency = window_start_idx(counter);
            cnt.event(ievent).type = 'fit_start';
            cnt.event(ievent).urevent = [];
            cnt.event(ievent).trial_type = '';
            cnt.event(ievent).duration = [];
        end
        
        
        % add end of fitting windows
        tt_end_start = size(cnt.event, 2) + 1;
        tt_end_end = size(cnt.event, 2) + length(window_end_idx);
        counter = 0;
        for ievent = tt_end_start:tt_end_end
            counter = counter + 1;
            cnt.event(ievent).latency = window_end_idx(counter);
            cnt.event(ievent).type = 'fit_end';
            cnt.event(ievent).urevent = [];
            cnt.event(ievent).trial_type = '';
            cnt.event(ievent).duration = [];
        end
        cnt = eeg_checkset(cnt);
        
end
return;
