function varargout = PM_tester_GUI(varargin)
% PM_TESTER_GUI MATLAB code for PM_tester_GUI.fig
%      PM_TESTER_GUI, by itself, creates a new PM_TESTER_GUI or raises the existing
%      singleton*.
%
%      H = PM_TESTER_GUI returns the handle to a new PM_TESTER_GUI or the handle to
%      the existing singleton*.
%
%      PM_TESTER_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PM_TESTER_GUI.M with the given input arguments.
%
%      PM_TESTER_GUI('Property','Value',...) creates a new PM_TESTER_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before PM_tester_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to PM_tester_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PM_tester_GUI

% Last Modified by GUIDE v2.5 29-Jul-2014 13:58:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PM_tester_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @PM_tester_GUI_OutputFcn, ...
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

import mbed.*;
%variable to store all the locations of the test files
global test_file_pathList
global dataArray
global datafile
global testRows
test_file_pathList = containers.Map;

% --- Executes just before PM_tester_GUI is made visible.
function PM_tester_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to PM_tester_GUI (see VARARGIN)

% Choose default command line output for PM_tester_GUI
handles.output = hObject;
set(hObject,'Name','Pacemaker Testing Platform');
% Update handles structure
guidata(hObject, handles);

%Populate Serial Port drop menu if serial ports are available
s = instrhwinfo('serial');
ports = s.SerialPorts;
if ~isempty(ports)
    pacemakerPorts = ports;
    pacemakerPorts = [pacemakerPorts;{'Pacemaker'}];
    set(handles.pacemaker_menu,'String',pacemakerPorts);
    set(handles.pacemaker_menu,'Value',length(pacemakerPorts));   
end

%Initialize the percent complete text
set(handles.tests_Complete_Percentage,'String','0%');

%allow for multiline input in the report log
set(handles.reportLog,'Max',5);
set(handles.reportLog,'Min',2);

%allow for multiline input in the test edit infor
set(handles.testedit,'Max',5);
set(handles.testedit,'Min',2);

%%TODO: add workspace import option

%Initialize the Axes
plotinAx(hObject,eventdata,handles);

%Initialize testList
testList = containers.Map;
set(handles.test_list,'UserData',testList)

%Initialize the listboxes
set(handles.test_list,'String',{});
set(handles.tests_selected,'String',{});


% UIWAIT makes PM_tester_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = PM_tester_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in start_Button.
function start_Button_Callback(hObject, eventdata, handles)
% hObject    handle to start_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global mymbed;
global complete;
global atrial_tolerance;
global ventrical_tolerance;
global test_file_pathList;
global testRows;
%global dataFile;
global dataArray
global RPC_struct;

