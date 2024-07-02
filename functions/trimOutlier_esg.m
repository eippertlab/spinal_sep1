%% Modified from trimOutlier() %%

function [EEG, artifact_info] = trimOutlier_esg(EEG, amplitudeThreshold, pointSpreadWidth)

if ~(nargin==3)
    error('trimOutlier_adjust() requires 3 input arguments.')
end

% return if 3-D
if length(size(EEG.data))==3
    disp('Epoched data detected: datapoint rejection will not be performed.')
    return
end


%% remove bad datapoints

% obtain the window size
windowSize = pointSpreadWidth; % millisecond
windowSizeInFrame = round(windowSize/(1000/EEG.srate)); % frames

% compute bad datapoints
abs_esg = abs(EEG.data(:,:));
sum_points = abs_esg > amplitudeThreshold;
bad_points = sum_points ~= 0;

n_chans = EEG.nbchan;
badchan_counter = 0;

merged_ivals = [];
badchan_name = {};

if any(sum(bad_points, 2))
    % expand badPoints
    for ichan = 1:n_chans
        badPointsExpanded = logical(conv(single(bad_points(ichan,:)), ones(1,windowSizeInFrame), 'same'));
        tmp = reshape(find(diff([false badPointsExpanded false])),2,[])';
        tmp(:,2) = tmp(:,2)-1;
        
        % sort
        [~,idx] = sort(tmp(:,1)); % sort just the first column
        tmp = tmp(idx,:);
        
        % merge overlapping segments and segments that are less than 1sec appart
        isb = 1;
        while size(tmp,1) > 1 && isb < size(tmp,1)
            prev_minus_next = tmp(isb+1,1) - tmp(isb,2);
            if (prev_minus_next) < (1 * EEG.srate)
                tmp(isb,2) = tmp(isb+1,2);
                tmp(isb+1,:) = [];
                isb = isb - 1;
            end
            isb = isb + 1 ;
        end
        
        % add time before and after the artifact
        for kk = 1:size(tmp,1)
            
            if tmp(kk,1) - EEG.srate > EEG.srate*3 % if minusing is more than 3 seconds
                tmp(kk,1) = tmp(kk,1) - EEG.srate/2; %start minus half a second
            else
                tmp(kk,1) = 1;
            end
            
            if tmp(kk,2) <= length(EEG.data)- EEG.srate
                tmp(kk,2) = tmp(kk,2) + EEG.srate/2; %end plus half a second
            else
                tmp(kk,2) = length(EEG.data);
            end
        end
        
        % merge overlapping segments and segments that are less than 1sec appart
        isb = 1;
        while size(tmp,1) > 1 && isb < size(tmp,1)
            prev_minus_next = tmp(isb+1,1) - tmp(isb,2);
            if (prev_minus_next) < (1 * EEG.srate)
                tmp(isb,2) = tmp(isb+1,2);
                tmp(isb+1,:) = [];
                isb = isb - 1;
            end
            isb = isb + 1 ;
        end
        
        % identify bad channels
        tmp_rejected = sum(tmp(:,2) - tmp(:,1));
        rej_ratio(ichan) = tmp_rejected / size(bad_points, 2);
        if rej_ratio(ichan) >= 0.5
            dataIntervals_bychan{ichan} = [];
            badchan_counter = badchan_counter + 1;
            badchan_name{badchan_counter} = EEG.chanlocs(ichan).labels;
        else
            dataIntervals_bychan{ichan} = tmp;
            % merge data ivals
            if isempty(merged_ivals)
                merged_ivals = tmp;
            else
                merged_ivals = [merged_ivals; tmp];
            end
        end
        clear tmp badPointsExpanded
    end

    % sort
    [~,idx] = sort(merged_ivals(:,1)); % sort just the first column
    merged_ivals = merged_ivals(idx,:);
        
    % merge overlapping segments or those that are less than 1 sec apart
    idx = 1;
    while size(merged_ivals,1) > 1 && idx < size(merged_ivals,1)
        prev_minus_next = merged_ivals(idx+1,1) - merged_ivals(idx,2);
        if (prev_minus_next) < (1 * EEG.srate)
            merged_ivals(idx,2) = merged_ivals(idx+1,2);
            merged_ivals(idx+1,:) = [];
            idx = idx - 1;
        end
        idx = idx + 1 ;
    end
    
    rejectDataIntervals = merged_ivals;

    
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
    badPointsInSec = sum(rejectDataIntervals(:,2)-rejectDataIntervals(:,1))*1000/EEG.srate/1000; 
    recordingInSec = EEG.pnts / EEG.srate;
    disp('*****************************')
    fprintf(['Threshold: %2.0f' char(181) 'V; \n spreading: %2.0fms; \n rejected: %2.1fsec (%2.1f %%); \n added boundaries: %2.0f; \n removed channels: %s\n'], ...
        amplitudeThreshold, ...
        windowSize, ...
        badPointsInSec, ...
        badPointsInSec / recordingInSec * 100, ...
        size(rejectDataIntervals,1), ...
        [badchan_name{:}]);
    disp('*****************************')
    
    artifact_info.lf_threshold = amplitudeThreshold;
    artifact_info.windowSize = windowSize;
    artifact_info.rejectedSeconds = badPointsInSec;
    artifact_info.rejectedPercentage = badPointsInSec / recordingInSec * 100;
    artifact_info.addedBoundaries = size(rejectDataIntervals,1);
    artifact_info.rejectDataIntervals = rejectDataIntervals;
    artifact_info.rejectedChannels = badchan_name;
else
    disp('No datapoint rejected.');
    artifact_info.lf_threshold = amplitudeThreshold;
    artifact_info.windowSize = windowSize;
    artifact_info.rejectedSeconds = [];
    artifact_info.rejectedPercentage = [];
    artifact_info.addedBoundaries = [];
    artifact_info.rejectDataIntervals = [];
    artifact_info.rejectedChannels = [];
    disp('No datapoint rejected.');
end

