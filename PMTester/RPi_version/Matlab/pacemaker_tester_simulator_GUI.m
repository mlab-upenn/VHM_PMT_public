function [] = pacemaker_tester_simulator_GUI(hObject,eventdata,handles,filename,initializer,pacemaker_param,varargin)
%pacemaker_tester takes in:
%   filename, a char array of the name of a file that contains the test 
%       data.
%   initializer, a char arry (or matrix) of the name of a file that contains the
%               initializer data
%   pacemaker_param, a structure defining pacemaker parameters.
%   and additional arguments.
%
%
%varagin
%   'plotTitle sets the title of the plot. Parameter is a char array of the
%       name. Default is 'Pacemaker Operation " followed by filename.
%   'tolerances' defines the allowable error in ms to be considered on time
%       parameter is a matrix or cell array defining the accepted tolerance 
%       for atrial timing and ventrial timing.
%       i.e. [10,8] or {10,8} allows for 10 ms for atrial tolerance and 8 ms for
%       ventricular tolerance. Default is no tolerances ([0,0]).
%   'allowOffset' defines if an offset will be applied if a signal is not
%       on time
%       parameter is either 'yes' or 1 to enable. Default is off.
%   'displayInitializer' allows the reporting of the pacemaker operation
%       when it's being initialized. use 1 to allow and 0 to disallow. Default
%       is 0.
%
%{
close all;
clear;
clc;
%}
%% Decide what to plot
plotSignals = 1;
breakEarly = 1;
plotTitle = 0;
exportPlot = 0;
pace_inter=1; %default stepsize
total_time = 3000;%ms %define how long you want to run the test.
tolerance_atrial = 0; %Acceptable tolerance (in ms) for detecting atrial output signals
tolerance_ventrical = 0; %Acceptable tolerance for detecting ventricular output signals.
greatestTolerance = max([tolerance_atrial, tolerance_ventrical]);
output = 0; %0 if output to display, 1 if printing to file.
seePaceSense = 0;
displayInitializer = 0;
totalFiles = 1;

%%TODO: Figure out which parameters to record in the error report.
%stats
%Global stats
testError = 0;
testsInError = '';
total_V_late_errors = 0;
total_V_early_errors = 0;
total_V_wrong_errors = 0;

total_A_late_errors = 0;
total_A_early_errors = 0;
total_A_wrong_errors = 0;

avgMarginError = 0;
greatestMarginError = 0;


%file Stats
marginError = 0;
V_late_error = 0;
V_early_error = 0;
V_wrong_error = 0;

A_late_error = 0;
A_early_error = 0;
A_wrong_error = 0;
fileError = 0;

