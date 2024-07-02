% Author: Ulrike Horn
% uhorn@cbs.mpg.de

function varargout = manual_rpeak_selection(varargin)
% MANUAL_RPEAK_SELECTION MATLAB code for manual_rpeak_selection.fig
%      MANUAL_RPEAK_SELECTION, by itself, creates a new MANUAL_RPEAK_SELECTION or raises the existing
%      singleton*.
%
%      H = MANUAL_RPEAK_SELECTION returns the handle to a new MANUAL_RPEAK_SELECTION or the handle to
%      the existing singleton*.
%
%      MANUAL_RPEAK_SELECTION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MANUAL_RPEAK_SELECTION.M with the given input arguments.
%
%      MANUAL_RPEAK_SELECTION('Property','Value',...) creates a new MANUAL_RPEAK_SELECTION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before manual_rpeak_selection_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to manual_rpeak_selection_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help manual_rpeak_selection

% Last Modified by GUIDE v2.5 28-Aug-2019 16:50:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @manual_rpeak_selection_OpeningFcn, ...
                   'gui_OutputFcn',  @manual_rpeak_selection_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before manual_rpeak_selection is made visible.
function manual_rpeak_selection_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to manual_rpeak_selection (see VARARGIN)

% Choose default command line output for manual_rpeak_selection
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

handles.data_path = getappdata(0,'data_path');
if ~isfile(handles.data_path)
    error('File not found')
end
[subj_path,name,~] = fileparts(handles.data_path);

set(handles.text2,'String','Select points where R peaks are missing or too much.');

% load ECG data with R peak events
handles.ecg = pop_loadset([name,'.set'],subj_path);

handles.data = handles.ecg.data;
handles.sr = handles.ecg.srate;
[~, idx] = ismember({handles.ecg.chanlocs.labels}, {'ECG'});
handles.ecg_channel = find(idx);
handles.data = double(handles.data);

% load R peaks
is_qrs_event = ismember ({handles.ecg.event.type}, 'qrs');
times = [handles.ecg.event.latency]; % in samples
handles.r_peaks = times(is_qrs_event);
handles.r_peaks_corr = handles.r_peaks; % copy for corrected data

% find reasonable time points to display (20s?)
num_starts = floor(length(handles.data)/handles.sr/20);
if num_starts==0 %shorter than 20s
    handles.cue_onsets = [1 round(length(handles.data)/2)];
else
    handles.cue_onsets = 1:20*handles.sr:num_starts*20*handles.sr+1;   
end

