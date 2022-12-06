% Author: Birgit Nierula
% nierula@cbs.mpg.de

function cnt_new = ecg_removeDoubleDetections(cnt)

%% removes qrs events that were detected several times
% find R-peaks
 qrs_idx = find(ismember({cnt.event.type}, 'qrs'));
 qrs_events = cnt.event(qrs_idx).latency;

%test version
%  qrs_idx = find(ismember({cnt.event.type}, 'qrs'));
%  qrs_events = nan(1,length(qrs_idx));
%  for qrs_idx = qrs_idx(1:end)
%      qrs_events(qrs_idx) = cnt.event(qrs_idx).latency;
%  end


% find difference
qrs_difference = diff(qrs_events);

% find those with 0 difference
double_idx = find(qrs_difference == 0);
if ~isempty(double_idx)
    disp(['### ' num2str(double_idx) ' events with the same latency detected ###'])
end

% remove double_idx events from cnt
counter = 1;
if ~isempty(double_idx)
    for ii = 1:size(cnt.event, 2)
        if ii == double_idx(counter)
            counter = counter + 1;
        else
            new_event = cnt.event(ii);
        end
    end
    cnt_new = cnt;
    cnt_new.event = new_event;
    cnt_new = eeg_checkset(cnt_new);
else
    cnt_new = cnt;
end