state = get(hObject,'Value');
%if start button was pressed
if state == get(hObject,'Max')
    set(hObject,'String','Stop');
    set(handles.reportLog,'String','');
    set(handles.tests_Complete_Percentage,'String','0%');
    set(handles.reportLog,'ForegroundColor','k');
    complete = 0;
     
    %get the test parameter data
        %info for atrial tolerance
        atrial_tolerance = get(handles.atrial_tolerance_editText,'String');
        if isempty(atrial_tolerance)
            atrial_tolerance = 0;
        end
        atrial_tolerance = char(atrial_tolerance);
        if isempty(str2num(atrial_tolerance))
            errordlg('please provide an appropriate value for the atrial tolerance');
        end

        %info for ventricular tolerance
        ventrical_tolerance = get(handles.ventricular_tolerance_editText,'String');
        if isempty(ventrical_tolerance)
            ventrical_tolerance = 0;
        end
        ventrical_tolerance = char(ventrical_tolerance);
        if isempty(str2num(ventrical_tolerance))
            errordlg('please provide an appropriate value for the ventricular tolerance');
        end

        %info for offset
        ifOffset = get(handles.offset_adjustment_checkBox,'Value');
        
        %test files to be used
        alltests = cellstr(get(handles.tests_selected,'String'));
        testList = get(handles.test_list,'UserData');
        
    if strcmp(get(get(handles.tester_choice,'SelectedObject'),'String'),'Simulation')
        
        for f = 1:length(alltests)
            get(handles.reportLog,'Value')
            set(handles.reportLog,'ListboxTop',20);
            set(handles.reportLog,'ForegroundColor','k');
            filename = alltests{f};
            %test_file_pathList
            pathname = testList(filename);
            
            load('initializer.mat');
            load('pm_New_George.mat');
            %display the test file in the log
            currReport = cellstr(get(handles.reportLog,'String'));
            currReport{end+1}=filename;
            set(handles.reportLog,'String',currReport);
            
            %check if it is a .mat file
            [path, file, ext] = fileparts(pathname);
            if strcmp(ext,'.mat')
                load(pathname);
                sample_File = eval(filename);
            elseif strcmp(ext,'.txt')
                sample_File = [pathname,filename];
                fid = fopen(sample_File);
                sample_File = fscanf(fid,'%d %d',[2,inf])';
            else
                errordlg(['Unsupported file format ''',ext,'''']);
            end
            
            set(handles.testedit,'String',filename);
            currReport= cellstr(get(handles.testedit,'String'));
            currReport{end+1}=sprintf('time (ms)\tevent');
            set(handles.testedit,'String',currReport);

            for i = 1:size(sample_File,1)
                str ='';
                str = [str,num2str(sample_File(i,1))];
                switch sample_File(i,2)
                    case 1
                        str = sprintf([str,'\tAtrial Input']); 
                    case 2
                        str = sprintf([str,'\tVentricular Input']); 
                    case 3
                        str = sprintf([str,'\tAtrial Output']); 
                    case 4
                        str = sprintf([str,'\tVentricular Output']); 
                end
                currReport= cellstr(get(handles.testedit,'String'));
                currReport{end+1}=str;
                set(handles.testedit,'String',currReport);
            end
            
            
            pacemaker_tester_simulator_GUI(hObject,eventdata,handles,sample_File,initializer,pace_param,'tolerances'...
                                            ,[str2num(atrial_tolerance),str2num(ventrical_tolerance)],'allowOffset',ifOffset,...
                                            'plotTitle',filename);
            hold off;
            percent_complete = num2str(f/length(alltests)*100);
            set(handles.tests_Complete_Percentage,'String',[percent_complete,'%']);
            pause(0.05);
        end
        set(hObject,'Value',get(hObject,'Min'))
        set(hObject,'String','Start');
        
    else
        RPCInit(get(handles.ip_address,'String'),9999);        
 
        %%initialize the board
        RPCWrite('tolerance_atrial',str2double(atrial_tolerance));
        RPCWrite('tolerance_ventrical',str2double(ventrical_tolerance));
        RPCWrite('allowOffsets',ifOffset);

        %%TODO: Generate an initializer file
        while(RPC_struct.udp_handle.BytesAvailable)%this is to clear the data in network waiting
            fscanf(RPC_struct.udp_handle);
        end
        for f = 1:length(alltests)
            set(handles.reportLog,'ForegroundColor','k');
            RPCCall('reset');
 
            %%initialize the board
            RPCWrite('tolerance_atrial',str2double(atrial_tolerance));
            RPCWrite('tolerance_ventrical',str2double(ventrical_tolerance));
            RPCWrite('allowOffsets',ifOffset);       
            filename = alltests{f};
            pathname = testList(filename);
            
            %display the test file in the log
            currReport= get(handles.reportLog,'String');
            currReport{end+1}=filename;
            set(handles.reportLog,'String',currReport);
            
            %check if it is a .mat file
            [path, file, ext] = fileparts(pathname);
            if strcmp(ext,'.mat')
                load(pathname);
                sample_File = eval(filename);
            elseif strcmp(ext,'.txt')
                sample_File = [pathname,filename];
                fid = fopen(sample_File);
                sample_File = fscanf(fid,'%d %d',[2,inf])';
            else
                errordlg(['Unsupported file format ''',ext,'''']);
            end
        
            
            set(handles.testedit,'String',filename);
            currReport= cellstr(get(handles.testedit,'String'));
            currReport{end+1}=sprintf('time (ms)\tevent');
            set(handles.testedit,'String',currReport);
            for i = 1:size(sample_File,1)
                str ='';
                str = [str,num2str(sample_File(i,1))];
                switch sample_File(i,2)
                    case 1
                        str = sprintf([str,'\tAtrial Input']); 
                    case 2
                        str = sprintf([str,'\tVentricular Input']); 
                    case 3
                        str = sprintf([str,'\tAtrial Output']); 
                    case 4
                        str = sprintf([str,'\tVentricular Output']); 
                end
                currReport= cellstr(get(handles.testedit,'String'));
                currReport{end+1}=str;
                set(handles.testedit,'String',currReport);
            end
            
            testRows = size(sample_File,1);            
            currReport= get(handles.reportLog,'String');
            currReport{end+1}='Sending Test Data';
            set(handles.reportLog,'String',currReport);
            disp('Sending Test Data');  
            sample_file_extended=sample_File;
            sample_file_extended(:,end+1)=1;
            RPCWrite('rows',testRows);
            RPCWrite('testData',sample_file_extended);
            %%TODO: Incorporate initializer file.
            dataArray = zeros(testRows,3);
            %start the test
            complete=0;
            RPC_struct.udp_handle.DatagramReceivedFcn=@get_datagram;
            RPCCall('start');
    
            %% wait for board to create report
            while(~complete)
                pause(0.1);
            end
            RPC_struct.udp_handle.DatagramReceivedFcn='';
            %dat=RPCRead('testData',testRows,3);
            dat=dataArray;
            printResults_GUI(hObject, eventdata, handles,dat,sample_File,ifOffset,filename);
            
            currReport= get(handles.reportLog,'String');
            currReport{end+1}='';
            set(handles.reportLog,'String',currReport);
            
            %%TODO:get the report log working!
            %{
            currReport= get(handles.reportLog,'String')
            currReport{end+1}='something';
            set(handles.reportLog,'String',currReport);
            %}
            %%TODO: get the percent_complete text working!
            percent_complete = num2str(f/length(alltests)*100);
            set(handles.tests_Complete_Percentage,'String',[percent_complete,'%']);
   %         set(mymbed.SerialCon,'BytesAvailableFcn','');
        end
        set(hObject,'Value',get(hObject,'Min'))
        set(hObject,'String','Start');
    end
    %set(hObject,'String','Start');
    
 % if button was turned off   
elseif state == get(hObject,'Min')
   
   set(hObject,'String','Start');
   if (~strcmp(get(get(handles.tester_choice,'SelectedObject'),'String'),'Simulation'))
        RPCClose();
   end
   disp('test ended'); 
end

function get_datagram(hObject,~)
global testRows complete dataArray
    temp_value=fscanf(hObject);
    if(temp_value(1)=='E')
        disp('ERROR reading variable');
    else
        temp_value=str2double(strsplit(temp_value,','));
        dataArray=zeros(testRows,3);
        for i=1:testRows,
            for j=1:3,
                dataArray(i,j)=temp_value((i-1)*3+j);
            end
        end
    end
    complete=1;
% Hint: get(hObject,'Value') returns toggle state of start_Button

%%

% --- Executes during object creation, after setting all properties.
function reportLog_CreateFcn(hObject, eventdata, handles)
% hObject    handle to reportLog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on selection change in serial_port_select.
function serial_port_select_Callback(hObject, eventdata, handles)
% hObject    handle to serial_port_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns serial_port_select contents as cell array
%        contents{get(hObject,'Value')} returns selected item from serial_port_select


% --- Executes during object creation, after setting all properties.
function serial_port_select_CreateFcn(hObject, eventdata, handles)
% hObject    handle to serial_port_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in save_button.
function save_button_Callback(hObject, eventdata, handles)
% hObject    handle to save_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resultTest = get(handles.reportLog,'String')
[filename pathname] = uiputfile('*.txt')
fileID = fopen([pathname,filename],'w')
for i=1:length(resultTest)
    fprintf(fileID,'%s\n',resultTest{i});
end
fclose(fileID);

% --- Executes on button press in remove_Button.
function remove_Button_Callback(hObject, eventdata, handles)
% hObject    handle to remove_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
testNo = get(handles.tests_selected,'Value')
%testSelectList = get(handles.tests_selected,'String');
%testToRemove = testSelectList{testNo};
old_test_selected_list = cellstr(get(handles.tests_selected,'String'))
%new_test_selected_list = cell(length(old_test_selected_list)-1,1); 
new_test_selected_list = cell(0);

for i = 1:length(old_test_selected_list)
    add = 1;
    for j = 1:length(testNo)
        if i == testNo(j)
            add = 0;
            %continue
        end  
    end
    if add
        new_test_selected_list = [new_test_selected_list;old_test_selected_list{i}];
    end
end
new_test_selected_list
set(handles.tests_selected,'String',new_test_selected_list);
set(handles.tests_selected,'Value',length(new_test_selected_list));

% --- Executes on button press in addButton.
function addButton_Callback(hObject, eventdata, handles)
% hObject    handle to addButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
testNo = get(handles.test_list,'Value');
testNo
testList = cellstr(get(handles.test_list,'String'));
testList

test = testList(testNo(1):testNo(end))

initial_test_selected_list = cellstr(get(handles.tests_selected,'String'))
if isempty(initial_test_selected_list)
    new_test_selected_list = test;
else
    new_test_selected_list = [initial_test_selected_list;test(1:end)]
end
set(handles.tests_selected,'String',new_test_selected_list);
set(handles.tests_selected,'Value',length(new_test_selected_list));


% --- Executes on selection change in tests_selected.
function tests_selected_Callback(hObject, eventdata, handles)
% hObject    handle to tests_selected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tests_selected contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tests_selected

testList = get(handles.test_list,'UserData');
filename = cellstr(get(handles.tests_selected,'String'));
testNo = get(handles.tests_selected,'Value');
filename = filename{testNo};

%check if it is a .mat file
pathname = testList(filename);
[path, file, ext] = fileparts(pathname);

set(handles.testedit,'String',filename);
currReport= cellstr(get(handles.testedit,'String'));
currReport{end+1}=sprintf('time (ms)\tevent');
set(handles.testedit,'String',currReport);

if strcmp(ext,'.mat')
    load(pathname);
    sample_File = eval(filename);
elseif strcmp(ext,'.txt')
    sample_File = [pathname,filename];
    fid = fopen(sample_File);
    sample_File = fscanf(fid,'%d %d',[2,inf])';
else
    currReport= cellstr(get(handles.testedit,'String'));
    currReport{end+1}='Unsupported file format';
    set(handles.reportLog,'String',currReport);
    disp(['Unsupported file format ''',ext,'''']);
    return
end
for i = 1:size(sample_File,1)
    str ='';
    str = [str,num2str(sample_File(i,1))];
    switch sample_File(i,2)
        case 1
            str = sprintf([str,'\tAtrial Input']); 
        case 2
            str = sprintf([str,'\tVentricular Input']); 
        case 3
            str = sprintf([str,'\tAtrial Output']); 
        case 4
            str = sprintf([str,'\tVentricular Output']); 
    end
    currReport= cellstr(get(handles.testedit,'String'));
    currReport{end+1}=str;
    set(handles.testedit,'String',currReport);
end

            

% --- Executes during object creation, after setting all properties.
function tests_selected_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tests_selected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in test_list.
function test_list_Callback(hObject, eventdata, handles)
% hObject    handle to test_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns test_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from test_list
testList = get(handles.test_list,'UserData');
filename = cellstr(get(handles.test_list,'String'));
testNo = get(handles.test_list,'Value');
filename = filename{testNo};

%check if it is a .mat file
pathname = testList(filename);
[path, file, ext] = fileparts(pathname);

set(handles.testedit,'String',filename);
currReport= cellstr(get(handles.testedit,'String'));
currReport{end+1}=sprintf('time (ms)\tevent');
set(handles.testedit,'String',currReport);

if strcmp(ext,'.mat')
    load(pathname);
    sample_File = eval(filename);
elseif strcmp(ext,'.txt')
    sample_File = [pathname,filename];
    fid = fopen(sample_File);
    sample_File = fscanf(fid,'%d %d',[2,inf])';
else
    currReport= cellstr(get(handles.testedit,'String'));
    currReport{end+1}='Unsupported file format';
    set(handles.reportLog,'String',currReport);
    disp(['Unsupported file format ''',ext,'''']);
    return
end
for i = 1:size(sample_File,1)
    str ='';
    str = [str,num2str(sample_File(i,1))];
    switch sample_File(i,2)
        case 1
            str = sprintf([str,'\tAtrial Input']); 
        case 2
            str = sprintf([str,'\tVentricular Input']); 
        case 3
            str = sprintf([str,'\tAtrial Output']); 
        case 4
            str = sprintf([str,'\tVentricular Output']); 
    end
    str
    currReport= cellstr(get(handles.testedit,'String'));
    currReport{end+1}=str;
    set(handles.testedit,'String',currReport);
end


% --- Executes during object creation, after setting all properties.
function test_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to test_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function reportLog_Callback(hObject, eventdata, handles)
% hObject    handle to reportLog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of reportLog as text
%        str2double(get(hObject,'String')) returns contents of reportLog as a double


% --- Executes on button press in importButton.
%this deals with importing test files to the workspace
function importButton_Callback(hObject, eventdata, handles)
% hObject    handle to importButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global test_file_pathList

testList = get(handles.test_list,'UserData');

[filename,pathname,filterIndex] = uigetfile;
[~,~,ext] = fileparts(filename);
if strcmp(ext,'.mat')
    pathname = [pathname,filename];
    currVariables = who;
    currVariables = [currVariables;{'currVariables'}];
    load(pathname);
    newVariables = who;
    fileVariables = cell(0,0);
    % remove variable names that were previously in the workspace
    for i=1:length(newVariables)
        dontAdd = 0;
        for j=1:length(currVariables)
            if strcmp(newVariables{i},currVariables{j})
                dontAdd = 1;
            end  
        end
        if ~dontAdd
            fileVariables = [fileVariables;newVariables(i)];
        end
    end
    for i=1:length(fileVariables)
        test_file_pathList(fileVariables{i}) = pathname;
        testList(fileVariables{i}) = pathname
    end
    initial_test_list = cellstr(get(handles.test_list,'String'))
    if isempty(initial_test_list)
        new_test_list = fileVariables;
    else
        new_test_list = [initial_test_list;fileVariables];
    end
    set(handles.test_list,'String',new_test_list);
    set(handles.test_list,'UserData',testList);
    return
else
    test_file_pathList(filename) = pathname;
    testList(filename) = pathname;
    initial_test_list = cellstr(get(handles.test_list,'String'));
    new_test_list = [initial_test_list;{filename}];
    set(handles.test_list,'String',new_test_list);
    set(handles.test_list,'UserData',testList);
end




function spec_data_text_Callback(hObject, eventdata, handles)
% hObject    handle to spec_data_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of spec_data_text as text
%        str2double(get(hObject,'String')) returns contents of spec_data_text as a double


% --- Executes during object creation, after setting all properties.
function spec_data_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to spec_data_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in all_signalButton.
function all_signalButton_Callback(hObject, eventdata, handles)
% hObject    handle to all_signalButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of all_signalButton



function atrial_tolerance_editText_Callback(hObject, eventdata, handles)
% hObject    handle to atrial_tolerance_editText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of atrial_tolerance_editText as text
%        str2double(get(hObject,'String')) returns contents of atrial_tolerance_editText as a double


% --- Executes during object creation, after setting all properties.
function atrial_tolerance_editText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to atrial_tolerance_editText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ventricular_tolerance_editText_Callback(hObject, eventdata, handles)
% hObject    handle to ventricular_tolerance_editText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ventricular_tolerance_editText as text
%        str2double(get(hObject,'String')) returns contents of ventricular_tolerance_editText as a double


% --- Executes during object creation, after setting all properties.
function ventricular_tolerance_editText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ventricular_tolerance_editText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in offset_adjustment_checkBox.
function offset_adjustment_checkBox_Callback(hObject, eventdata, handles)
% hObject    handle to offset_adjustment_checkBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of offset_adjustment_checkBox


% --- Executes on button press in refresh_ports_button.
function refresh_ports_button_Callback(hObject, eventdata, handles)
% hObject    handle to refresh_ports_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
serial = instrhwinfo('serial');
pacemakerPorts = [serial.SerialPorts;{'Simulation'};{'Pacemaker'}];
if ~isempty(ports)
    set(handles.pacemaker_menu,'String',pacemakerPorts);
end


% --- Executes on button press in pacemaker_button.
function pacemaker_button_Callback(hObject, eventdata, handles)
% hObject    handle to pacemaker_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global mybed
import mbed.*
comport = get(handles.pacemaker_menu,'String');
comportNo = get(handles.pacemaker_menu,'Value');
comport = comport{comportNo};
delete(instrfind({'Port'},{comport}))
try
    mybed = SerialRPC(comport, 9600);
    % myled = DigitalOut(mymbed, LED1);
    %tie to that object in MATLAB
    %dout3 = DigitalOut(mymbed,'blueLED');
    %Read and Write to a variable on mbed
    mybed.reset;
    pause(0.01);
catch 
end

pace_param.PAAB= get(handles.PAABedit,'String');
pace_param.PAARP= get(handles.PAARPedit,'String');
pace_param.PAVB= get(handles.PAVBedit,'String');
pace_param.PVAB=  get(handles.PVABedit,'String');
pace_param.PVARP= get(handles.PVARPedit,'String');
pace_param.PVVB= get(handles.PVVBedit,'String');
pace_param.PVVRP = get(handles.PVVRPedit,'String');
pace_param.VSP_thresh= get(handles.VSPedit,'String');
pace_param.PVARP_def=  get(handles.PVARPedit,'String');
pace_param.TAVI= get(handles.AVIedit,'String');
pace_param.TURI= get(handles.URIedit,'String');
pace_param.TLRI=  get(handles.LRIedit,'String');
pace_param.setup = 0;

PAAB = RPCVariable(mybed, 'PAAB');
PAARP = RPCVariable(mybed, 'PAARP');
PAVB = RPCVariable(mybed, 'PAVB');
PVAB = RPCVariable(mybed, 'PVAB');
PVARP = RPCVariable(mybed, 'PVARP');
PVVB = RPCVariable(mybed, 'PVVB');
PVVRP = RPCVariable(mybed,'PVVRP');
VSP_thresh = RPCVariable(mybed, 'VSP_thresh');
PVARP_def = RPCVariable(mybed, 'PVARP_def');
TAVI = RPCVariable(mybed, 'TAVI');
TURI = RPCVariable(mybed, 'TURI');
TLRI = RPCVariable(mybed, 'TLRI');
setup = RPCVariable(mybed, 'setup');


%setup.write('1');
pause(0.05);

PAAB.write(pace_param.PAAB);
pause(0.05);

PAARP.write(pace_param.PAARP);
pause(0.05);

PAVB.write(pace_param.PAVB);
pause(0.05);

PVAB.write(pace_param.PVAB);
pause(0.05);

PVARP.write(pace_param.PVARP);
pause(0.05);

PVVB.write(pace_param.PVVB);
pause(0.05);

PVVRP.write(pace_param.PVVRP);
pause(0.05);

VSP_thresh.write(pace_param.VSP_thresh);
pause(0.05);

PVARP_def.write(pace_param.PVARP_def);
pause(0.05);

TAVI.write(pace_param.TAVI);
pause(0.05);

TURI.write(pace_param.TURI);
pause(0.05);

TLRI.write(pace_param.TLRI);
pause(0.05);

% double check
check_PAAB = str2double(PAAB.read());
if check_PAAB == str2num(pace_param.PAAB)
    disp('PAAB good');
else
    fprintf(2,'PAAB bad\n')
end

check_PAARP = str2double(PAARP.read());
if check_PAARP == str2num(pace_param.PAARP)
    disp('PAARP good');
else
    fprintf(2,'PAARP bad\n')
end

check_PAVB = str2double(PAVB.read());
if check_PAVB == str2num(pace_param.PAVB)
    disp('PAVB good');
else
    fprintf(2,'PAVB bad\n')
end

check_PVAB = str2double(PVAB.read());
if check_PVAB == str2num(pace_param.PVAB)
    disp('PVAB good');
else
    fprintf(2,'PVAB bad\n')
end

check_PVARP = str2double(PVARP.read());
if check_PVARP == str2num(pace_param.PVARP)
    disp('PVARP good');
else
    fprintf(2,'PVARP bad\n')
end

check_PVVB = str2double(PVVB.read());
if check_PVAB == str2num(pace_param.PVAB)
    disp('PVVB good');
else
    fprintf(2,'PVVB bad\n')
end

check_PVVRP = str2double(PVVRP.read());
if check_PVVRP == str2num(pace_param.PVVRP)
    disp('PVVRP good');
else
    fprintf(2,'PVVRP bad\n')
end

check_VSP_thresh = str2double(VSP_thresh.read());
if check_VSP_thresh == str2num(pace_param.VSP_thresh)
    disp('VSP_thresh good');
else
    fprintf(2,'VSP_thresh bad\n')
end

check_PVARP_def = str2double(PVARP_def.read());
if check_PVARP_def == str2num(pace_param.PVARP_def)
    disp('PVARP good');
else
    fprintf(2,'PVARP bad\n')
end

check_TAVI = str2double(TAVI.read());
if check_TAVI == str2num(pace_param.TAVI)
    disp('TAVI good');
else
    fprintf(2,'TAVI bad\n')
end

check_TURI = str2double(TURI.read());
if check_TURI == str2num(pace_param.TURI)
    disp('TURI good');
else
    fprintf(2,'TURI bad\n')
end
check_TLRI = str2double(TLRI.read());
if check_TLRI == str2num(pace_param.TLRI)
    disp('TLRI good');
else
    fprintf(2,'TLRI bad\n')
end

%check_
pause(0.01);
setup.write('1');
%mybed.delete

% --- Executes on selection change in pacemaker_menu.
function pacemaker_menu_Callback(hObject, eventdata, handles)
% hObject    handle to pacemaker_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pacemaker_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pacemaker_menu


% --- Executes during object creation, after setting all properties.
function pacemaker_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pacemaker_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function PAABedit_Callback(hObject, eventdata, handles)
% hObject    handle to PAABedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PAABedit as text
%        str2double(get(hObject,'String')) returns contents of PAABedit as a double


% --- Executes during object creation, after setting all properties.
function PAABedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PAABedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function PAARPedit_Callback(hObject, eventdata, handles)
% hObject    handle to PAARPedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PAARPedit as text
%        str2double(get(hObject,'String')) returns contents of PAARPedit as a double


% --- Executes during object creation, after setting all properties.
function PAARPedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PAARPedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function PVABedit_Callback(hObject, eventdata, handles)
% hObject    handle to PVABedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PVABedit as text
%        str2double(get(hObject,'String')) returns contents of PVABedit as a double


% --- Executes during object creation, after setting all properties.
function PVABedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PVABedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function PAVBedit_Callback(hObject, eventdata, handles)
% hObject    handle to PAVBedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PAVBedit as text
%        str2double(get(hObject,'String')) returns contents of PAVBedit as a double


% --- Executes during object creation, after setting all properties.
function PAVBedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PAVBedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function PVARPedit_Callback(hObject, eventdata, handles)
% hObject    handle to PVARPedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PVARPedit as text
%        str2double(get(hObject,'String')) returns contents of PVARPedit as a double


% --- Executes during object creation, after setting all properties.
function PVARPedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PVARPedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function PVVBedit_Callback(hObject, eventdata, handles)
% hObject    handle to PVVBedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PVVBedit as text
%        str2double(get(hObject,'String')) returns contents of PVVBedit as a double


% --- Executes during object creation, after setting all properties.
function PVVBedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PVVBedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function PVVRPedit_Callback(hObject, eventdata, handles)
% hObject    handle to PVVRPedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PVVRPedit as text
%        str2double(get(hObject,'String')) returns contents of PVVRPedit as a double


% --- Executes during object creation, after setting all properties.
function PVVRPedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PVVRPedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function VSPedit_Callback(hObject, eventdata, handles)
% hObject    handle to VSPedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of VSPedit as text
%        str2double(get(hObject,'String')) returns contents of VSPedit as a double


% --- Executes during object creation, after setting all properties.
function VSPedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VSPedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AVIedit_Callback(hObject, eventdata, handles)
% hObject    handle to AVIedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AVIedit as text
%        str2double(get(hObject,'String')) returns contents of AVIedit as a double


% --- Executes during object creation, after setting all properties.
function AVIedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AVIedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function URIedit_Callback(hObject, eventdata, handles)
% hObject    handle to URIedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of URIedit as text
%        str2double(get(hObject,'String')) returns contents of URIedit as a double


% --- Executes during object creation, after setting all properties.
function URIedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to URIedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function LRIedit_Callback(hObject, eventdata, handles)
% hObject    handle to LRIedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LRIedit as text
%        str2double(get(hObject,'String')) returns contents of LRIedit as a double


% --- Executes during object creation, after setting all properties.
function LRIedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LRIedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function testedit_Callback(hObject, eventdata, handles)
% hObject    handle to testedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of testedit as text
%        str2double(get(hObject,'String')) returns contents of testedit as a double


% --- Executes during object creation, after setting all properties.
function testedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to testedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ip_address_Callback(hObject, eventdata, handles)
% hObject    handle to ip_address (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ip_address as text
%        str2double(get(hObject,'String')) returns contents of ip_address as a double


% --- Executes during object creation, after setting all properties.
function ip_address_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ip_address (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in tester_choice.
function tester_choice_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in tester_choice 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
    
    
    

% --- Executes during object creation, after setting all properties.
function tester_choice_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tester_choice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
