function printResults_GUI(hObject, eventdata, handles,dat,sample_File,ifOffset,filename)
    global ATRIAL_INPUT;
    global VENTRICAL_INPUT;
    global ATRIAL_OUTPUT;
    global VENTRICAL_OUTPUT;
    global atrial_tolerance;
    global ventrical_tolerance;
    
    ATRIAL_INPUT = 1;
    VENTRICAL_INPUT = 2;
    ATRIAL_OUTPUT = 3;
    VENTRICAL_OUTPUT = 4;
    
    
    SENT_A_SIG = 'sent atrial signal at t=';
    % DETECT_A_SIG = 'pacemaker detected atrial signal at t=';
    % NDETECT_A_SIG = 'WARNING: pacemaker did not detect atrial signal at t=';
    
    SENT_V_SIG = 'sent ventrical signal at t=';
    % DETECT_V_SIG = 'pacemaker detected ventrical signal at t=';
    % NDETECT_V_SIG = 'WARNING: pacemaker did not detect ventrical signal at t=';
    
    A_EARLY = 'ERROR: Pacemaker paced atrium early at t=';
    A_ON = 'Pacemaker paced atrium on time at t=';
    A_LATE = 'ERROR: Pacemaker paced atrium late at t=';
    A_WRONG = 'ERROR: Pacemaker incorrectly paced atrium. at t=';
    
    V_EARLY = 'ERROR: Pacemaker paced ventricle early at t=';
    V_ON = 'Pacemaker paced ventricle on time at t=';
    V_LATE = 'ERROR: Pacemaker paced ventricle late at t=';
    V_WRONG = 'ERROR: Pacemaker incorrectly paced ventricle at t=';
        
        
    
    A_BOUND_COLOR = 'g';
    A_OFFSET_COLOR = [0 204/255 102/255];
    V_BOUND_COLOR = [153/255 204/255 1];
    V_OFFSET_COLOR = 'c';
    ALPHA_FACE_VALUE = 0.2;
    ALPHA_EDGE_VALUE = 0.5;
    