handles.curr_trial = 1;
handles.artifact_found = 0;
interval = [round(handles.cue_onsets(handles.curr_trial)):round(handles.cue_onsets(handles.curr_trial+1))];
plot_indx = find(handles.r_peaks>=interval(1)& handles.r_peaks<=interval(end));
axes(handles.plot1); % create plot window
datacursormode on;
guidata(hObject, handles);
cla; % clear plot content
plot(interval,handles.data(handles.ecg_channel,interval));
hold on
plot(handles.r_peaks(plot_indx),handles.data(handles.ecg_channel,handles.r_peaks(plot_indx)),'o', 'Color', 'r');
% generate the "text blocks"
ypos = double(max(handles.data(handles.ecg_channel,handles.r_peaks(plot_indx))));
ibi = diff(handles.r_peaks([plot_indx plot_indx(end)+1]));
text(handles.r_peaks(plot_indx)+0.1*handles.sr,repmat(ypos,size(ibi)),strcat(num2str(ibi','%.f')),'FontSize',9);    
hold off
xlabel({'time'});
ylabel({'ECG amplitude'});
handles.dcm_obj = datacursormode(gcf);
guidata(hObject, handles);

% UIWAIT makes manual_rpeak_selection wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = manual_rpeak_selection_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%     f = uifigure;
%     msg = 'Do you want to keep the changes?';
%     title = 'Confirm Save';
%     selection = uiconfirm(f,msg,title,...
%            'Options',{'Save','Discard'},...
%            'DefaultOption',2);
if handles.artifact_found
%     button = questdlg('Do you want to save this?','Confirmation');
%     if strcmpi(button, 'Yes')
       handles.r_peaks = handles.r_peaks_corr;
       handles.artifact_found = 0;
%     end
%     if strcmpi(button, 'No')
%        handles.r_peaks_corr = handles.r_peaks;
%        handles.artifact_found = 0;
%     end
end
set(handles.text2,'String','Select points where R peaks are missing or too much.');
if handles.curr_trial>=2
    handles.curr_trial = handles.curr_trial-1;
end
interval = [round(handles.cue_onsets(handles.curr_trial)):round(handles.cue_onsets(handles.curr_trial+1))];

plot_indx = find(handles.r_peaks>=interval(1)& handles.r_peaks<=interval(end));
% axes(handles.plot1); % create plot window
cla; % clear plot content
datacursormode on
plot(interval,handles.data(handles.ecg_channel,interval));
hold on
plot(handles.r_peaks(plot_indx),handles.data(handles.ecg_channel,handles.r_peaks(plot_indx)),'o', 'Color', 'r');
% generate the "text blocks"
ypos = double(max(handles.data(handles.ecg_channel,handles.r_peaks(plot_indx))));
ibi = diff(handles.r_peaks([plot_indx plot_indx(end)+1]));
text(handles.r_peaks(plot_indx)+0.1*handles.sr,repmat(ypos,size(ibi)),strcat(num2str(ibi','%.f')),'FontSize',9);
hold off
xlabel({'time'});
ylabel({'ECG amplitude'});
handles.dcm_obj = datacursormode(gcf);
guidata(hObject, handles);

% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.artifact_found
    %button = questdlg('Do you want to save this?','Confirmation');
    %if strcmpi(button, 'Yes')
       handles.r_peaks = handles.r_peaks_corr;
       handles.artifact_found = 0;
    %end
%     if strcmpi(button, 'No')
%        handles.r_peaks_corr = handles.r_peaks;
%        handles.artifact_found = 0;
%     end
end

set(handles.text2,'String','Select points where R peaks are missing or too much.');
if handles.curr_trial<length(handles.cue_onsets)
    handles.curr_trial = handles.curr_trial+1;
end
if handles.curr_trial==length(handles.cue_onsets)
    interval = [round(handles.cue_onsets(handles.curr_trial)):length(handles.data)];
else
    interval = [round(handles.cue_onsets(handles.curr_trial)):round(handles.cue_onsets(handles.curr_trial+1))];
end
plot_indx = find(handles.r_peaks>=interval(1)& handles.r_peaks<=interval(end));
% axes(handles.plot1); % create plot window
cla; % clear plot content
datacursormode on
plot(interval,handles.data(handles.ecg_channel,interval));
hold on
plot(handles.r_peaks(plot_indx),handles.data(handles.ecg_channel,handles.r_peaks(plot_indx)),'o', 'Color', 'r');
% generate the "text blocks"
ypos = double(max(handles.data(handles.ecg_channel,handles.r_peaks(plot_indx))));
if handles.curr_trial==length(handles.cue_onsets)
    % here you have to shorten the ibi by 1 because there is no next peak
    ibi = diff(handles.r_peaks(plot_indx));
    plot_indx(end)=[];
    text(handles.r_peaks(plot_indx)+0.1*handles.sr,repmat(ypos,size(ibi)),strcat(num2str(ibi','%.f')),'FontSize',9);
else
    ibi = diff(handles.r_peaks([plot_indx plot_indx(end)+1]));
    text(handles.r_peaks(plot_indx)+0.1*handles.sr,repmat(ypos,size(ibi)),strcat(num2str(ibi','%.f')),'FontSize',9);
end
hold off
xlabel({'time'});
ylabel({'ECG amplitude'});
handles.dcm_obj = datacursormode(gcf);
guidata(hObject, handles);


% --- Executes on button press in addbutton.
function addbutton_Callback(hObject, eventdata, handles)
% hObject    handle to addbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c_info = getCursorInfo(handles.dcm_obj);
if isempty(c_info)
    set(handles.text2,'String','You did not select anything.');
else
    handles.artifact_found = 1;
    num_peaks = length(c_info);
    % collect x values of new markers
    new = [c_info.Position];
    new(2:2:end)=[];
    % search for max value in +-50 ms window
%     range = [-0.05 0.05]*handles.sr; 
    range = [-0.1 0.1]*handles.sr; 
    for ii = 1:num_peaks
        bgn = new(ii) + range(1);
        enn = new(ii) + range(2);
        if enn <= size(handles.data, 2) && bgn > 0
            [~, ind] = max(handles.data(handles.ecg_channel, bgn:enn));
            new(ii) = bgn + ind -1;
        end
    end
    % TO DO insert some checks here
    % if there is a peak already --> warning?
    % then search for max within a tiny window
    handles.r_peaks_corr = sort([handles.r_peaks_corr new]);
    if handles.curr_trial==length(handles.cue_onsets)
        interval = [round(handles.cue_onsets(handles.curr_trial)):length(handles.data)];
    else
        interval = [round(handles.cue_onsets(handles.curr_trial)):round(handles.cue_onsets(handles.curr_trial+1))];
    end
    plot_indx = find(handles.r_peaks_corr>=interval(1)& handles.r_peaks_corr<=interval(end));
    cla; % clear plot content
    datacursormode on
    plot(interval,handles.data(handles.ecg_channel,interval));
    hold on
    plot(handles.r_peaks_corr(plot_indx),...
        handles.data(handles.ecg_channel,handles.r_peaks_corr(plot_indx)),'o', 'Color', 'r');
    hold off
    xlabel({'time'});
    ylabel({'ECG amplitude'});
    handles.dcm_obj = datacursormode(gcf);
    guidata(hObject, handles);
end


% --- Executes on button press in deletebutton.
function deletebutton_Callback(hObject, eventdata, handles)
% hObject    handle to deletebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c_info = getCursorInfo(handles.dcm_obj);
if isempty(c_info)
    set(handles.text2,'String','You did not select anything.');
else
    handles.artifact_found = 1;
    num_peaks = length(c_info);
    % collect x values of markers
    new = [c_info.Position];
    new(2:2:end)=[];
    for ipeak = 1:num_peaks
        % find closest and delete
        [~,idx]=min(abs(handles.r_peaks_corr - new(ipeak)));
        handles.r_peaks_corr(idx)=[];
    end
    if handles.curr_trial==length(handles.cue_onsets)
        interval = [round(handles.cue_onsets(handles.curr_trial)):length(handles.data)];
    else
        interval = [round(handles.cue_onsets(handles.curr_trial)):round(handles.cue_onsets(handles.curr_trial+1))];
    end
    plot_indx = find(handles.r_peaks_corr>=interval(1)& handles.r_peaks_corr<=interval(end));
    cla; % clear plot content
    datacursormode on
    plot(interval,handles.data(handles.ecg_channel,interval));
    hold on
    plot(handles.r_peaks_corr(plot_indx),...
        handles.data(handles.ecg_channel,handles.r_peaks_corr(plot_indx)),'o', 'Color', 'r');
    hold off
    xlabel({'time'});
    ylabel({'ECG amplitude'});
    handles.dcm_obj = datacursormode(gcf);
    guidata(hObject, handles);
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% if ~exist('handles.artifact_found','var')
%     delete(hObject);
% else
    if handles.artifact_found
        button = questdlg('Do you want to save this?','Confirmation');
        if strcmpi(button, 'Yes')
            handles.r_peaks = handles.r_peaks_corr;
            handles.artifact_found = 0;
        end
        if strcmpi(button, 'No')
            handles.r_peaks_corr = handles.r_peaks;
            handles.artifact_found = 0;
        end
    end
    button = questdlg('Do you want to save all your changes?','Confirmation');
    if strcmpi(button, 'Yes')
        % delete old R peak events
        is_qrs_event = ismember ({handles.ecg.event.type}, 'qrs');
        handles.ecg.event(is_qrs_event) = [];
        % and put new ones
        num_events = length(handles.ecg.event);
        for ii = 1:length(handles.r_peaks_corr)
            handles.ecg.event(num_events+ii).type = 'qrs';
            handles.ecg.event(num_events+ii).latency = handles.r_peaks_corr(ii);
            handles.ecg.event(num_events+ii).urevent = num_events + ii;
        end
        % check for consistency and sort them
        handles.ecg = eeg_checkset(handles.ecg,'eventconsistency');
        
        % save ECG data with R peak events
        [subj_path,name,~]= fileparts(handles.data_path);
        % if this is already a manually corrected one
        % you should ask whether you want to overwrite it
        if contains(name,'_mancorr')
            button = questdlg('Do you want to overwrite the old file?','Confirmation');
            if strcmpi(button, 'Yes')
                new_file_name = [name,'.set'];
            end
            if strcmpi(button, 'No')
                new_file_name = [name,'1.set'];
            end
        else
            new_file_name = [name,'_mancorr.set'];
        end
        % if it is a baseline scan save new baseline values for IBI
        if contains(name,'baseline')
            avg_ibi_baseline = round(mean(diff(handles.r_peaks_corr)))/handles.sr;
            std_ibi_baseline = round(std(diff(handles.r_peaks_corr)))/handles.sr;
            save(fullfile(subj_path,'baseline_values.mat'),...
                'avg_ibi_baseline','std_ibi_baseline')
            fprintf('Baseline values have been updated \n')
        end
        % save data set
        handles.ecg = pop_saveset(handles.ecg, 'filename', ...
            new_file_name, 'filepath', subj_path);
        delete(hObject);
    end
    if strcmpi(button, 'No')
        delete(hObject);
    end
% end


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close

