function [EEG, rejectDataIntervals, badPointsInSec, badPointsPerc] = trimOutlier_profound_cleaning(EEG, sd_thresh_lf, amplitudeThreshold_hf, pointSpreadWidth, chan_ex)
% Modified from trimOutlier() by Elena Cesnait & Paul Steinfath
% Adapted for ERP data by Tilman Stephani, 08/2019

% Apply thresholds based on SD (sd_thresh_lf) in lower frequency range and
% on fixed value (amplitudeThreshold_hf) in higher frequency range. Additionally
% cut out a certain region (pointSpreadWidth around the artifacts. Also, exclude
% some channels (chan_ex).


% return if 3-D
if length(size(EEG.data))==3
    disp('Epoched data detected: datapoint rejection will not be performed.')
    return
end
EEG_mfront = pop_select(EEG, 'nochannel', chan_ex); %reject frontal channels not to detect eye blinks

%% set the threshold for lower freq bands %%
[a,b] = butter(2,[1 15]/(EEG.srate/2));
EEG_lowfreq.data = filtfilt(a,b,double(EEG_mfront.data)')';
meanAllChan = mean(EEG_lowfreq.data(:,:));
stdAllChan  = std( EEG_lowfreq.data(:,:),0,1);
posi2SDChan = meanAllChan + sd_thresh_lf * stdAllChan;
nega2SDChan = meanAllChan - sd_thresh_lf * stdAllChan;
newThre = max(max(abs(nega2SDChan), posi2SDChan));

amplitudeThreshold = newThre;
% if newThre > 300
%     amplitudeThreshold = 300;
% else
%     amplitudeThreshold = newThre;
% end

%% remove bad datapoints

% obtain the window size
windowSize = pointSpreadWidth; % millisecond
windowSizeInFrame = round(windowSize/(1000/EEG.srate)); % frame

% compute bad datapoints
absMinMaxAllChan = max([abs(min(EEG_mfront.data(:,:))); abs(max(EEG_mfront.data(:,:)))],[],1);
badPoints = [];
badPoints  = absMinMaxAllChan > amplitudeThreshold;

% Adjust parameters for higher frequency activity %
% high-pass filter
    [d,c] = butter(2,[15 45]/(EEG.srate/2));
    EEG_hf.data = filtfilt(d,c,double(EEG_mfront.data)')';

% compute bad datapoints

absMinMaxAllChan_hf = max([abs(min(EEG_hf.data(:,:))); abs(max(EEG_hf.data(:,:)))],[],1);
badPoints_hf  = absMinMaxAllChan_hf > amplitudeThreshold_hf;


if any(badPoints) || any(badPoints_hf)
    % expand badPoints
    badPointsExpanded = logical(conv(single(badPoints), ones(1,windowSizeInFrame), 'same'));

    % start Christian's impressive code
    rejectDataIntervals = reshape(find(diff([false badPointsExpanded false])),2,[])';
    rejectDataIntervals(:,2) = rejectDataIntervals(:,2)-1;

    % expand badPoints for high frequencies
    badPointsExpanded_hf = logical(conv(single(badPoints_hf), ones(1,windowSizeInFrame), 'same'));

    % start Christian's impressive code
    rejectDataIntervals_hf = reshape(find(diff([false badPointsExpanded_hf false])),2,[])';
    rejectDataIntervals_hf(:,2) = rejectDataIntervals_hf(:,2)-1;

    for n = 1:size(rejectDataIntervals_hf,1)
        l = size(rejectDataIntervals,1) +1;
        rejectDataIntervals(l,:)=rejectDataIntervals_hf(n,:);
    end

     [~,idx] = sort(rejectDataIntervals(:,1)); % sort just the first column
     rejectDataIntervals = rejectDataIntervals(idx,:);

      % merge overlapping segments and segments that are less than [intv_crit] appart
        intv_crit = 1; % critical distance for merging; in sec (before: 3 sec)
        isb = 1;
        while size(rejectDataIntervals,1) > 1 && isb < size(rejectDataIntervals,1)
            prev_minus_next = rejectDataIntervals(isb+1,1) - rejectDataIntervals(isb,2);
            if (prev_minus_next) < (intv_crit * EEG.srate)
                rejectDataIntervals(isb,2) = rejectDataIntervals(isb+1,2);
                rejectDataIntervals(isb+1,:) = [];
                isb = isb - 1;
            end
            isb = isb + 1 ;
        end

%     %    add one second before and after the artifact -> commented, TS 08/2019
%     for kk = 1:size(rejectDataIntervals,1) 
% 
%         if rejectDataIntervals(kk,1) - EEG.srate > EEG.srate*3 % if minusing is more than 3 seconds
%             rejectDataIntervals(kk,1) = rejectDataIntervals(kk,1) - EEG.srate; %start minus a second
%         else
%             rejectDataIntervals(kk,1) = 1;
%         end
% 
%         if rejectDataIntervals(kk,2) <= length(EEG.data)- EEG.srate
%             rejectDataIntervals(kk,2) = rejectDataIntervals(kk,2) + EEG.srate; %end plus 1 second
%         else
%             rejectDataIntervals(kk,2) = length(EEG.data);
%         end
%     end

%     % merge overlapping segments and segments that are less than [intv_crit] sec appart
%     intv_crit = 1;
%     isb = 1;
%     while size(rejectDataIntervals,1) > 1 && isb < size(rejectDataIntervals,1)
%         prev_minus_next = rejectDataIntervals(isb+1,1) - rejectDataIntervals(isb,2);
%         if (prev_minus_next) < (intv_crit * EEG.srate)
%             rejectDataIntervals(isb,2) = rejectDataIntervals(isb+1,2);
%             rejectDataIntervals(isb+1,:) = [];
%             isb = isb - 1;
%         end
%         isb = isb + 1 ;
%     end

        %     adjust the amplitude threshold before and after the bad
        %     segment> DELETED

    % mark them
    for ii = 1:size(rejectDataIntervals,1)
        n = length(EEG.event);
            EEG.event(n+1).latency = rejectDataIntervals(ii,1);
            EEG.event(n+1).duration = rejectDataIntervals(ii,2)-rejectDataIntervals(ii,1); % 
            EEG.event(n+1).type = 'auto_start';

            EEG.event(n+2).latency = rejectDataIntervals(ii,2);
            EEG.event(n+2).duration = 0;
            EEG.event(n+2).type = 'auto_end';
    end

%     EEG = eeg_checkset(EEG,'eventconsistency');   

    % display log
    %badPointsInSec = length(find(badPointsExpanded))*1000/EEG.srate/1000; %#ok<*NASGU>    
    badPointsInSec = sum(diff(rejectDataIntervals, [], 2))/EEG.srate;
    badPointsPerc = sum(diff(rejectDataIntervals, [], 2))/size(EEG.data,2);
    fprintf('\n Summary of automatic artifact rejection: \n with thresholds of %2.0f µV (low-frequency) and %2.0f µV (high-frequency) and a %2.0f ms spreading window, \n %2.1f sec have been rejected in total (%1.4f percent of the data). \n %1.0f artifact events added. \n', ...
        amplitudeThreshold, amplitudeThreshold_hf, windowSize, badPointsInSec, badPointsPerc, size(rejectDataIntervals,1));
else
    rejectDataIntervals = [];
    badPointsInSec = [];
    badPointsPerc = [];
    disp('No datapoint rejected.');
end
end