%% Plot data
    %arrow properties
    roLength = 10;
    roTipAngle = 12;
    PACE_MAGNITUDE = 3;
    %SENSE_MAGNITUDE = 2;
    %REF_MAGNITUDE = 2;
    SIGN_MAGNITUDE = 0.3;
    %Title font properties
    TITLE_NAME = ['Pacemaker Operation ',filename];
    TITLE_FONT = 'AvantGarde';
    TITLE_FONT_SIZE = 20;
    TITLE_FONT_WEIGHT = 'Bold';
        %Signal plot font properties
    SIGNAL_NAME = 'Pacemaker Signals';
    SIGNAL_FONT = 'AvantGarde';
    SIGNAL_FONT_SIZE = 16;
    SIGNAL_FONT_WEIGHT = 'Bold';
    
    INPUT_FONT = 'Arial';
    INPUT_FONT_SIZE = 14;
    INPUT_FONT_WEIGHT = 'Bold';
    
    %{
        A_BOUND_COLOR = 'g';
        A_OFFSET_COLOR = [0 204/255 102/255];
        V_BOUND_COLOR = [153/255 204/255 1];
        V_OFFSET_COLOR = 'c';
        ALPHA_FACE_VALUE = 0.2;
        ALPHA_EDGE_VALUE = 0.5;
   %}
        
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
  
    %figure;
    handles.signal_Plot;
    cla;
    hold;
    %Signal Plot
    total_time = 3000;
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
    
    result_offset = 0;
    for p = 1:size(sample_File,1)
        resultTime = dat(p,1);
        resultEvent = dat(p,2);
        resultPass = dat(p,3);
            
        expected_Time = sample_File(p,1);
        expected_Event = sample_File(p,2);
            
     %   if plotSignals
        if expected_Event == ATRIAL_OUTPUT
            atr = str2double(atrial_tolerance);
            if ~ifOffset
                a_lowBound = expected_Time-atr;
                a_highBound = expected_Time+atr;
                patch([a_lowBound,a_highBound,a_highBound,a_lowBound],[0 0 4 4],A_BOUND_COLOR,'EdgeColor', A_BOUND_COLOR,'EdgeAlpha',ALPHA_EDGE_VALUE,'FaceAlpha',ALPHA_FACE_VALUE);
            else
                a_lowBound = (expected_Time+result_offset)-atr;
                a_highBound = (expected_Time+result_offset)+atr;
                patch([a_lowBound,a_highBound,a_highBound,a_lowBound],[0 0 4 4],A_OFFSET_COLOR,'EdgeColor', A_OFFSET_COLOR,'EdgeAlpha',ALPHA_EDGE_VALUE,'FaceAlpha',ALPHA_FACE_VALUE);
            end
        elseif expected_Event == VENTRICAL_OUTPUT
            ven = str2double(ventrical_tolerance);
            if ~ifOffset
                v_lowBound = expected_Time-ven;
                v_highBound = expected_Time+ven;
                patch([v_lowBound,v_highBound,v_highBound,v_lowBound],[-4 -4 0 0],V_BOUND_COLOR,'EdgeColor', V_BOUND_COLOR,'EdgeAlpha',ALPHA_EDGE_VALUE,'FaceAlpha',ALPHA_FACE_VALUE);
            else
                v_lowBound = (expected_Time+result_offset)-ven;
                v_highBound = (expected_Time+result_offset)+ven;
                patch([v_lowBound,v_highBound,v_highBound,v_lowBound],[-4 -4 0 0],V_OFFSET_COLOR,'EdgeColor', V_OFFSET_COLOR,'EdgeAlpha',ALPHA_EDGE_VALUE,'FaceAlpha',ALPHA_FACE_VALUE);    
            end

        end
     %   end
            
        if resultPass
            [sentence flag] = getSentence(expected_Event);
            correctTime = getCorrectTime(ifOffset,result_offset,expected_Time);
            writeReport(sentence,correctTime,resultTime,flag);
            
            if ~isa(resultTime,'double')
                resultTime = cast(resultTime,'double');
            end
            
            drawSignal(expected_Event,resultTime,resultPass)
        
            result_offset = result_offset +(resultTime - expected_Time);
        else
            failedTime = resultTime;
            if ~isa(failedTime,'double')
                failedTime = cast(failedTime,'double');
            end
            %report what event happened
            [sentence, flag, reportTime] = determineError(expected_Time,failedTime,p,expected_Event,resultEvent);
            correctTime = getCorrectTime(ifOffset,result_offset,reportTime);
            writeReport(sentence,correctTime,failedTime,flag);
   
            drawSignal(expected_Event,failedTime,resultPass)
   
            break;
        end
    end
    %% other functions
    function [sentence,flag] = getSentence(event)
        if event == ATRIAL_INPUT
            sentence = SENT_A_SIG;
            flag = 2;
        elseif event == VENTRICAL_INPUT
            sentence = SENT_V_SIG;
            flag = 2;
        elseif event == ATRIAL_OUTPUT
            sentence = A_ON;
            flag = 1;
        elseif event == VENTRICAL_OUTPUT
            sentence = V_ON;
            flag = 1;
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

    function drawSignal(name,t,pass)
        textHeight = 3;
        faceColor = 'k';
        if strcmp(name,'AP') || name == ATRIAL_OUTPUT
            arrowHeight = PACE_MAGNITUDE;
            textHeight = arrowHeight + 0.3;
            faceColor = 'r';
            name = 'AP';
        elseif strcmp(name,'VP') || name == VENTRICAL_OUTPUT 
            arrowHeight = -PACE_MAGNITUDE;
            textHeight = arrowHeight - 0.3;
            faceColor = 'm';
            name = 'VP';
        elseif strcmp(name,'A_{Signal}') || name == ATRIAL_INPUT
            arrowHeight = SIGN_MAGNITUDE;
            textHeight = arrowHeight + 0.3;
            faceColor = 'y';
            name = 'A_{Signal}';
        elseif strcmp(name,'V_{Signal}') || name == VENTRICAL_INPUT
            arrowHeight = -SIGN_MAGNITUDE;
            textHeight = arrowHeight - 0.3;
            faceColor = 'w';
            name = 'V_{Signal}';
        end
        c = class(t)
        c2= class(arrowHeight)
        name
        arrow([t,0],[t,arrowHeight],'Length', roLength, 'TipAngle',roTipAngle,'EdgeColor','k','FaceColor',faceColor);
        text(t,textHeight,name,'FontName', TEXT_FONT,'FontWeight',TEXT_FONT_WEIGHT,'Fontsize', TEXT_FONT_SIZE);
            
        if ~pass
            if strcmp(name,'AP')
                makeErrorBlock('a',t);
            else
                makeErrorBlock('v',t);
            end
        end
    end

    function makeErrorBlock(type,t)
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

    function [sentence, flag, correctTime] = determineError(time,curTime,fileLine,expected_event,result_event)% (expected_Time,failedTime,p,expected_Event,resultEvent);
        correctTime = time;
        flag = 0;
        sentence = 'An incorrect event happened';
       %the below two lines cause error if fileLine is the last line in
       %the file
        if(fileLine~=size(sample_File,1))
            nextEvent = sample_File(fileLine+1,2);
            nextTime = sample_File(fileLine+1,1);
        else
            return;
        end
        if expected_event == ATRIAL_INPUT
            if result_event == ATRIAL_OUTPUT
                if nextEvent == ATRIAL_OUTPUT
                    sentence = A_EARLY;
                    correctTime = nextTime;
                else
                    sentence = A_WRONG;
                    correctTime = NaN;
                end    
            elseif result_event == VENTRICAL_OUTPUT
                if nextEvent == VENTRICAL_OUTPUT
                    sentence = V_EARLY;
                    correctTime = nextTime;
                else
                    sentence = V_WRONG;
                    correctTime = NaN;
                end
            end 
        elseif expected_event == VENTRICAL_INPUT
            if result_event == ATRIAL_OUTPUT
                if nextEvent == ATRIAL_OUTPUT
                    sentence = A_EARLY;
                    correctTime = nextTime;
                else
                    sentence = A_WRONG;
                    correctTime = NaN;
                end    
            elseif result_event == VENTRICAL_OUTPUT
                if nextEvent == VENTRICAL_OUTPUT
                    sentence = V_EARLY;
                    correctTime = nextTime;
                else
                    sentence = V_WRONG;
                    correctTime = NaN;
                end
            end 
        elseif expected_event == ATRIAL_OUTPUT
            if result_event == ATRIAL_OUTPUT
                if curTime < time
                    sentence = A_EARLY;
                elseif curTime > time
                    sentence = A_LATE;
                end
            elseif result_event == VENTRICAL_OUTPUT
                if nextEvent == VENTRICAL_OUTPUT
                    sentence = V_EARLY;
                    correctTime = time;
                else
                    sentence = V_WRONG;
                    correctTime = NaN;
                end
                    
            end
        elseif expected_event == VENTRICAL_OUTPUT
            if result_event == ATRIAL_OUTPUT
                if nextEvent == ATRIAL_OUTPUT
                    sentence = A_EARLY;
                    correctTime = nextTime;
                else
                    sentence = A_WRONG;
                    correctTime = NaN;
                end
            elseif result_event == VENTRICAL_OUTPUT
                if curTime < time
                    sentence = V_EARLY;
                elseif curTime > time
                    sentence = V_LATE;
                end       
            end               
        end
    end

    function writeReport(sentence,correctTime,t,good)
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
end