%% Decide what to test
allowOffsets = 0;
%% Varagins
%take into account multiple arguments, and adjust the test accordingly
    if ~isempty(varargin)
        for i = 1:2:length(varargin)
            argument = varargin{i};
            if strcmpi(argument,'plotTitle')
                titleName = varargin{i+1};
                plotTitle = 1;
            elseif strcmpi(argument,'tolerances')
                parameter = varargin{i+1};
                if iscell(parameter)
                    tolerance_atrial = parameter{1};
                    tolerance_ventrical = parameter{2};
                    greatestTolerance = max([tolerance_atrial, tolerance_ventrical]);
                else
                    tolerance_atrial = parameter(1);
                    tolerance_ventrical = parameter(2);
                    greatestTolerance = max([tolerance_atrial, tolerance_ventrical]);
                end
            elseif strcmpi(argument,'allowOffset')
                parameter = varargin{i+1};
                if isa(parameter,'char')
                    if strcmpi(parameter,'yes')
                        allowOffsets = 1;
                    end
                elseif isa(parameter,'double')
                    if parameter == 1
                        allowOffsets = 1;
                    end
                end
            else
                error(['Unknown argument ''',varargin{i},'''']);
            end
        end
    end

    
%% Preallocation of test file
pace_param = pacemaker_param;
sample_File = filename;
%% Script Variables
% Plot Variables
if plotSignals
    %arrow properties
    roLength = 10;
    roTipAngle = 12;
    PACE_MAGNITUDE = 3;
    SENSE_MAGNITUDE = 2;
    REF_MAGNITUDE = 2;
    SIGN_MAGNITUDE = 0.3;
    %Title font properties
    if plotTitle
        TITLE_NAME = ['Pacemaker Operation ',titleName];
    else
        TITLE_NAME = ['Pacemaker Operation ',inputname(4)];
    end

    TITLE_FONT = 'AvantGarde';
    TITLE_FONT_SIZE = 15;
    TITLE_FONT_WEIGHT = 'Bold';
    %Signal plot font properties
    SIGNAL_NAME = 'Pacemaker Signals';
    SIGNAL_FONT = 'AvantGarde';
    SIGNAL_FONT_SIZE = 16;
    SIGNAL_FONT_WEIGHT = 'Bold';
    
    INPUT_FONT = 'Arial';
    INPUT_FONT_SIZE = 14;
    INPUT_FONT_WEIGHT = 'Bold';
end

    A_BOUND_COLOR = 'g';
    A_OFFSET_COLOR = [0 204/255 102/255];
    V_BOUND_COLOR = [153/255 204/255 1];
    V_OFFSET_COLOR = 'c';
    ALPHA_FACE_VALUE = 0.2;
    ALPHA_EDGE_VALUE = 0.5;
   
    ERROR_COLOR = 'r';
    ERROR_ALPHA_FACE_VALUE = 0.5;
    ERROR_ALPHA_EDGE_VALUE = 0.7;
    ifBoundsPrinted = 0;
    ifAOutput = 0;
    ifVOutput = 0;
    input_done = 0;
    output_done = 0;

    XAXIS_NAME = 'time (milliseconds)';
    XAXIS_FONT_WEIGHT = 'Normal';
    XAXIS_FONT_SIZE = 10;
   
    TEXT_FONT = 'Arial';
    TEXT_FONT_SIZE = 16;
    TEXT_FONT_WEIGHT = 'Bold';
    
%% Test Variables
%Message Constants
    SENT_A_SIG = 'sent atrial signal at t=';
    DETECT_A_SIG = 'pacemaker detected atrial signal at t=';
    NDETECT_A_SIG = 'WARNING: pacemaker did not detect atrial signal at t=';
    
    SENT_V_SIG = 'sent ventrical signal at t=';
    DETECT_V_SIG = 'pacemaker detected ventrical signal at t=';
    NDETECT_V_SIG = 'WARNING: pacemaker did not detect ventrical signal at t=';
    
    A_EARLY = 'ERROR: Pacemaker paced atrium early at t=';
    A_ON = 'Pacemaker paced atrium on time at t=';
    A_LATE = 'ERROR: Pacemaker paced atrium late at t=';
    A_WRONG = 'ERROR: Pacemaker incorrectly paced atrium. at t=';
    
    V_EARLY = 'ERROR: Pacemaker paced ventricle early at t=';
    V_ON = 'Pacemaker paced ventricle on time at t=';
    V_LATE = 'ERROR: Pacemaker paced ventricle late at t=';
    V_WRONG = 'ERROR: Pacemaker incorrectly paced ventricle at t=';
    
    WARNING_COLOR = [229/255 222/255 22/255];
    GOOD_COLOR = 'Comments';
    NOTE_COLOR = [0 0 1];
%Global Variables
    nextLine = 0; %variable to determine which line in the file is being processed
    offset = 0; %variable to store any necessary offsets
    a_ifPaced = 0; %boolean to determine if pacemaker paced atrium
    v_ifPaced = 0; %boolean to determine if pacemaker paced ventricle
    a_ifSensed = 0; %boolean to determine if pacemaker sensed atrium signal
    v_ifSensed = 0; %boolean to determine if pacemaker sensed ventricle signal
%% Input File Variables
    %Constants
    ATRIAL_INPUT = 1;
    VENTRICAL_INPUT = 2;
    ATRIAL_OUTPUT = 3;
    VENTRICAL_OUTPUT = 4;
    A_OUTPUT_V_INPUT = 5; %If pacemaker outputs signal to atrium and detects a ventricular signal at the same time.
    V_OUTPUT_A_INPUT = 6; %If pacemaker outputs signal to ventricule and detects an atrial signal at the same time.
    %Global Variables
    nextTime = 0; %the next time an event occurs.
    nextNextTime = 0; % the next time for the event after the expected event
    nextEvent = 0; %The next type of event, from 1-4
    nextNextEvent = 0; %The next next type of event, from 1-4  

%% PreDraw Graphs
if plotSignals
    handles.signal_Plot;
    cla;
    hold;
    if plotSignals
        %Signal Plot
        title(TITLE_NAME,'FontName',TITLE_FONT,'FontWeight',TITLE_FONT_WEIGHT, 'FontSize', TITLE_FONT_SIZE,'Interpreter','None');
        ylabel(SIGNAL_NAME,'FontName',SIGNAL_FONT,'FontWeight',SIGNAL_FONT_WEIGHT,'FontSize', SIGNAL_FONT_SIZE);
        xlabel(XAXIS_NAME,'FontWeight',XAXIS_FONT_WEIGHT,'FontSize', XAXIS_FONT_SIZE);
        set(gca,'Ylim',[-4,4],'Xlim',[0,total_time],'FontWeight','Normal','FontSize', 11);
        set(gca,'YtickLabel',[]);
        xVal = [0,total_time]; 
        yVal = [0,0];
        line(xVal, yVal, 'Color', 'k');
        set(gca,'XGrid','on');
        %set(gca,'GridLineStyle', '.');
    end
end
%% initialize the pacemaker to known state
if isa(initializer, 'double')
    initializer_File = initializer;
elseif isa(initializer,'char')
    [pa fi extension] = fileparts(initializer);
    if strcmp(extension,'.txt')
        fid = fopen(initializer);
        initializer_File = fscanf(fid,'%d %d',[2,inf])';
    else
        error(['Unsupported initializer file format ''',ext,'''']);
    end
else
    error(['Unsupported initializer file format ''',inputname(1),'''']);
end
t = 0;
lin = 0;
event = 0;
time = 0;
nxtTime = 0;
nxtEvent = 0;
initializer_next();

currReport= get(handles.reportLog,'String');
currReport{end+1}='initializing...';
%currReport{end+2}='';
set(handles.reportLog,'String',currReport);

while t < initializer_File(end,1)
    sendASignal = 0;
    sendVSignal = 0;
    switch event
        case ATRIAL_INPUT
            %check instances where there is incorrect pacing
            if pace_param.v_pace == 1
                correctTime = NaN;
                if displayInitializer
                    writeReport(V_WRONG,correctTime,0)
                end
            end
            if pace_param.a_pace == 1
                correctTime = NaN;
                if displayInitializer
                    writeReport(A_WRONG,correctTime,0)
                end
            end
            %deliver the sense when the time is right
            if t == (time + offset)
                sendASignal = 1;
            end
            if sendASignal == 1
                initializer_next();
            end
        case VENTRICAL_INPUT
            %check instances where there is incorrect pacing
            if pace_param.v_pace == 1
                correctTime = NaN;
                if displayInitializer
                    writeReport(V_WRONG,correctTime,0)
                end
            end
            if pace_param.a_pace == 1
                correctTime = NaN;
                if displayInitializer
                    writeReport(A_WRONG,correctTime,0)
                end
            end
            %deliver the sense when the time is right
            if t == (time + offset)
                sendVSignal = 1;
            end
            if sendVSignal == 1
                initializer_next();
            end
    end
        if sendASignal == 1
            pace_param = pacemaker_new(pace_param,1,0, pace_inter);
            if displayInitializer
                writeReport(SENT_A_SIG,NaN,2)
            end
            if pace_param.a_sense
                if seePaceSense
                    if displayInitializer
                        writeReport(DETECT_A_SIG,NaN,2)
                    end
                    
                end
            else
                if seePaceSense
                    if displayInitializer
                        writeReport(NDETECT_A_SIG,NaN,2)
                    end
                end
            end
        elseif sendVSignal == 1
            pace_param = pacemaker_new(pace_param,0,1, pace_inter);
            if displayInitializer
                writeReport(SENT_V_SIG,NaN,2)
            end
            if pace_param.v_sense
                if seePaceSense
                    if displayInitializer
                        writeReport(DETECT_V_SIG,NaN,2)
                    end
                end
            else
                if seePaceSense
                    if displayInitializer
                        writeReport(NDETECT_V_SIG,NaN,2)
                    end
                end
            end
        else
            pace_param = pacemaker_new(pace_param,0,0, pace_inter);
        end
    pace_param;
    t= t+1;
end
read_next(); %read the first line in the file
%wait until there is appropriate pacing
aPaced = 0;
vPaced = 0;
%see if the test starts at an Atrial pace, Ventricle pace, or neither AND
%happens at t=0.
if nextTime == 0
    switch nextEvent
        case ATRIAL_OUTPUT
            while 1
                if pace_param.v_pace
                    vPaced = 1;
                end
                if vPaced && pace_param.a_pace
                    aPaced = 1;
                end
                if aPaced && vPaced
                    break;
                end
                pace_param = pacemaker_new(pace_param,0,0, pace_inter);
            end
        case VENTRICAL_OUTPUT
            while 1
                if pace_param.a_pace
                    aPaced = 1;
                end
                if aPaced && pace_param.v_pace
                    vPaced = 1;
                end
                if aPaced && vPaced
                    break;
                end
                pace_param = pacemaker_new(pace_param,0,0, pace_inter);
            end
        otherwise
        %TODO:deal with cases when the test is not initiated by pacing
        %(i.e. should there be delay before the test, or immediately begin
        %after initialization?
    end
end

%% Loop

currReport= get(handles.reportLog,'String');
currReport{end+1}='starting test...';
set(handles.reportLog,'String',currReport);

t=-1;

while t< total_time
    
    t=t+1;
    sendASignal = 0;
    sendVSignal = 0;
    %% Do Test
        switch nextEvent
% Atrial Input        
        case ATRIAL_INPUT
            redFlag = atrialInput(); %see script
            if redFlag
                fileError = 1;
            end
            if sendASignal == 1;
                if plotSignals
                    arrow([t,0],[t,SIGN_MAGNITUDE],'Length', roLength, 'TipAngle',roTipAngle,'EdgeColor','k','FaceColor','y');
                    text(t+10,SIGN_MAGNITUDE+0.4,'A_{Signal}','FontName', INPUT_FONT,'FontWeight',INPUT_FONT_WEIGHT,'Fontsize', INPUT_FONT_SIZE); 
                end
                read_next(); %see script/ or see function increment
                ifBoundsPrinted = 0;
            end
% Ventrical Input            
        case VENTRICAL_INPUT
            redFlag = ventricularInput(); %see script
            if redFlag
                fileError = 1;
            end
            if sendVSignal == 1;
                if plotSignals
                    arrow([t,0],[t,-SIGN_MAGNITUDE],'Length', roLength, 'TipAngle',roTipAngle,'EdgeColor','k','FaceColor','w');
                    text(t+10,-SIGN_MAGNITUDE-0.4,'V_{Signal}','FontName', INPUT_FONT,'FontWeight',INPUT_FONT_WEIGHT,'Fontsize', INPUT_FONT_SIZE); 
                end
                read_next(); %see script/ or see function increment
                ifBoundsPrinted = 0;
            end
% Atrial Output           
        case ATRIAL_OUTPUT
            redFlag = atrialOutput(); %see script
            if redFlag
                fileError = 1;
            end
            if ifAOutput == 1 
                read_next(); %see script/ or see function increment
                ifBoundsPrinted = 0;
            end
% VENTRICAL Output
        case VENTRICAL_OUTPUT
            redFlag = ventricularOutput(); %see script
            if redFlag
                fileError = 1;
            end
            if ifVOutput == 1
                read_next(); %see script/ or see function increment
                ifBoundsPrinted = 0;
            end
% TODO: Deal with these cases          
        case A_OUTPUT_V_INPUT
            redFlag = atrialOutput();
            if redFlag
                fileError = 1;
            end
            redFlag = ventricularInput();
            if redFlag
                fileError = 1;
            end
    %        if pace_param.a_pace ==1
    %        end      
            if ifAOutput == 1
                output_done = 1;
            end
            if sendVSignal == 1
                input_done = 1;
            end
            if input_done && output_done
                read_next
                ifBoundsPrinted = 0;
                input_done = 0;
                output_done = 0;
            end
        case V_OUTPUT_A_INPUT
            ventricularOutput()
            atrialInput()
            if ifVOutput == 1
                output_done = 1;
            end
            if sendASignal == 1
                input_done = 1;
            end
            if input_done && output_done
                read_next;
                ifBoundsPrinted = 0;
                output_done = 0;
                input_done = 0;
            end
        end

      
    
    %% Plot Pacemaker Sensing/Pacing
    if plotSignals
        %% plot bound lines
            switch nextEvent
                case {ATRIAL_OUTPUT ,A_OUTPUT_V_INPUT}   
                    if ifBoundsPrinted == 0
                        if ~allowOffsets
                            a_lowBound = nextTime-tolerance_atrial;
                            a_highBound = nextTime+tolerance_atrial;
                            patch([a_lowBound,a_highBound,a_highBound,a_lowBound],[0 0 4 4],A_BOUND_COLOR,'EdgeColor', A_BOUND_COLOR,'EdgeAlpha',ALPHA_EDGE_VALUE,'FaceAlpha',ALPHA_FACE_VALUE);
                        else
                            a_lowBound = (nextTime+offset)-tolerance_atrial;
                            a_highBound = (nextTime+offset)+tolerance_atrial;
                            patch([a_lowBound,a_highBound,a_highBound,a_lowBound],[0 0 4 4],A_OFFSET_COLOR,'EdgeColor', A_OFFSET_COLOR,'EdgeAlpha',ALPHA_EDGE_VALUE,'FaceAlpha',ALPHA_FACE_VALUE);
                        end
                        ifBoundsPrinted = 1;
                    end
                case {VENTRICAL_OUTPUT, V_OUTPUT_A_INPUT}
                    if ifBoundsPrinted == 0;
                        if ~allowOffsets
                            v_lowBound = nextTime-tolerance_ventrical;
                            v_highBound = nextTime+tolerance_ventrical;
                            patch([v_lowBound,v_highBound,v_highBound,v_lowBound],[-4 -4 0 0],V_BOUND_COLOR,'EdgeColor', V_BOUND_COLOR,'EdgeAlpha',ALPHA_EDGE_VALUE,'FaceAlpha',ALPHA_FACE_VALUE);
                        else
                            v_lowBound = (nextTime+offset)-tolerance_ventrical;
                            v_highBound = (nextTime+offset)+tolerance_ventrical;
                            patch([v_lowBound,v_highBound,v_highBound,v_lowBound],[-4 -4 0 0],V_OFFSET_COLOR,'EdgeColor', V_OFFSET_COLOR,'EdgeAlpha',ALPHA_EDGE_VALUE,'FaceAlpha',ALPHA_FACE_VALUE);
                        end
                        ifBoundsPrinted = 1;
                    end
            end
    %% plot signals
    data=0;
        % a_pace
        if pace_param.a_pace
            data=PACE_MAGNITUDE;
            name = 'AP';
            faceColor = 'r';
            height = data + 0.3;
            arrow([t,0],[t,data],'Length', roLength, 'TipAngle',roTipAngle,'EdgeColor','k','FaceColor',faceColor);
            text(t,height,name,'FontName', TEXT_FONT,'FontWeight',TEXT_FONT_WEIGHT,'Fontsize', TEXT_FONT_SIZE);
            
            if redFlag
                makeErrorBlock('a');
            end
        end
        % v_pace
        if pace_param.v_pace               
            data=-PACE_MAGNITUDE;
            name = 'VP';
            faceColor = 'm';
            height = data - 0.3;
            arrow([t,0],[t,data],'Length', roLength, 'TipAngle',roTipAngle,'EdgeColor','k','FaceColor',faceColor);
            text(t,height,name,'FontName', TEXT_FONT,'FontWeight',TEXT_FONT_WEIGHT,'Fontsize', TEXT_FONT_SIZE); 
            
            if redFlag
                makeErrorBlock('v');
            end
        end
        % a_sense
       
        % v_sense
        
        %a_ref
        
        % v_ref
        
   end
   
    %% Send signals/next Time Step
        if sendASignal == 1 %if an atrial sense needs to be sent
            pace_param = pacemaker_new(pace_param,1,0, pace_inter);
            writeReport(SENT_A_SIG,NaN,2)
            if pace_param.a_sense
                if seePaceSense
                    writeReport(DETECT_A_SIG,NaN,2)
                end
            else
                if seePaceSense
                    writeReport(NDETECT_A_SIG,NaN,2)
                end
            end
            sendASignal = 0;
        elseif sendVSignal == 1 %if a ventricular sense needs to be sent
            pace_param = pacemaker_new(pace_param,0,1, pace_inter);
            writeReport(SENT_V_SIG,NaN,2)
            if pace_param.v_sense
                if seePaceSense
                    writeReport(DETECT_V_SIG,NaN,2)
                end
            else
                if seePaceSense
                    writeReport(NDETECT_V_SIG,NaN,2)
                end
            end
            sendVSignal = 0;
        else %otherwise, go to next time step.
            pace_param = pacemaker_new(pace_param,0,0, pace_inter);
        end
        %make it pause per time step to make it seem more realistic
        %tic
        %pause(0.0008)
        %toc

%% Break/Escape test conditions        
        %break out of while loop once finished testing  
    if breakEarly        
        if t > (nextTime + offset)+ greatestTolerance + 300 && nextLine > length(sample_File)
            set(gca,'Ylim',[-4,4],'Xlim',[0,t]);
            break;
 
        end   
    end        
%if error was found, exit the test
    if fileError
        theEnd = max(nextTime +offset + greatestTolerance + 300,t +offset + greatestTolerance + 300);
            set(gca,'Ylim',[-4,4],'Xlim',[0,theEnd]);

        break;
    end
        
end %end test
currReport= get(handles.reportLog,'String');
currReport{end+1}= '';
set(handles.reportLog,'String',currReport);

    testError = testError + fileError;
    if fileError
        testsInError = [testsInError,', ',name];
        fileError = 0;
    end
if output == 0
    disp(' ');
else
    fprintf(fileId,'\n');
end

%print out a summary of the tests if more than 1 test was done.
if totalFiles > 1
    if output == 0
        disp('Complete.');
        disp('Results:');
        disp(['Total tests: ', num2str(totalFiles)]);
        disp(['Total tests failed: ',num2str(testError),'   percentage: ',num2str((totalFiles-testError)/totalFiles*100),'%']);
        disp(['Tests with errors: ',num2str(testsInError)]);
        disp(['Total early ventricular pacing: ',num2str(total_V_early_errors),'   average per test: ',num2str(total_V_early_errors/totalFiles)]);
        disp(['Total early atrial pacing: ',num2str(total_A_early_errors),'   average per test: ', num2str(total_A_early_errors/totalFiles)]);
        disp(['Total late ventricular pacing: ',num2str(total_V_late_errors),'   average per test: ', num2str(total_V_late_errors/totalFiles)]);
        disp(['Total late atrial pacing: ',num2str(total_A_late_errors),'   average per test: ', num2str(total_A_late_errors/totalFiles)]);
        disp(['Total ventricular pacing in error: ',num2str(total_V_wrong_errors),'   average per test: ',num2str(total_V_wrong_errors/totalFiles)]);
        disp(['Total atrial pacing in error: ',num2str(total_A_wrong_errors),'   average per test: ',num2str(total_A_wrong_errors/totalFiles)]);
        disp(' ');
    else
        fprintf(fileId,'Results:\n');
        fprintf(fileId,'Total tests: %d\n', totalFiles);
        fprintf(fileId,'Total tests failed: %d\tpercentage: %d%%\n',testError,(totalFiles-testError)/totalFiles*100);
        fprintf(fileId,'Tests with errors: %s\n',testsInError);
        fprintf(fileId,'Total early ventricular pacing: %d \t average per test: %d\n',total_V_early_errors,total_V_early_errors/totalFiles);
        fprintf(fileId,'Total early atrial pacing: %d \t average per test: %d\n', total_A_early_errors, total_A_early_errors/totalFiles);
        fprintf(fileId,'Total late ventricular pacing: %d \t average per test: %d\n', total_V_late_errors, total_V_late_errors/totalFiles);
        fprintf(fileId,'Total late atrial pacing: %d \t average per test: %d\n', total_A_late_errors, total_A_late_errors/totalFiles);
        fprintf(fileId,'Total ventricular pacing in error: %d \t average per test: %d\n', total_V_wrong_errors, total_V_wrong_errors/totalFiles);
        fprintf(fileId,'Total atrial pacing in error: %d \t average per test: %d\n', total_A_wrong_errors, total_A_wrong_errors/totalFiles);
        fclose(fileId);
    end
end
%% functions

    function redFlag = ventricularOutput()
         ifVOutput = 0;
         redFlag = 0;
            %if nextLine == 1
            %    correctTime = nextTime;
            %    writeReport(output,V_ON,correctTime,1)
            %    pace_param.v_pace = 1;
            %    ifVOutput = 1;
            %else
                if allowOffsets
                    v_lowBound = (nextTime+offset)-tolerance_ventrical;
                    v_highBound = (nextTime+offset)+tolerance_ventrical;
                else
                    v_lowBound = (nextTime)-tolerance_ventrical;
                    v_highBound = (nextTime)+tolerance_ventrical;
                end
                if t < v_lowBound
                    if pace_param.a_pace == 1
                        correctTime = getCorrectTime(allowOffsets,offset,nextTime);
                        writeReport(A_LATE,correctTime,0)
                        
                        %errors
                        total_A_late_errors = total_A_late_errors + 1; 
                        redFlag = 1;
                    end
                    if pace_param.v_pace == 1
                        correctTime = getCorrectTime(allowOffsets,offset,nextTime);
                        writeReport(V_EARLY,correctTime,0)
                        offset = offset + (t-nextTime);
                        ifVOutput = 1;
                        
                        %errors
                        total_V_early_errors = total_V_early_errors + 1;
                        redFlag = 1;
                    end
                elseif t >= v_lowBound && t <= v_highBound
                    if pace_param.v_pace == 1
                        correctTime = getCorrectTime(allowOffsets,offset,nextTime);
                        writeReport(V_ON,correctTime,1)
                        offset = offset + (t-nextTime);
                        ifVOutput = 1;
                    end
                    if pace_param.a_pace == 1
                        if nextNextEvent == ATRIAL_OUTPUT
                            correctTime = getCorrectTime(allowOffsets,offset,nextNextTime);
                            writeReport(A_EARLY,correctTime,0)
                            %count errors
                            total_A_early_errors = total_A_early_errors + 1;
                            redFlag = 1;
                        else
                            correctTime = NaN;
                            writeReport(A_WRONG,correctTime,0)
                            %count errors
                            total_A_wrong_errors = total_A_wrong_errors + 1;
                            redFlag = 1;
                        end
                    end
                elseif t > v_highBound
                    if pace_param.v_pace == 1
                        correctTime = getCorrectTime(allowOffsets,offset,nextTime);
                        writeReport(V_LATE,correctTime,0)
                        offset = offset + (t-nextTime);
                        ifVOutput = 1;
                        %errors
                        total_V_late_errors = total_V_late_errors + 1;
                        redFlag = 1;
                    end
                    if pace_param.a_pace == 1
                        if nextNextEvent == ATRIAL_OUTPUT
                            correctTime = getCorrectTime(allowOffsets,offset,nextNextTime);
                            writeReport(A_EARLY,correctTime,0)
                            %errors
                            total_A_early_errors = total_A_early_errors +1;
                            redFlag = 1;
                        else
                            correctTime = NaN;
                            writeReport(A_WRONG,correctTime,0)
                            %errors
                            total_A_wrong_errors = total_A_wrong_errors + 1;
                            redFlag = 1;
                        end
                    end
                end
            %end
    end
    function redFlag = atrialOutput()
           ifAOutput = 0;
           redFlag = 0;
                if allowOffsets
                    a_lowBound = (nextTime+offset)-tolerance_atrial;
                    a_highBound = (nextTime+offset)+tolerance_atrial;
                else
                    a_lowBound = (nextTime)-tolerance_atrial;
                    a_highBound = (nextTime)+tolerance_atrial;
                end
                if t < a_lowBound
                    if pace_param.a_pace == 1
                        correctTime = getCorrectTime(allowOffsets,offset,nextTime);
                        writeReport(A_EARLY,correctTime,0)
                        offset = offset + (t-nextTime);
                        ifAOutput = 1;
                        %errors
                        total_A_early_errors = total_A_early_errors + 1;
                        redFlag = 1;
                    end
                    if pace_param.v_pace == 1
                        if nextNextEvent == VENTRICAL_OUTPUT
                            correctTime = getCorrectTime(allowOffsets,offset,nextTime);
                            writeReport(V_EARLY,correctTime,0)
                            %errors
                            total_V_early_errors = total_V_early_errors + 1;
                            redFlag = 1;
                        else
                            correctTime = NaN;
                            writeReport(V_WRONG,correctTime,0)
                            %errors
                            total_V_wrong_errors = total_V_wrong_errors + 1;
                            redFlag = 1;
                        end
                    end
                elseif t >= a_lowBound && t <= a_highBound
                    if pace_param.a_pace == 1
                        correctTime = getCorrectTime(allowOffsets,offset,nextTime);
                        writeReport(A_ON,correctTime,1)
                        offset = offset + (t-nextTime);
                        ifAOutput = 1;
                    end
                    if pace_param.v_pace == 1
                        if nextNextEvent == VENTRICAL_OUTPUT
                            correctTime = getCorrectTime(allowOffsets,offset,nextNextTime);
                            writeReport(V_EARLY,correctTime,0)
                            %errors
                            total_V_early_errors = total_V_early_errors + 1;
                            redFlag = 1;
                        else
                            correctTime = NaN;
                            writeReport(V_WRONG,correctTime,0)
                            %errors
                            total_V_wrong_errors = total_V_wrong_errors + 1;
                            redFlag = 1;
                        end
                    end
                elseif t > a_highBound
                    if pace_param.a_pace == 1
                        correctTime = getCorrectTime(allowOffsets,offset,nextTime);
                        writeReport(A_LATE,correctTime,0)
                        offset = offset + (t-nextTime);
                        ifAOutput = 1;
                        %errors
                        total_A_late_errors = total_A_late_errors + 1;
                        redFlag = 1;
                    end
                    if pace_param.v_pace == 1
                        if nextNextEvent == VENTRICAL_OUTPUT
                            correctTime = getCorrectTime(allowOffsets,offset,nextNextTime);
                            writeReport(V_EARLY,correctTime,0)
                            %errors
                            total_V_early_errors = total_V_early_errors + 1;
                            redFlag = 1;
                        else
                            correctTime = NaN;
                            writeReport(V_WRONG,correctTime,0)
                            %errors
                            total_V_wrong_errors = total_V_wrong_errors + 1;
                            redFlag = 1;
                        end
                    end
                end
            %end
    end
    
    function redFlag = atrialInput()
        %check instances where there is incorrect pacing
            redFlag = 0;
        if pace_param.v_pace == 1
            correctTime = NaN;
            writeReport(V_WRONG,correctTime,0)
            %errors
            total_V_wrong_errors = total_V_wrong_errors + 1;
            redFlag = 1;
        end
        if pace_param.a_pace == 1
            correctTime = NaN;
            writeReport(A_WRONG,correctTime,0)
            %errors
            total_A_wrong_errors = total_A_wrong_errors + 1;
            redFlag = 1;
        end
        %deliver the sense when the time is right
        if t == (nextTime + offset)
            sendASignal = 1;
        end
    end

    function redFlag = ventricularInput()
        %check instances where there is incorrect pacing
            redFlag = 0;
        if pace_param.v_pace == 1
            correctTime = NaN;
            writeReport(V_WRONG,correctTime,0)
            %errors
            total_V_wrong_errors = total_V_wrong_errors + 1;
            redFlag = 1;
        end
        if pace_param.a_pace == 1
            correctTime = NaN;
            writeReport(A_WRONG,correctTime,0)
            %errors
            total_A_wrong_errors = total_A_wrong_errors + 1;
            redFlag = 1;
        end
        %deliver the sense when the time is right
        if t == (nextTime + offset)
                sendVSignal = 1;
        end
    end

    function initializer_next()
        %initializer_next reads the next line in the initializer file.
    [lin, time, event,...
        nxtTime,nxtEvent, initializer_File] = increment(lin, time, event,...
        nxtTime,nxtEvent, initializer_File);
    end

    function read_next()
        %read_next reads the next line in the test file.
    [nextLine, nextTime, nextEvent,...
        nextNextTime,nextNextEvent, sample_File] = increment(nextLine, nextTime, nextEvent,...
        nextNextTime,nextNextEvent, sample_File);       
    end

    function [nxtLine, nxtTime, nxtEvent, nNTime,nNEvent, smp_File] = increment(nxtLine, nxtTime, nxtEvent, nNTime,nNEvent, smp_File)
    %increment reads the next line, and next next line of an nx2 matrix
    %   Detailed explanation goes here
        nxtLine = nxtLine + 1;
        if nxtLine <= length(smp_File)
            nxtTime = smp_File(nxtLine,1);
            nxtEvent = smp_File(nxtLine,2);
        else
            nxtEvent = 0;
        end
    
        if nxtLine < length(smp_File)
            nNTime = smp_File(nxtLine+1,1);
            nNEvent = smp_File(nxtLine+1,2);
        else
            nNTime = 0;
            nNEvent = 0;    
        end

    end
    function writeReport(sentence,correctTime,good)
        %writeReport writes a line on if the pacemaker did something in
        %error or did it correctly.
        if good == 1 %good statement
                currReport= get(handles.reportLog,'String');
                currReport{end+1}= [sentence, num2str(t), '. (Expected at t=', num2str(correctTime),'. Misalignment: ',num2str(t-correctTime),')'];
                set(handles.reportLog,'String',currReport);
        elseif good == 0 %error statement
                set(handles.reportLog,'ForegroundColor','r');
                currReport= get(handles.reportLog,'String');
                currReport{end+1}= [sentence, num2str(t),'. (Expected at t=',num2str(correctTime), '. Misalignment: ',num2str(t-correctTime),')'];
                set(handles.reportLog,'String',currReport);
        elseif good == 2 %neutral statement
                currReport= get(handles.reportLog,'String');
                currReport{end+1}= [sentence, num2str(t), '.'];
                set(handles.reportLog,'String',currReport);
        end
    end

    function correctTime = getCorrectTime(allowOffsets,offset,time)
        %correctTime gets the expected time of a pacemaker event if an
        %error occurred.
         if allowOffsets
             correctTime = time + offset;
         else
             correctTime = time;
         end
         
    end

    function makeErrorBlock(type)
        %if plotting, makeErrorBlock creates a rectangle surrounding the
        %incorrect pacemaker event.
        high = t+5;
        low  = t-5;
        if strcmp(type,'v')      
            patch([low,high,high,low],[-4 -4 0 0],ERROR_COLOR,'EdgeColor', ERROR_COLOR,'EdgeAlpha',ERROR_ALPHA_EDGE_VALUE,'FaceAlpha',ERROR_ALPHA_FACE_VALUE);
        elseif strcmp(type,'a')
            patch([low,high,high,low],[0 0 4 4],ERROR_COLOR,'EdgeColor', ERROR_COLOR,'EdgeAlpha',ERROR_ALPHA_EDGE_VALUE,'FaceAlpha',ERROR_ALPHA_FACE_VALUE);
        end
   end
end

