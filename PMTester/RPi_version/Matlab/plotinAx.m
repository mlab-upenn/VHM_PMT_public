function [ ] = plotinAx(hObject,eventdata,handles)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
    TITLE_NAME = 'Pacemaker Operation';
    TITLE_FONT = 'AvantGarde';
    TITLE_FONT_SIZE = 20;
    TITLE_FONT_WEIGHT = 'Bold';
    %Signal plot font properties
    SIGNAL_NAME = 'Pacemaker Signals';
    SIGNAL_FONT = 'AvantGarde';
    SIGNAL_FONT_SIZE = 10;
    SIGNAL_FONT_WEIGHT = 'Bold';
    
    INPUT_FONT = 'Arial';
    INPUT_FONT_SIZE = 14;
    INPUT_FONT_WEIGHT = 'Bold';
    
    XAXIS_NAME = 'time (milliseconds)';
    XAXIS_FONT_WEIGHT = 'Bold';
    XAXIS_FONT_SIZE = 10;
   
    TEXT_FONT = 'Arial';
    TEXT_FONT_SIZE = 16;
    TEXT_FONT_WEIGHT = 'Bold';
%{
 x = 1:100;
 y = sin(0.5*x);
 plot(handles.signal_Plot,y);
%}
 title(TITLE_NAME,'FontName',TITLE_FONT,'FontWeight',TITLE_FONT_WEIGHT, 'FontSize', TITLE_FONT_SIZE,'Interpreter','None');
 set(gca,'YtickLabel',[]);
 ylabel(SIGNAL_NAME,'FontName',SIGNAL_FONT,'FontWeight',SIGNAL_FONT_WEIGHT,'FontSize', SIGNAL_FONT_SIZE);
 xlabel(XAXIS_NAME,'FontWeight',XAXIS_FONT_WEIGHT,'FontSize', XAXIS_FONT_SIZE);
end

