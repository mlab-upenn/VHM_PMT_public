%VHM_GUI()-->hardware heart model
%VHM_GUI(<mat_file_path>)-->heart model as software

function err_code=VHM_GUI(varargin)
    global GUI time_stamp
    if(nargin==2)
       update_GUI(varargin{1},varargin{2});%called when updating the GUI 
    else
        err_code=0;
        delete(instrfindall);
        delete(timerfindall);
        GUI.udp_handle=[]; 
        GUI.ok_to_display=0;
        GUI.IP={'158.130.12.42'};%sample IP address
        GUI.logging_in_progress=0;
        GUI.update_in_progress=0;
        GUI.screen_size=get(0,'ScreenSize');
        GUI.nx=0;
        GUI.ny=7;
        GUI.px=0;
        GUI.py=7;
        GUI.factor=1;
        get_model_info;
        GUI.main_gui_handle=figure('Units', 'normalized'...
            ,'Position', [0 0 1 1]...
            ,'Resize','on'...
            ,'Name','Simple Model GUI'...
            ,'NumberTitle','Off');   
        if(GUI.heart_model)
            set(GUI.main_gui_handle,'Name','Complex Model GUI');
            GUI.ny=12;
            GUI.py=8;
        end
        set(GUI.main_gui_handle,'MenuBar','none');
        set(GUI.main_gui_handle,'ToolBar','none');
        GUI.toolbar_handle=uitoolbar(GUI.main_gui_handle);
        GUI.time_display=0;
        GUI.MAX_PACES=20;
        GUI.mode=0;
        GUI.formal_mode=nargin;
        GUI.node_table=[];
        GUI.path_table=[];
        GUI.trigger_table=[];
        GUI.paths_handle=[];
        GUI.add_path_mode=0;
        GUI.heart_axes_handle=axes('Units','normalized'...
            ,'Position',[0.005,0.195,0.47,0.8]...
            ,'Xlim',[0 530]...
            ,'Ylim',[0 530]...
            ,'XTick',[]...
            ,'YTick',[]...
            ,'ZTick',[]...
            ,'NextPlot','add');    
        GUI.panel2_handle=uipanel('Parent',GUI.main_gui_handle...
            ,'Title',''...
            ,'Units','normalized'...
            ,'Position',[0.005 0.005 0.47 0.185]...
            ,'BackgroundColor',[0.7 0.9 0.8]...
            ,'BorderType','etchedout'...
            ,'BorderWidth',1,...
            'ShadowColor',[0 0 0]);
        GUI.play_or_stop_button=uicontrol('Parent',GUI.panel2_handle...
            ,'String','Play'...
            ,'Style','pushbutton'...
            ,'Units','normalized'...
            ,'Position',[0.005 0.8 0.04 0.15],...
            'Callback',@run_model);
        GUI.position_slider=uicontrol('Parent',GUI.panel2_handle,'Style','slider'...
            ,'Min',0,...
            'Max',10,...
            'Value',0,...
            'Units','normalized'...
            ,'Position',[0.05 0.8 0.705 0.15]...
            ,'SliderStep',[0.0001 0.001]);
        GUI.max_time_display=uicontrol('Parent',GUI.panel2_handle,'Style','text','FontSize',14,'String','Inf'...
            ,'Units','normalized'...
            ,'Position',[0.76 0.8 0.055 0.15]);
        GUI.speed_list=uicontrol('Parent',GUI.panel2_handle,'String',{'1x','0.5x','0.25x','0.1x'},'Style',...
            'popupmenu','Units','normalized'...
            ,'Position',[0.82 0.8 0.08 0.15]...
            ,'Callback',@change_speed);
        GUI.pace_button=uicontrol('Parent',GUI.panel2_handle...
            ,'String','Pace Now'...
            ,'Style','pushbutton'...
            ,'Units','normalized'...
            ,'Position',[0.905 0.8 0.09 0.15],...
            'Callback',@pace_nodes);
        GUI.show_signals_handle=uicontrol('Style','pushbutton'...
            ,'String','Show Signals'...
            ,'Units','normalized'...
            ,'Position',[0.5 0.97 0.07 0.025]...
            ,'BackgroundColor',[0.7 0.9 0.8]...
            ,'Callback',@display_signals_or_tables);   
        GUI.panel4_handle=uipanel('Parent',GUI.main_gui_handle...
            ,'Title',''...
            ,'Units','normalized'...
            ,'Position',[0.48 0.005 0.015 .965]...
            ,'BackgroundColor',[0.7 0.9 0.8]...
            ,'BorderType','etchedout'...
            ,'BorderWidth',1,...
            'ShadowColor',[0 0 0]); 
        GUI.panel3_handle=uipanel('Parent',GUI.main_gui_handle...
            ,'Title',''...
            ,'Units','normalized'...
            ,'Position',[0.495 0.005 0.5 .965]...
            ,'BackgroundColor',[0.7 0.9 0.8]...
            ,'BorderType','etchedout'...
            ,'BorderWidth',1,...
            'ShadowColor',[0 0 0]); 
        if(GUI.heart_model)
            node_table_column_format={'numeric','numeric','numeric','numeric','numeric','numeric','numeric','numeric','numeric','numeric','numeric','numeric'};
            node_table_column_editable_array=[true true true true true true true true true true true true];
            node_table_column_name={'Node State','TERP_current','TERP_default','TRRP_current','TRRP_default','Trest_current','Trest_default','ERP_min','ERP_max','Node activation status','Path activation status','AV Node'};
            path_table_column_format={'numeric','numeric','numeric','numeric','numeric','numeric','numeric','numeric'};
            path_table_column_editable_array=[true true true true true true true true];
            path_table_column_name={'Path State','Source Node','Destination Node','current FC','Default FC','Current BC','Default BC','Reset Values'};
        else
            node_table_column_format={'numeric','numeric','numeric','numeric','numeric','numeric','numeric'};
            node_table_column_editable_array=[true true true true true true true];
            node_table_column_name={'Node State','TERP_current','TERP_default','Trest_current','Trest_default','Node activation status','Path activation status'};
            path_table_column_format={'numeric','numeric','numeric','numeric','numeric','numeric','numeric'};
            path_table_column_editable_array=[true true true true true true true];
            path_table_column_name={'Path State','Source Node','Destination Node','current FC','Default FC','Current BC','Default BC'};
        end
        GUI.node_table_handle = uitable('Parent',GUI.panel3_handle,'Units','normalized'...
            ,'Position',[0.005 0.5025 0.4925 0.4925]...
            ,'Data',GUI.node_table...
            ,'RowName',[]...
            ,'ColumnFormat',node_table_column_format...
            ,'ColumnWidth','auto'...
            ,'ColumnEditable',node_table_column_editable_array...
            ,'ColumnName',node_table_column_name...
            ,'TooltipString','Node Table');
        GUI.path_table_handle = uitable('Parent',GUI.panel3_handle,'Units','normalized'...
            ,'Position',[0.5025 0.5025 0.4925 0.4925]...
            ,'Data',GUI.path_table...
            ,'RowName',[]...
            ,'ColumnFormat',path_table_column_format...
            ,'ColumnWidth','auto'...
            ,'ColumnEditable',path_table_column_editable_array...
            ,'ColumnName',path_table_column_name...
            ,'TooltipString','Path Table');
        GUI.trigger_table_handle = uitable('Parent',GUI.panel3_handle,'Units','normalized'...
            ,'Position',[0.005 0.005 0.99 0.4925]...
            ,'Data',GUI.trigger_table...
            ,'ColumnFormat',{'numeric'}...
            ,'ColumnWidth','auto'...
            ,'ColumnEditable',true...
            ,'ColumnName',{'Trigger Count'}...
            ,'CellEditCallback',@update_meaning...
            ,'TooltipString','Pacing setup table');
        GUI.im=imread('..\icons\EP.jpg');
        GUI.im=imagesc(GUI.im);
        GUI.nodes_position=[];
        GUI.node_pos=scatter([],[],'LineWidth',5,'Marker','o','MarkerEdgeColor','r','MarkerFaceColor','r','HitTest','off');
        if(nargin)%if any argument passed, first argument is the .mat file for the model configuration
            time_stamp=1;
            trigger_table=zeros(GUI.nx,1);
            try
                load(varargin{1});
            catch
                close all;
                disp('.mat file not present at the path specified');
                err_code=1;
                return;
            end
            GUI.node_table=node_table;
            GUI.path_table=path_table;
            try
                create_t_table_on_GUI(trigger_table,GUI.trigger_table_handle);
            catch
            end
            GUI.nx=size(GUI.node_table,1);
            GUI.ny=size(GUI.node_table,2);
            GUI.px=size(GUI.path_table,1);
            GUI.py=size(GUI.path_table,2);
            set(GUI.node_table_handle,'Data',GUI.node_table);
            set(GUI.path_table_handle,'Data',GUI.path_table);
            GUI.nodes_position=node_pos;
            set(GUI.node_pos,'XData',node_pos(:,1),'YData',node_pos(:,2));
            try
                delete(GUI.paths_handle);
            catch
            end
            GUI.paths_handle=[];
            for i=1:GUI.px
                GUI.paths_handle(end+1)=line([node_pos(path_table(i,2),1) node_pos(path_table(i,3),1)],[node_pos(path_table(i,2),2) node_pos(path_table(i,3),2)],'LineWidth',5);
            end
            GUI.model_mode_handle=uipushtool(GUI.toolbar_handle,'CData',customize_image('..\icons\software-icon.png'),'TooltipString','Software Heart Model');
        else
            GUI.new_file_handle=uipushtool(GUI.toolbar_handle,'CData',customize_image('..\icons\new.png'),'TooltipString','New Model','ClickedCallback',@new_model);
            GUI.load_file_handle=uipushtool(GUI.toolbar_handle,'CData',customize_image('..\icons\open-file.png'),'TooltipString','Load Model','ClickedCallback',@load_model_dbox);
            GUI.save_file_handle=uipushtool(GUI.toolbar_handle,'CData',customize_image('..\icons\save.png'),'TooltipString','Save Model','ClickedCallback',@save_model);
            GUI.add_path_handle=uipushtool(GUI.toolbar_handle,'CData',customize_image('..\icons\add_path.png'),'TooltipString','Add path','ClickedCallback',@add_path);
            GUI.delete_node_handle=uipushtool(GUI.toolbar_handle,'CData',customize_image('..\icons\delete_node.png'),'TooltipString','Remove Node','ClickedCallback',@remove_node);
            GUI.delete_path_handle=uipushtool(GUI.toolbar_handle,'CData',customize_image('..\icons\delete_path.png'),'TooltipString','Remove Path','ClickedCallback',@remove_path);
            GUI.model_mode_handle=uipushtool(GUI.toolbar_handle,'CData',customize_image('..\icons\heart_model.png'),'TooltipString','Hardware Heart Mode');
            GUI.load_trigger_table_handle=uipushtool(GUI.toolbar_handle,'CData',customize_image('..\icons\upload.png'),'TooltipString','Upload Trigger Table','ClickedCallback',@upload_trigger_table);
            GUI.ip_address_handle=uipushtool(GUI.toolbar_handle,'CData',customize_image('..\icons\network_ip.png'),'TooltipString','IP address','ClickedCallback',@change_ip);
        end
        GUI.play_mode_handle=uipushtool(GUI.toolbar_handle,'CData',customize_image('..\icons\clock.png'),'TooltipString','Current Mode','ClickedCallback',@switch_modes,'Tag','current');
        GUI.pacemaker_mode_handle=uipushtool(GUI.toolbar_handle,'CData',customize_image('..\icons\pacemaker.png'),'TooltipString','Pacemaker Off','ClickedCallback',@switch_modes,'Tag','poff');
        GUI.view_history_handle=uipushtool(GUI.toolbar_handle,'CData',customize_image('..\icons\log.png'),'TooltipString','View Heart Log','ClickedCallback',@display_log);
        GUI.selected_node_pos=scatter([],[],'LineWidth',5,'Marker','o','MarkerEdgeColor','g','MarkerFaceColor','g');
        GUI.activated_node_pos=scatter([],[],'LineWidth',5,'Marker','o','MarkerEdgeColor','y','MarkerFaceColor','y','HitTest','off');
        GUI.excited_node_pos=scatter([],[],'LineWidth',5,'Marker','o','MarkerEdgeColor','g','MarkerFaceColor','g','HitTest','off');
        GUI.relaxed_node_pos=scatter([],[],'LineWidth',5,'Marker','o','MarkerEdgeColor','r','MarkerFaceColor','r','HitTest','off');
        GUI.activated_nodes_position=zeros(1,2);
        GUI.excited_nodes_position=zeros(1,2);
        GUI.relaxed_nodes_position=zeros(1,2);
        set(GUI.im,'HitTest','off');
        set(GUI.heart_axes_handle,'ButtonDownFcn',@button_press);
        set(GUI.main_gui_handle,'WindowButtonMotionFcn', @hinter);
        GUI.node_hint_text_handle = text('Color', 'white', 'VerticalAlign', 'Bottom');
        GUI.path_hint_text_handle = text('Color', 'white', 'VerticalAlign', 'Bottom');
    end
end

function load_model_dbox(~,~)
global GUI
    GUI.model_selection_figure.main_handle=figure('Units', 'normalized',...
            'Position', [0.5 0.5 0.2 0.2],...
            'Resize','off',...
            'Name','Choose Heart Model',...
            'NumberTitle','Off'); 
    set(GUI.model_selection_figure.main_handle,'MenuBar','none');
    set(GUI.model_selection_figure.main_handle,'ToolBar','none');
    GUI.model_selection_figure.buttongroup_handle=uibuttongroup('visible','on','Units','normalized','Position',[0 0.2 1 0.8],'SelectionChangeFcn',@change_selection);
    GUI.model_selection_figure.shm_button=uicontrol('Parent',GUI.model_selection_figure.buttongroup_handle,'Style','radiobutton','String','Standard Heart Model','Units','normalized','Position',[0.005 0.75 0.35 0.1]);
    GUI.model_selection_figure.predefined_model_menu=uicontrol('Parent',GUI.model_selection_figure.main_handle,...
        'Style','popupmenu',...
        'String',{'Normal Sinus Rhythm(simple)','Bradycardia with Heart Block(simple)','Atrioventricular Nodal Reentry Tachycardia(simple)','Wenckebach Heart Block(complex)'},...
        'Units','normalized','Position',[0.35 0.8 0.5 0.1]);
    GUI.model_selection_figure.chm_button=uicontrol('Parent',GUI.model_selection_figure.buttongroup_handle,'Style','radiobutton','String','Custom Heart Model','Units','normalized','Position',[0.005 0.4 0.35 0.1]);
    GUI.model_selection_figure.chm_path=uicontrol('Style','edit','String',[],'Units','normalized','Position',[0.35 0.5 0.5 0.1],'BackgroundColor','w','Enable','off');
    GUI.model_selection_figure.chm_browse_button=uicontrol('Style','pushbutton','String','Browse','Units','normalized','Position',[0.85 0.5 0.145 0.1],'Callback',@load_custom_model,'Enable','off');
    GUI.model_selection_figure.ok_button=uicontrol('Style','pushbutton','String','OK','Units','normalized','Position',[0.02 0.02 0.33 0.15],'Callback',@model_ok);
    GUI.model_selection_figure.cancel_button=uicontrol('Style','pushbutton','String','Cancel','Units','normalized','Position',[0.65 0.02 0.33 0.15],'Callback',@model_not_ok);
    set(GUI.model_selection_figure.buttongroup_handle,'SelectedObject',GUI.model_selection_figure.shm_button); 
end

function change_selection(~,eventdata)
    global GUI
    if(eventdata.NewValue==GUI.model_selection_figure.shm_button)
        set(GUI.model_selection_figure.chm_path,'Enable','off');
        set(GUI.model_selection_figure.chm_browse_button,'Enable','off');
        set(GUI.model_selection_figure.predefined_model_menu,'Enable','on');
    else
        set(GUI.model_selection_figure.chm_path,'Enable','on');
        set(GUI.model_selection_figure.chm_browse_button,'Enable','on');
        set(GUI.model_selection_figure.predefined_model_menu,'Enable','off'); 
    end
        
end

function load_custom_model(~,~)
    global GUI
    [FileName,FilePath ]= uigetfile('*.mat', 'Load VHM Model');
    GUI.model_selection_figure.ExPath = fullfile(FilePath, FileName);
    set(GUI.model_selection_figure.chm_path,'String',GUI.model_selection_figure.ExPath);
end

function model_ok(hObject,~)
    global GUI
    standard_model_file_paths={'D:\VHM\HOC_freedom\HOC_freedom\new_codes\case_sp_NSR.mat','D:\VHM\HOC_freedom\HOC_freedom\new_codes\case_sp_BRwHB.mat','D:\VHM\HOC_freedom\HOC_freedom\new_codes\AVNRT.mat','D:\VHM\HOC_freedom\HOC_freedom\new_codes_ver2\matlab\case_cp_WB.mat'};
    if(get(GUI.model_selection_figure.buttongroup_handle,'SelectedObject')==GUI.model_selection_figure.shm_button)
      load_model(standard_model_file_paths{get(GUI.model_selection_figure.predefined_model_menu,'Value')}); 
    else
        load_model(GUI.model_selection_figure.ExPath);
    end
    close(get(hObject,'Parent'));
end

function model_not_ok(hObject,~)
    close(get(hObject,'Parent'));
end

function change_ip(~,~)
    global GUI
    GUI.IP=inputdlg('Enter the Heart IP address','IP Address',1,GUI.IP);%dialog box to specify IP of heart
end

function change_speed(hObject,~)
global GUI
    speed_factor=get(hObject,'Value');
    switch speed_factor
        case 1
            fprintf(GUI.udp_handle,'s1');
            GUI.factor=1;
        case 2
            fprintf(GUI.udp_handle,'s2');
            GUI.factor=2;
        case 3
            fprintf(GUI.udp_handle,'s4');
            GUI.factor=4;
        case 4
            fprintf(GUI.udp_handle,'s10');
          GUI.factor=10;
    end
end

function get_model_info
global GUI
option=questdlg('Choose the type of Heart model',...
        'Model Type',...
        'Simple Model','Complex Model','Simple Model');
    switch option
        case 'Simple Model'
            GUI.heart_model=0;
        case 'Complex Model'
            GUI.heart_model=1;
    end
end

function x=customize_image(image_path)
    [x map]=imread(image_path);
    try
        x=ind2rgb(x,map);
    catch
    end
    for i=1:size(x,1)
        for j=1:size(x,2)
            if(sum(x(i,j,:))==0)
                x(i,j,:)=[255 255 255];%turn black background to white
            end
        end
    end
    
end

function change_position(~,~)
    global GUI
    new_time_stamp=get(GUI.position_slider,'Value');
    GUI.start_point=max(find(GUI.time_stamp_history<=new_time_stamp));%update the point from which to start the playback
end

function switch_modes(hObject,~)
    global GUI
    switch(get(hObject,'Tag'))
    case 'current'%change from real time data capture to playback of activities so far
        if(~GUI.formal_mode)
            if(gather_data(0))
                return;
            end
        end
        GUI.start_point=1;
        set(GUI.position_slider,'Callback',@change_position);
        set(GUI.position_slider,'Min',GUI.time_stamp_history(1));
        set(GUI.position_slider,'Max',GUI.time_stamp_history(end));
        set(GUI.position_slider,'Value',GUI.time_stamp_history(1));
        set(GUI.max_time_display,'String',strcat(num2str(double(uint64((GUI.time_stamp_history(end)-GUI.time_stamp_history(1))/10))/100),'s'),'FontSize',8);
        set(hObject,'CData',customize_image('..\icons\history.png'),'TooltipString','Playback Mode','Tag','playback');
        GUI.mode=1;
    case 'playback'%change to real time data capture
        set(GUI.position_slider,'Callback','');
        set(GUI.position_slider,'Min',0);
        set(GUI.position_slider,'Value',0);
        set(GUI.position_slider,'Max',10);
        set(GUI.max_time_display,'String','Inf','FontSize',14);
        set(hObject,'CData',customize_image('..\icons\clock.png'),'TooltipString','Current Mode','Tag','current');
        GUI.mode=0;
    case 'pon'
        %under construction
    case 'poff'
        %under construction
    end
end

function new_model(~,~)
global GUI
%clear all model specific data
    GUI.ok_to_display=0;
    GUI.logging_in_progress=0;
    GUI.update_in_progress=0;
    GUI.nx=0;
    GUI.px=0;
    GUI.node_table=[];
    GUI.path_table=[];
    GUI.trigger_table=[];
    GUI.nodes_position=[];
    GUI.activated_nodes_position=zeros(1,2);
    GUI.excited_nodes_position=zeros(1,2);
    GUI.relaxed_nodes_position=zeros(1,2);
    delete(GUI.paths_handle);
    GUI.paths_handle=[];
    GUI.add_path_mode=0;
    GUI.time_display=0;
    set(GUI.node_pos,'XData',[],'YData',[]);
    set(GUI.node_table_handle,'Data',GUI.node_table);
    set(GUI.path_table_handle,'Data',GUI.path_table);
    set(GUI.trigger_table_handle,'Data',GUI.trigger_table);
    set(GUI.trigger_table_handle,'ColumnFormat',{'numeric'},'ColumnWidth','auto','ColumnEditable',true,'ColumnName',{'Trigger Count'});    
end

function DatagramReceivedCallback(~,~)%callback for data received on the opened socket
global GUI
    [GUI.current_nodes_states(end+1,:),GUI.current_node_activation_status(end+1,:),GUI.current_path_states(end+1,:),GUI.current_time(end+1,:)]=data_decoder2(fscanf(GUI.udp_handle),GUI.nx,GUI.px);%decode received data and buffer for display
end

function plot_signals(option,curr_time_frame,current_node_activation_status,time_now,no_of_nodes)
    persistent prev_value plot_handle text_handle time_frame offset_matrix working_handle_index handle_list
    global GUI change changed_node signals_list
    if(option==0)
        time_frame=200;%data points per plot
        working_handle_index=9999*ones(1,no_of_nodes);%initialize temporary index
        color_string='ymcrgb';%colors for each signal on the plot
        GUI.plot_axis_handle=axes('Parent',GUI.panel3_handle,'Units','normalized','Position',[0 0 1 1]);%create the axes for the plot
        set(gca,'Color','k');%set background clock of axis to black
        handle_list=[];
        handle_list(1,1)=time_now;%start time of an interval
        handle_list(2,1)=text('Parent',GUI.plot_axis_handle,'Units','data','Position',[time_frame,0],'String',[],'Color','k');%text handle for the interval
        handle_list(3,1)=1;%instantaneous position of the text handle
        handle_list(4,1)=0;%vertical position of the text handle
        handle_list(5,1)=1;%end time of the interval, assigned low value to enable early deletion
        offset_matrix=zeros(1,no_of_nodes);%offset added to each node's signal precomputed for performance
        prev_value=[];
        plot_handle=[];
        text_handle=[];
        hold on;%allows adding plots onto the same axes
        for i=1:no_of_nodes
            offset_matrix(i)=1.5*(no_of_nodes-i);%compute offset
            prev_value(:,i)=offset_matrix(i)*ones(time_frame,1);%create a straight line with suitable offset
            plot_handle(i)=plot(GUI.plot_axis_handle,prev_value(:,i));%plot the straight line
            colorcode=color_string(mod(i,6)+1);%pick a color based on position in the plot
            set(plot_handle(i),'Color',colorcode);%assign chosen color to the plot
            temp_string=strcat('Node ',num2str(i));%create name for the plot
            text_handle(i)=text('Parent',GUI.plot_axis_handle,'Units','data','Position',[0,1.5*(no_of_nodes-i)+0.75],'String',temp_string,'Color','w');%create text to label the plot signals
        end
        set(GUI.plot_axis_handle,'XTick',[],'YTick',[]);%remove markings on x axis and y axis
        set(GUI.plot_axis_handle,'XTickLabel',[],'YTickLabel',[]);
        set(GUI.plot_axis_handle,'box','off');%remove adornments around the axis
        ylim([0 1.5*no_of_nodes]);%set maximum amplitude of the signals to prevent auto resizing by Matlab
        xlim([0 time_frame]);%set maximum data points to prevent auto resizing
        hold off;%stop addition
    end
    if(change~=0)%a node was added/removed from the plot
        %remove offset from the signals for easier computation
        prev_value=prev_value-repmat(offset_matrix,time_frame,1);
        if(change==-1) % a plot is deleted
            %find the index of the deleted plot
            victim_index=sum(changed_node>signals_list)+1;
            %find the text handles to be deleted from the plot
            victim_handles=1.5*(no_of_nodes+1-victim_index)+1;
            hit_list=find(handle_list(4,:)==victim_handles);
            %find plots affected by deletion
            affected_list=find(handle_list(4,:)>victim_handles);
            %adjust the position of the plots above the deleted plot
            handle_list(4,affected_list)=handle_list(4,affected_list)-1.5;
            %delete all relevent figures
            delete(handle_list(2,hit_list));
            delete(text_handle(victim_index));
            delete(plot_handle(victim_index));
            %empty deleted entries
            text_handle(victim_index)=[];
            handle_list(:,hit_list)=[];
            plot_handle(victim_index)=[];
            prev_value(:,victim_index)=[];
            working_handle_index(victim_index)=[];
            offset_matrix(1)=[];
            %update the position of the interval texts with the new location
            for i=1:no_of_nodes
                set(text_handle(i),'Position',[0,offset_matrix(i)+0.75]);
            end
        else %a plot is added
            %find the index of the new plot
            victim_index=find(changed_node==signals_list);
            %find all plots that will be moved as a result
            victim_handles=1.5*(no_of_nodes-victim_index)+1;
            affected_list=find(handle_list(4,:)>=victim_handles);
            handle_list(4,affected_list)=handle_list(4,affected_list)+1.5;
            color_string='ymcrgb';
            %add an offset for the new plot into the offset matrix
            offset_matrix=[1.5*(no_of_nodes-1) offset_matrix];
            hold on;
            if(changed_node==max(signals_list)) %new plot is the last plot
                prev_value(:,end+1)=zeros(time_frame,1);%add another column at the end for the new plot with zeros
                plot_handle(end+1)=plot(GUI.plot_axis_handle,prev_value(:,end));%create a plot for the data points
                colorcode=color_string(mod(changed_node,6)+1);%pick a color for the plot
                set(plot_handle(end),'Color',colorcode);
                temp_string=strcat('Node ',num2str(changed_node));
                text_handle(end+1)=text('Parent',GUI.plot_axis_handle,'Units','data','Position',[0,offset_matrix(end)+0.75],'String',temp_string,'Color','w');%create label for the new plot
                working_handle_index(end+1)=9999;
                for i=1:no_of_nodes
                    set(text_handle(i),'Position',[0,offset_matrix(i)+0.75]);%adjust position of old higher plots to make space for the newer low placed plot
                end
            else if(changed_node==min(signals_list)) % new plot is the first plot
                    prev_value=[zeros(time_frame,1) prev_value];%add another column at the beginning for the new plot
                    plot_handle=[plot(GUI.plot_axis_handle,prev_value(:,1)) plot_handle];%create a plot for the data points
                    colorcode=color_string(mod(changed_node,6)+1);%pick a color for the plot
                    set(plot_handle(1),'Color',colorcode);
                    temp_string=strcat('Node ',num2str(changed_node));
                    text_handle=[text('Parent',GUI.plot_axis_handle,'Units','data','Position',[0,offset_matrix(1)+0.75],'String',temp_string,'Color','w') text_handle];
                    working_handle_index=[9999 working_handle_index];
                    for i=1:no_of_nodes
                        set(text_handle(i),'Position',[0,offset_matrix(i)+0.75]);%adjust position of other plots to make space for teh newer plot
                    end
                else %new plot has to be inserted in between plots
                    %create temporary place holders for the new plot data
                    temp_prev_value=zeros(time_frame,no_of_nodes);
                    temp_plot_handle=zeros(1,no_of_nodes);
                    temp_text_handle=zeros(1,no_of_nodes);
                    temp_working_handle_index=zeros(1,no_of_nodes);
                    for i=1:no_of_nodes
                        if(signals_list(i)<changed_node) %plots before new plot
                            temp_prev_value(:,i)=prev_value(:,i);
                            temp_plot_handle(i)=plot_handle(i);
                            temp_text_handle(i)=text_handle(i);
                            temp_working_handle_index(i)=working_handle_index(i);
                            set(temp_text_handle(i),'Position',[0,offset_matrix(i)+0.75]);
                        else if(signals_list(i)>changed_node) %plots after new plot
                                temp_prev_value(:,i)=prev_value(:,i-1);
                                temp_plot_handle(i)=plot_handle(i-1);
                                temp_text_handle(i)=text_handle(i-1);
                                set(temp_text_handle(i),'Position',[0,offset_matrix(i)+0.75]);
                                temp_working_handle_index(i)=working_handle_index(i-1);
                            else %new plot
                                %create relevant data for the new plot
                                temp_prev_value(:,i)=zeros(time_frame,1);
                                temp_plot_handle(i)=plot(GUI.plot_axis_handle,temp_prev_value(:,i));
                                colorcode=color_string(mod(changed_node,6)+1);
                                set(temp_plot_handle(i),'Color',colorcode);
                                temp_string=strcat('Node ',num2str(changed_node));
                                temp_text_handle(i)=text('Parent',GUI.plot_axis_handle,'Units','data','Position',[0,offset_matrix(i)+0.75],'String',temp_string,'Color','w');
                                temp_working_handle_index(i)=9999;
                            end
                        end
                    end
                    prev_value=temp_prev_value;
                    plot_handle=temp_plot_handle;
                    text_handle=temp_text_handle;
                    working_handle_index=temp_working_handle_index;
                end
            end
            hold off;
        end
        prev_value=prev_value+repmat(offset_matrix,time_frame,1);
        ylim([0 1.5*no_of_nodes]);
        change=0;
    end
    if(time_frame==curr_time_frame)
        prev_value(1,:)=[];%remove first data point to accommodate for the newer value added to the end
        handle_list(3,:)=handle_list(3,:)-1;%mimic movement of the plot, shift data points to the left and likewise, the text position as well
        handle_list(5,:)=handle_list(5,:)-1;
    else if(time_frame<curr_time_frame)
            time_frame=time_frame+1;
        else            
            prev_value(1:time_frame-curr_time_frame+1,:)=[];%resize the array to match the datapoints on the plot
            handle_list(3,:)=handle_list(3,:)-(time_frame-curr_time_frame+1);%mimic movement of the plot, shift data points to the left and likewise, the text position as well
            handle_list(5,:)=handle_list(5,:)-(time_frame-curr_time_frame+1);
            time_frame=curr_time_frame;
        end
        xlim([0 time_frame]);
    end
    prev_value(end+1,:)=current_node_activation_status+offset_matrix;%append newer values
    for i=1:no_of_nodes,
        if((current_node_activation_status(i)==1)&&(offset_matrix(i)==prev_value(end-1,i)))%positive edge detection
            temp_array(1)=time_now;%start time of the interval
            temp_array(3)=time_frame;%text position on the plot
            temp_array(4)=1.5*(no_of_nodes-i)+1;%y axis position
            temp_array(5)=time_frame;%end time of the interval
            temp_array(2)=text('Parent',GUI.plot_axis_handle,'Units','data','Position',[time_frame,temp_array(4)],'String',[],'HitTest','off','Color','w');%create empty text field
            handle_list(:,end+1)=temp_array;%assign temporary structure to handle list
            almost_finished_handle=working_handle_index(i);%one positive edge means the end of interval of the previous positive pulse
            working_handle_index(i)=size(handle_list,2);%current text handle is the last element in the handle_list, number of columns give the position of the last element in the column
            if(almost_finished_handle<=size(handle_list,2))%if text under construction already deleted, do nothing
                handle_list(5,almost_finished_handle)=handle_list(3,almost_finished_handle);
                handle_list(3,almost_finished_handle)=(time_frame+handle_list(3,almost_finished_handle))/2-1;%update text position before making it visible
                set(handle_list(2,almost_finished_handle),'Position',[handle_list(3,almost_finished_handle),handle_list(4,almost_finished_handle)],'String',num2str(time_now-handle_list(1,almost_finished_handle)));
            end
        end
        set(plot_handle(i),'YData',prev_value(:,i));%refresh all the plots
    end
    hit_list=find(handle_list(5,:)<=1);%texts fallen way too left can be deleted. Find deletable text handles
    delete(handle_list(2,hit_list));%delete out of view text handles
    handle_list(:,hit_list)=[];%empty deleted text handle placeholders
    for i=1:no_of_nodes,
        working_handle_index(i)=working_handle_index(i)-sum(working_handle_index(i)>hit_list);%adjust the indices of the intervals under construction by reducing the index as many times as as many deleted elements before this index
    end
    for i=1:size(handle_list,2)
        set(handle_list(2,i),'Position',[handle_list(3,i),handle_list(4,i)]);%refresh all the texts on the axes with the correct position
    end
    pause(0.000001);%nominal time to allow for plot to be displayed
end

function pace_nodes(~,~)
    global GUI
    fprintf(GUI.udp_handle,'pppp');%p's enable programmed triggering of the paces
end

function emergency_pacer(~,~)%pace at will
    global GUI
    if(GUI.node_in_focus)        
        fprintf(GUI.udp_handle,['e' num2str(GUI.node_in_focus-1)]); 
        set(GUI.node_hint_text_handle,'String','Paced');
    end
end

function run_model(hObject,~)
    global GUI
    persistent button_states
    if(config_check~=1)
        return;
    end
    if(strcmp(get(hObject,'String'),'Play'))
        response=1;
        if(~GUI.mode&&~GUI.formal_mode)
            response=update_tables;
        end
        if(response==1)
            delete(instrfindall);
            delete(timerfindall);
            set(hObject,'String','Stop');
%             button_states.view_history=get(GUI.view_history_handle,'Enable');
%             button_states.new_option=get(GUI.new_file_handle,'Enable');
%             button_states.load_option=get(GUI.load_file_handle,'Enable');
%             button_states.save_option=get(GUI.save_file_handle,'Enable');
%             button_states.add_path_option=get(GUI.add_path_handle,'Enable');
%             button_states.upload_trigger_table=get(GUI.load_trigger_table_handle,'Enable');
%             set(GUI.view_history_handle,'Enable','off');
%             set(GUI.new_file_handle,'Enable','off');
%             set(GUI.load_file_handle,'Enable','off');
%             set(GUI.save_file_handle,'Enable','off');
%             set(GUI.load_trigger_table_handle,'Enable','off');
%             set(GUI.node_table_handle,'Enable','off');
%             set(GUI.path_table_handle,'Enable','off');
%             set(GUI.trigger_table_handle,'Enable','off');
            set(GUI.pace_button,'Enable','on');
            set(GUI.activated_node_pos,'XData',[],'YData',[]);
            set(GUI.relaxed_node_pos,'XData',[],'YData',[]);
            set(GUI.excited_node_pos,'XData',[],'YData',[]);
            set(GUI.activated_node_pos,'Visible','on');
            set(GUI.relaxed_node_pos,'Visible','on');
            set(GUI.excited_node_pos,'Visible','on');
            set(GUI.heart_axes_handle,'ButtonDownFcn',@emergency_pacer);
            GUI.heart_rate_text=text('Parent',GUI.heart_axes_handle,'Units','normalized','Position',[0.8 0.925],'String','HEART RATE','HitTest','off','Color','k','FontSize',15);
            GUI.heart_rate_field=text('parent',GUI.heart_axes_handle,'Units','normalized','Position',[0.795 0.89],'String','0BPM','HitTest','off','Color','g','FontSize',30);
            %set up of the buffers
            if(GUI.mode)
                if(GUI.start_point==size(GUI.time_stamp_history,1))
                    GUI.start_point=1;
                end
                GUI.current_nodes_states=GUI.nodes_states_history(GUI.start_point:end,:);
                GUI.current_node_activation_status=GUI.node_activation_status_history(GUI.start_point:end,:);
                GUI.current_path_states=GUI.path_states_history(GUI.start_point:end,:);
                GUI.current_time=GUI.time_stamp_history(GUI.start_point:end,:);
                setup_display_routine(0.5,99999999,@plot_refresher);
                start(GUI.periodic_function_handle);
            else
                if(~GUI.formal_mode)
                    GUI.current_nodes_states=ones(1,GUI.nx);
                    GUI.current_node_activation_status=zeros(1,GUI.nx);
                    GUI.current_path_states=ones(1,GUI.px);
                    GUI.current_time=0;
                    setup_display_routine(0,99999999,@plot_refresher);%very large number of executions for approximation to infinite executions
                    GUI.udp_handle = udp(GUI.IP{1}, 4950, 'LocalPort', 4950);
                    set(GUI.udp_handle,'DatagramTerminateMode','on');
                    set(GUI.udp_handle, 'ReadAsyncMode', 'continuous');
                    GUI.udp_handle.DatagramReceivedFcn=@DatagramReceivedCallback;
                    fopen(GUI.udp_handle);
                    fprintf(GUI.udp_handle,'x');
                    change_speed(GUI.speed_list,0);
                    start(GUI.periodic_function_handle);
                end
            end
            
        else
            errordlg('Could not run model','error','modal');
            return;
        end
    else
        if(~GUI.mode&&~GUI.formal_mode)
            GUI.udp_handle.DatagramReceivedFcn='';
            fprintf(GUI.udp_handle,'s0');
            flushinput(GUI.udp_handle);
            fclose(GUI.udp_handle);
            clear GUI.udp_handle;
        end
        if(~GUI.formal_mode)
            stop_display_routine;
        end
        set(GUI.activated_node_pos,'Visible','off');
        set(GUI.relaxed_node_pos,'Visible','off');
        set(GUI.excited_node_pos,'Visible','off');
%         set(GUI.view_history_handle,'Enable',button_states.view_history);
%         set(GUI.new_file_handle,'Enable',button_states.new_option);
%         set(GUI.load_file_handle,'Enable',button_states.load_option);
%         set(GUI.save_file_handle,'Enable',button_states.save_option);
%         set(GUI.edit_menu,'Enable',button_states.edit_menu);
%         set(GUI.play_mode,'Enable',button_states.mode_menu);
%         set(GUI.load_trigger_table_handle,'Enable',button_states.upload_trigger_table);
%         set(GUI.pause_button_handle,'Enable','off');
        GUI.ok_to_display=0;
        try
            delete(GUI.plot_axis_handle);
            delete(GUI.datapoints);
            delete(GUI.curr_time_frame_handle);
            delete(GUI.time_frame_slider);
            for i=1:GUI.nx,
                delete(GUI.signals_selection_button_handle(i));
            end
        catch
        end
        delete(GUI.heart_rate_text);
        delete(GUI.heart_rate_field);
        set(GUI.node_table_handle,'Visible','on');
        set(GUI.path_table_handle,'Visible','on');
        set(GUI.trigger_table_handle,'Visible','on');   
        set(GUI.show_signals_handle,'String','Show Signals');
%         set(GUI.pace_button,'Enable','off');
        set(GUI.heart_axes_handle,'ButtonDownFcn',@button_press);
        %display_signals_or_tables(GUI.show_signals_handle,0);
        set(hObject,'String','Play');
    end
end

function setup_display_routine(start_delay,no_of_executions,function_name)
    global GUI
    %set up the timer callback to be scheduled at period of 1ms
    GUI.periodic_function_handle=timer('StartDelay',start_delay,'Period',0.001,'TasksToExecute',no_of_executions,'ExecutionMode','fixedDelay','BusyMode','drop');%Period should be 0.001
    GUI.periodic_function_handle.TimerFcn=function_name;
end

function stop_display_routine
    global GUI
    %stop the timer callback routine
    stop(GUI.periodic_function_handle);
    %flush all data present in the buffers
    GUI.current_nodes_states=[];
    GUI.current_node_activation_status=[];
    GUI.current_path_states=[];
    GUI.current_time=[];
    delete(GUI.periodic_function_handle);%delete timer handle
end

function plot_refresher(varargin)
    global GUI change signals_list no_of_nodes curr_time_frame
    persistent option temp_nodes_states temp_node_activation_status temp_path_states temp_current_time prev_v_node_activation_time prev_v_node_activation_status
    if(~isempty(GUI.current_nodes_states))
        %read the first element from all the buffers
        temp_nodes_states=GUI.current_nodes_states(1,:);
        temp_node_activation_status=GUI.current_node_activation_status(1,:);
        temp_path_states=GUI.current_path_states(1,:);
        temp_current_time=GUI.current_time(1,:);
        %remove the read elements
        GUI.current_nodes_states(1,:)=[];
        GUI.current_node_activation_status(1,:)=[];
        GUI.current_path_states(1,:)=[];
        GUI.current_time(1,:)=[];
    end 
    if(GUI.ok_to_display==1)
        if(change~=0)
            no_of_nodes=size(signals_list,2);
        end
        plot_signals(option,curr_time_frame,temp_node_activation_status(signals_list),temp_current_time,no_of_nodes);%call plot_signal function with suitable arguments
        option=1;
    else 
        pause(0.000001);
        option=0;
    end
    colorcodes='bgrcw';
    GUI.relaxed_nodes_position=GUI.nodes_position(temp_nodes_states==1,:);%find all the nodes in Rest
    GUI.excited_nodes_position=GUI.nodes_position(temp_nodes_states==2,:);%find all the nodes in ERP
    GUI.activated_nodes_position=GUI.nodes_position(temp_node_activation_status==1,:);%find all the nodes currently activated
    set(GUI.relaxed_node_pos,'XData',GUI.relaxed_nodes_position(:,1),'YData',GUI.relaxed_nodes_position(:,2));
    set(GUI.excited_node_pos,'XData',GUI.excited_nodes_position(:,1),'YData',GUI.excited_nodes_position(:,2));
    set(GUI.activated_node_pos,'XData',GUI.activated_nodes_position(:,1),'YData',GUI.activated_nodes_position(:,2));
    if(temp_node_activation_status(GUI.nx)==1)%V node is activated
        if((~isempty(prev_v_node_activation_status))&&(temp_node_activation_status(GUI.nx)~=prev_v_node_activation_status)&&(~isempty(prev_v_node_activation_time)))
            heart_rate=floor(60000/(temp_current_time-prev_v_node_activation_time));
            if(heart_rate>=40&&heart_rate<=100)
                set(GUI.heart_rate_field,'String',[num2str(heart_rate) 'BPM'],'Color','g');
            else
                set(GUI.heart_rate_field,'String',[num2str(heart_rate) 'BPM'],'Color','r');
            end
        end
        prev_v_node_activation_time=temp_current_time;
    end
    prev_v_node_activation_status=temp_node_activation_status(GUI.nx);
    for i=1:GUI.px
        set(GUI.paths_handle(i),'Color',colorcodes(temp_path_states(i)));
    end
    if(GUI.mode)
        if((temp_current_time>=GUI.time_stamp_history(end))||(GUI.time_stamp_history(1)>=GUI.time_stamp_history(end)))
            %disp('ending routine');
            run_model(GUI.play_or_stop_button,0);
        end
        set(GUI.position_slider,'Value',temp_current_time);
        GUI.start_point=find(temp_current_time==GUI.time_stamp_history);
    end
end

function update_GUI(node_table,path_table)%called when heart model is a script to update the GUI
    global time_stamp GUI
    persistent prev_nodes_states prev_node_activation_status prev_path_states
    if(iscell(node_table)==iscell(path_table))
        if(iscell(node_table))%different ways to access node and path table depending on their data types
            current_nodes_states=cell2mat(node_table(:,1+GUI.heart_model)');
            current_node_activation_status=cell2mat(node_table(:,6+GUI.heart_model*4)');
            current_path_states=cell2mat(path_table(:,1+GUI.heart_model)');
        else if(isnumeric(node_table))
                current_nodes_states=node_table(:,1+GUI.heart_model)';
                current_node_activation_status=node_table(:,6+GUI.heart_model*4)';
                current_path_states=path_table(:,1+GUI.heart_model)';
            else
                disp('invalid datatype for node_table and path_table');
                return;
            end
        end
    else
        disp('Datatype for node table and path table are not valid');
        return;
    end
    if((time_stamp==1)||sum(prev_nodes_states-current_nodes_states)||sum(prev_node_activation_status-current_node_activation_status)||sum(prev_path_states-current_path_states))%update the GUI only when any of the signals change
        prev_nodes_states=current_nodes_states;
        GUI.current_nodes_states=prev_nodes_states;
        prev_node_activation_status=current_node_activation_status;
        GUI.current_node_activation_status=prev_node_activation_status;
        prev_path_states=current_path_states;
        GUI.current_path_states=prev_path_states;
        GUI.current_time=time_stamp;
    end
    plot_refresher;
    time_stamp=time_stamp+1;
end

function change_time_frame(hObject,~)
    global curr_time_frame GUI
    try
        if(hObject==GUI.curr_time_frame_handle)
            temp_time_frame=str2double(get(hObject,'String'));
            if((int64(abs(temp_time_frame))==temp_time_frame)&&(temp_time_frame<=10100))
                set(GUI.time_frame_slider,'Value',temp_time_frame);
                curr_time_frame=temp_time_frame;
            else
                set(hObject,'String',num2str(curr_time_frame));
            end
        else
            curr_time_frame=double(int64(get(hObject,'Value')));
            set(GUI.curr_time_frame_handle,'String',num2str(curr_time_frame));
        end
    catch
        curr_time_frame=200;
    end
end
function display_signals_or_tables(hObject,~)
    global GUI change signals_list no_of_nodes curr_time_frame
    if(strcmp(get(hObject,'String'),'Show Signals')==1) %setup axis for signals display
        if(config_check~=1)%check that the environment is in order
            return;
        end
        if(strcmp(get(GUI.play_or_stop_button,'String'),'Play'))%check that the heart model is running
            errordlg('Model not running','error','modal');
            return;
        end

        if((GUI.logging_in_progress==1)||(GUI.update_in_progress==1))%make sure other windows are not open
            errordlg('Close other Windows before continuing','Multiple windows open!','modal');
            return;
        end
        %make the tables invisible and setup the radiobuttons for plot
        %selection
        set(GUI.node_table_handle,'Visible','off');
        set(GUI.path_table_handle,'Visible','off');
        set(GUI.trigger_table_handle,'Visible','off');
        uipanel_position=getpixelposition(GUI.panel4_handle);
        for i=1:GUI.nx,
            GUI.signals_selection_button_handle(i)=uicontrol('Parent',GUI.panel4_handle,'Style','radiobutton'...
            ,'String',''...
            ,'Units','Normalized'...
            ,'Position',[0.005 ((2*(GUI.nx-i+1)-1)/(GUI.nx*2)) 0.99 0.99*uipanel_position(3)/uipanel_position(4)]...
            ,'BackgroundColor',[0.7 0.9 0.8]...
            ,'Callback',@signals_to_display_picker,'Value',1);
        end
        GUI.datapoints=uicontrol('Style','text',...
            'String','Datapoints',...
            'Units','Normalized',...
            'ForegroundColor','Red',...
            'BackgroundColor',[0.7 0.9 0.8],...
            'HorizontalAlignment','center',...
            'Position',[0.57 0.97 0.03 0.025]);
        GUI.curr_time_frame_handle=uicontrol('Style','edit',...
            'String','200',...
            'Units','Normalized',...
            'BackgroundColor','White',...
            'Position',[0.6 0.97 0.025 0.025],...
            'Callback',@change_time_frame);
        GUI.time_frame_slider=uicontrol('Style','slider',...
            'Min',100,...
            'Max',10100,...
            'Value',200,...
            'Units','normalized',...
            'Position',[0.625 0.97 0.37 0.025],...
            'SliderStep',[0.005 0.01],...
            'Callback',@change_time_frame);
        no_of_nodes=GUI.nx;
        change=0;
        signals_list=1:GUI.nx;
        curr_time_frame=200;
        GUI.ok_to_display=1;
        set(hObject,'String','Show Tables');
    else
        %switch to showing only the tables
        GUI.ok_to_display=0;
        %delete the plot and the radio buttons
        delete(GUI.plot_axis_handle);
        delete(GUI.datapoints);
        delete(GUI.curr_time_frame_handle);
        delete(GUI.time_frame_slider);
        for i=1:GUI.nx,
            delete(GUI.signals_selection_button_handle(i));
        end
        set(GUI.node_table_handle,'Visible','on');
        set(GUI.path_table_handle,'Visible','on');
        set(GUI.trigger_table_handle,'Visible','on');   
        set(hObject,'String','Show Signals');
    end        
end

function signals_to_display_picker(hObject,eventdata)
%called when one of the radio buttons is pressed
global GUI signals_list change changed_node
    for i=1:GUI.nx
        if(eq(hObject,GUI.signals_selection_button_handle(i)))%find the radiobutton pressed and change signals_list accordingly
            if(sum(signals_list==i))
                change=-1;
                signals_list(signals_list==i)=[];
            else
                change=1;
                signals_list(end+1)=i;
                signals_list=sort(signals_list);
            end
            changed_node=i;
            return;
        end
    end
end
       
function response=gather_data(fill)%fill==1 --> interpolate, fill==0 -->don't interpolate
    global GUI
    response=0;
    delete(instrfindall);
    delete(timerfindall);
    waitbar_handle=waitbar(0,'Gathering Data...');%setup fancy waitbar to indicate progress
    GUI.udp_handle = udp(GUI.IP{1}, 4950, 'LocalPort', 4950);%connect to heart
    set(GUI.udp_handle,'DatagramTerminateMode','off');
    fopen(GUI.udp_handle);
    fprintf(GUI.udp_handle,'x');
    pause(1);
    fprintf(GUI.udp_handle,'l');
    %below loop is an effective way to remove all available data in the
    %input buffer so that only history will be available in the buffer
    while(GUI.udp_handle.BytesAvailable)
        fscanf(GUI.udp_handle);
    end
    fprintf(GUI.udp_handle,'ok');
    data=fscanf(GUI.udp_handle);
    Log_plot_helper2(0,data,GUI.nx,GUI.px,fill);
    loop_count=1;
    while(1)
      fprintf(GUI.udp_handle,'ok');%send acknowledgement for every datagram received, without this, heart won't continue sending data
      data=fscanf(GUI.udp_handle);
      if(~isempty(find(data=='e',1)))
          break;
      end
      Log_plot_helper2(1,data,GUI.nx,GUI.px,fill);
      waitbar(loop_count/1000,waitbar_handle);
      loop_count=loop_count+1;
    end
    fclose(GUI.udp_handle);
    clear GUI.udp_handle;
    close(waitbar_handle);
end

function display_log(hObject,~)
    global GUI
    global start_time;
    global duration current_range x_limit;
    global Heart_log;
    global click_count;
    if(config_check~=1)
        return;
    end
    GUI.logging_in_progress=1;%indicate to other callbacks about this operation
    if((GUI.ok_to_display==1)||(GUI.update_in_progress==1))
        errordlg('Close other Windows before continuing','Multiple windows open!','modal');
        GUI.logging_in_progress=0;
        return;
    end
    if(gather_data(1))%interpolate data for convenient data manipulation
        GUI.logging_in_progress=0;
        return;
    end
    duration=size(GUI.node_activation_status_history,1);
    current_range=zeros(duration,GUI.nx);
    Heart_log.figure_handle=figure('Units', 'normalized'...
        ,'Position', [0 0 1 1]...
        ,'Resize','on'...
        ,'Name','Heart Log'...
        ,'NumberTitle','Off');
    set(Heart_log.figure_handle,'MenuBar','none');
    set(Heart_log.figure_handle,'ToolBar','none');
    Heart_log.axes_handle=axes('Units','normalized'...
        ,'Parent',Heart_log.figure_handle...
        ,'YTick',[]...
        ,'NextPlot','add'...
        ,'Position',[0.005 0.1 0.99 0.895]);
%     uicontrol('Style','text','String','Offset'...
%         ,'Units','normalized'...
%         ,'Position',[0.03 0.05 0.025 0.025]...
%         ,'BackgroundColor','black'...
%         ,'ForegroundColor','white'...
%         ,'HorizontalAlignment','center');
%     Heart_log.offset_field=uicontrol('Style','text','String','0ms',...
%         'Units','normalized',...
%         'Position',[0.055 0.05 0.025 0.025],...
%         'BackgroundColor','black',...
%         'ForegroundColor','white',...
%         'HorizontalAlignment','center');
    Heart_log.lower_limit_field=uicontrol('Style','text','String','0s'...
        ,'Units','normalized'...
        ,'Position',[0.005 0.025 0.025 0.025]);
    %two slide bars to change the range of viewable data and resolution
    Heart_log.slider1_handle=uicontrol('Style','slider'...
        ,'Min',1,...
        'Max',duration...
        ,'Value',1,...
        'Units','normalized'...
        ,'Position',[0.03 0.025 0.935 0.025]...
        ,'SliderStep',[1/duration 10/duration]...
        ,'Callback',@replot);
    Heart_log.slider2_handle=uicontrol('Style','slider'...
        ,'Min',1,...
        'Max',duration...
        ,'Value',duration,...
        'Units','normalized'...
        ,'Position',[0.03 0 0.935 0.025]...
        ,'SliderStep',[1/duration 10/duration]...
        ,'Callback',@replot);
    Heart_log.higher_limit_field=uicontrol('Style','text','String',strcat(num2str(duration/1000),'s')...
        ,'Units','normalized'...
        ,'Position',[0.965 0.025 0.03 0.025]);
    whitebg(Heart_log.figure_handle,'k');
    Heart_log.interval_text_handle=text('Units','data','Position',[0 0],'String','','HitTest','off');
    set(Heart_log.axes_handle,'ButtonDownFcn',@set_time_interval);%callback registered when button pressed on the plot
    x_limit=GUI.time_stamp_history(end) - GUI.time_stamp_history(1);
    click_count=0;
    color_string='ymcrgb';
    hold on;
    for i=1:GUI.nx
        current_range(:,i)=GUI.node_activation_status_history(1:duration,i)+1.5*(GUI.nx-i);
        Heart_log.plot_handle(i)=plot(current_range(:,i));
        colorcode=color_string(mod(i,6)+1);
        set(Heart_log.plot_handle(i),'Color',colorcode);%,'XDataSource','x_limit'
        set(Heart_log.plot_handle(i),'YDataSource','current_range(:,i)','HitTest','off');
        temp_string=strcat('Node ',num2str(i));
        Heart_log.label_handle(i)=text('Units','data','Position',[x_limit/2,1.5*(GUI.nx-i)+0.75],'String',temp_string,'HitTest','off');
    end
    hold off;
    set(Heart_log.axes_handle,'YTickLabel',[]);
    set(Heart_log.axes_handle,'box','off');
    ylim([0 1.5*GUI.nx]);
    xlim([0 GUI.time_stamp_history(end)-GUI.time_stamp_history(1)]);
    %set(hObject,'String','Plot Heart Log');
    GUI.logging_in_progress=0;
end

function replot(~,~)%this function called when the sliders are moved
    %Adjust the range of viewable data points based on the position of the
    %sliders
    global Heart_log current_range GUI x_limit
    lower_limit=uint64(get(Heart_log.slider2_handle,'Value'));
    higher_limit=uint64(get(Heart_log.slider1_handle,'Value'));
    if(lower_limit>higher_limit)
        temp=lower_limit;
        lower_limit=higher_limit;
        higher_limit=temp;
    end
    x_limit=higher_limit-lower_limit;
    current_range=zeros(higher_limit-lower_limit+1,GUI.nx);
    %sum(current_range)
    for i=1:GUI.nx
        current_range(:,i)=GUI.node_activation_status_history(lower_limit:higher_limit,i)+1.5*(GUI.nx-i);
        set(Heart_log.label_handle(i),'Position',[x_limit/2,1.5*(GUI.nx-i)+0.75]);
        refreshdata(Heart_log.plot_handle(i),'caller');
    end
    set(Heart_log.lower_limit_field,'String',[num2str(lower_limit) 'ms']);
    set(Heart_log.higher_limit_field,'String',[num2str(higher_limit) 'ms']);
    xlim([0 higher_limit-lower_limit]);
end

function set_time_interval(hObject,~)
    %This function displays the time interval between two points on the
    %plot. First click establishes first point, second click establishes
    %the last point and simultaneously causes time interval to be displayed
    global Heart_log click_count GUI
    persistent start_position end_position
    mark_pt=round(get(hObject,'CurrentPoint'));
    if(click_count>1)
        delete(Heart_log.start_marker_handle);
        delete(Heart_log.end_marker_handle);
        set(Heart_log.interval_text_handle,'String','');
        click_count=0;
    end
    if(click_count==0)
        hold on;
        click_count=1;
        start_position=mark_pt;
        Heart_log.start_marker_handle=stem(Heart_log.axes_handle,mark_pt(1,1),1.5*GUI.nx,'Color',[1 0.5 0],'LineStyle',':','Marker','<');
    else
        click_count=2;
        end_position=mark_pt;
        Heart_log.end_marker_handle=stem(Heart_log.axes_handle,mark_pt(1,1),1.5*GUI.nx,'Color',[1 0.5 0],'LineStyle',':','Marker','>');
        if(start_position(1)>end_position(1))
            pos=end_position(1)+(start_position(1)-end_position(1))/2;
        else
            pos=start_position(1)+(end_position(1)-start_position(1))/2;
        end
        set(Heart_log.interval_text_handle,'String',strcat(num2str(abs(start_position(1)-end_position(1))),'ms'),'Position',[pos 1.5*GUI.nx]);
        hold off;
    end        
end

function upload_trigger_table(~,~)%setup the programmed trigger on the heart
    global GUI
    if(size(get(GUI.trigger_table_handle,'Data'),1)~=GUI.nx)
        errordlg('Trigger Table does not have the same number of nodes as the heart configuration','Configuration Mismatch','modal');
        return;
    end
    %Data pattern sent to the heart%
    %<no_of_rows of node_table>,<no_of_cols of node_table>,<trigger table
    %row wise seperated by commas>,z
    GUI.trigger_table=get(GUI.trigger_table_handle,'Data');
    max_paces=max(GUI.trigger_table(:,1));
    nx_string=num2str(GUI.nx);
    ny_string=num2str(GUI.ny);
    transmit=strcat(nx_string,',',ny_string);
    edited_trigger_table=zeros(GUI.nx,21);
    for i=1:GUI.nx,
        for j=max_paces+1:-1:1,
            if((~isnan(GUI.trigger_table(i,j)))&&((round(GUI.trigger_table(i,j))~=GUI.trigger_table(i,j))||(GUI.trigger_table(i,j)<0)))
                errordlg('Invalid data found in the table','Data error','modal');
                return;
            end
            if((GUI.trigger_table(i,1)~=0)&&(j~=1)&&(j<=(GUI.trigger_table(i,1)+1))&&(GUI.trigger_table(i,j)==0))
                errordlg('Zero interval between paces found in the table','Hazardous Pacing Setup','modal');
                return;
            end
            if(isnan(GUI.trigger_table(i,j)))
                edited_trigger_table(i,j)=0;
            else
                edited_trigger_table(i,j)=GUI.trigger_table(i,j);
            end
        end
    end
    
    %The character 'z' indicates end of transmission
    for i=1:GUI.nx,
        for j=1:21,
            transmit=strcat(transmit,',',num2str(edited_trigger_table(i,j)));
        end
    end
    transmit=strcat(transmit,',z');
    delete(instrfindall);
    delete(timerfindall);
    GUI.udp_handle = udp(GUI.IP{1}, 4950, 'LocalPort', 4950);
    set(GUI.udp_handle,'DatagramTerminateMode','off');
    fopen(GUI.udp_handle);
    fprintf(GUI.udp_handle,'a');
    pause(1);
    fprintf(GUI.udp_handle,'t');
    pause(1);
    flushinput(GUI.udp_handle);
    fprintf(GUI.udp_handle,transmit);
    in=str2double(fscanf(GUI.udp_handle));
    if(in==size(transmit))
        msgbox('Update Complete!','Success');
    else
        %msgbox('Update Failed, please try again','Error','error');
    end
    fclose(GUI.udp_handle);
    clear GUI.udp_handle;
end

function update_meaning(~,eventdata)
    %update the tooltip when mouse hovers over the trigger table
    global GUI
    edited_cell=eventdata.Indices(1,:);
    if(edited_cell(2)==1)
        if(eventdata.NewData<0)
            errordlg('Invalid number for this field, only non negative numbers allowed','Wrong Entry','modal'); 
            set(GUI.trigger_table_handle,'Data',GUI.trigger_table);
        else if(eventdata.NewData>GUI.MAX_PACES)
                errordlg('Maximum number of Paces allowed is 20','Reduce Paces','modal'); 
                set(GUI.trigger_table_handle,'Data',GUI.trigger_table);
            else
                update_t_table_on_GUI(eventdata.NewData,GUI.trigger_table,get(GUI.trigger_table_handle,'Data'));
            end
        end
    end
end

function update_t_table_on_GUI(newdata,old_table,new_table)
    %complex code to expand and compress the trigger table depending on max
    %paces
    global GUI
    col_count=max(0,max(old_table(:,1)));
    if(col_count<newdata)   
        GUI.trigger_table=[new_table zeros(GUI.nx,newdata-col_count)];
        temp_columnformat_string={'numeric'};
        temp_columneditable_array=true;
        temp_columnname_string={'Pace Count'};
        for i=1:newdata,
            temp_columnformat_string{1,1+i}='numeric';
            temp_columneditable_array=[temp_columneditable_array,true];
            temp_columnname=['Pace ',num2str(i),' interval'];
            temp_columnname_string{1,1+i}=temp_columnname;      
        end
        set(GUI.trigger_table_handle,'Data',GUI.trigger_table,...
            'ColumnFormat',temp_columnformat_string,'ColumnEditable',temp_columneditable_array,'ColumnName',temp_columnname_string);
    else
       new_col_count=max(0,max(new_table(:,1)));
       if(col_count>new_col_count)
            new_table(:,new_col_count+2:end)=[];
            GUI.trigger_table=new_table;
            temp_columnformat_string=get(GUI.trigger_table_handle,'ColumnFormat');
            temp_columneditable_array=get(GUI.trigger_table_handle,'ColumnEditable');
            temp_columnname_string=get(GUI.trigger_table_handle,'ColumnName');
            temp_columnformat_string(new_col_count+2:end)=[];
            temp_columneditable_array(new_col_count+2:end)=[];
            temp_columnname_string(new_col_count+2:end)=[];
            set(GUI.trigger_table_handle,'Data',GUI.trigger_table,...
                'ColumnFormat',temp_columnformat_string,'ColumnEditable',temp_columneditable_array,'ColumnName',temp_columnname_string);
       end
    end
    GUI.trigger_table=get(GUI.trigger_table_handle,'Data');
    for i=1:GUI.nx
        for j=2:size(GUI.trigger_table,2)
            if(isnan(GUI.trigger_table(i,j))&&(j<=(GUI.trigger_table(i,1)+1)))
                GUI.trigger_table(i,j)=0;
            end
            if(j>(GUI.trigger_table(i,1)+1))
                GUI.trigger_table(i,j)=NaN;
            end
        end
    end
    set(GUI.trigger_table_handle,'Data',GUI.trigger_table);
end

function create_t_table_on_GUI(trigger_table,figure_handle)
    %creates trigger table and populates it when a model is loaded
    global GUI
    col_count=max(trigger_table(:,1));
    GUI.trigger_table=trigger_table;
    temp_columnformat_string={'numeric'};
    temp_columneditable_array=true;
    temp_columnname_string={'Trigger Count'};
    for i=1:col_count,
        temp_columnformat_string{1,1+i}='numeric';
        temp_columneditable_array=[temp_columneditable_array,true];
        temp_columnname=['Pace ',num2str(i),' interval'];
        temp_columnname_string{1,1+i}=temp_columnname;
    end
    set(figure_handle,'Data',GUI.trigger_table,...
    'ColumnFormat',temp_columnformat_string,'ColumnEditable',temp_columneditable_array,'ColumnName',temp_columnname_string);
end

function load_model(filepath)
    global GUI
    load(filepath);
    if((GUI.heart_model && (size(node_table,2)~=12 || size(path_table,2)~=8))||(~GUI.heart_model && (size(node_table,2)~=7 || size(path_table,2)~=7)))
        errordlg('Please load the correct heart model','Wrong tables structure','modal');
        return;
    end
    GUI.node_table=node_table;
    GUI.path_table=path_table;
    try
        create_t_table_on_GUI(trigger_table,GUI.trigger_table_handle);
    catch
    end
    GUI.nx=size(GUI.node_table,1);
    GUI.ny=size(GUI.node_table,2);
    GUI.px=size(GUI.path_table,1);
    GUI.py=size(GUI.path_table,2);
    set(GUI.node_table_handle,'Data',GUI.node_table);
    set(GUI.path_table_handle,'Data',GUI.path_table);
    GUI.nodes_position=node_pos;
    set(GUI.node_pos,'XData',node_pos(:,1),'YData',node_pos(:,2));
    try
        delete(GUI.paths_handle);
    catch
    end
    GUI.paths_handle=[];
    for i=1:GUI.px
        GUI.paths_handle(end+1)=line([node_pos(path_table(i,2),1) node_pos(path_table(i,3),1)],[node_pos(path_table(i,2),2) node_pos(path_table(i,3),2)],'LineWidth',5,'HitTest','off','Parent',GUI.heart_axes_handle);
    end
    %update_tooltip;
end

function response=update_tables
    global GUI
    if(config_check~=1)
        return;
    end
    GUI.update_in_progress=1;
    GUI.node_table=get(GUI.node_table_handle,'Data');
    GUI.path_table=get(GUI.path_table_handle,'Data');
    %%%Check for correctness of entries first%%%
    response=0;
    if(sum(sum((round(GUI.node_table)~=GUI.node_table)))||sum(sum(round(GUI.path_table)~=GUI.path_table)))
        errordlg('decimal values found in the table(s)','Decimal values not allowed!!!','modal');
        GUI.update_in_progress=0;
        return;
    end
    display_string1='Node table Entries:';
    error1=0;
    for i=1:GUI.nx,
        skiplist=[];
        for j=1:GUI.ny,
            if(GUI.node_table(i,j)<0)
                error1=1;
                skiplist=[skiplist,j];
                display_string1=[display_string1,'(',num2str(i),',',num2str(j),')::'];
            end
        end
        if(GUI.node_table(i,1)>(2+GUI.heart_model))
            error1=1;
            if(isempty(find(skiplist==1)))
                display_string1=[display_string1,'(',num2str(i),',1)::'];
            end
        end
        if(GUI.heart_model)
            if(GUI.node_table(i,12)>1)
                error1=1;
                if(isempty(find(skiplist==12)))
                    display_string1=[display_string1,'(',num2str(i),',12)::'];
                end
            else
                if(GUI.node_table(i,12)==0 && GUI.node_table(i,9)<GUI.node_table(i,8))
                    error1=1;
                    if(isempty(find(skiplist==8)))
                        display_string1=[display_string1,'(',num2str(i),',8)::'];
                    end
                end
                if(GUI.node_table(i,12)==1 && GUI.node_table(i,9)>GUI.node_table(i,8))
                    error1=1;
                    if(isempty(find(skiplist==8)))
                        display_string1=[display_string1,'(',num2str(i),',8)::'];
                    end
                end
            end
            if(GUI.node_table(i,10)>1)
                error1=1;
                if(isempty(find(skiplist==10)))
                    display_string1=[display_string1,'(',num2str(i),',10)::'];
                end
            end
            if(GUI.node_table(i,11)>1)
                error1=1;
                if(isempty(find(skiplist==11)))
                    display_string1=[display_string1,'(',num2str(i),',11)::'];
                end
            end
        else
            if(GUI.node_table(i,6)>1)
                error1=1;
                if(isempty(find(skiplist==6)))
                    display_string1=[display_string1,'(',num2str(i),',6)::'];
                end
            end
            if(GUI.node_table(i,7)>1)
                error1=1;
                if(isempty(find(skiplist==7)))
                    display_string1=[display_string1,'(',num2str(i),',7)::'];
                end
            end
        end
    end
    error2=0;
    display_string2='Path table Entries:';
    for i=1:GUI.px,
        skiplist=[];
        for j=1:GUI.py,
            if(GUI.path_table(i,j)<=0)
                error2=1;
                skiplist=[skiplist,j];
                display_string2=[display_string2,'(',num2str(i),',',num2str(j),')::'];
            end
        end
        if(GUI.path_table(i,5)<GUI.path_table(i,4))
            error2=1;
            if(isempty(find(skiplist==4)))
                display_string2=[display_string2,'(',num2str(i),',4)::'];
            end
        end
        if(GUI.path_table(i,7)<GUI.path_table(i,6))
            error2=1;
            if(isempty(find(skiplist==6)))
                display_string2=[display_string2,'(',num2str(i),',6)::'];
            end
        end
        if(GUI.path_table(i,2)>GUI.nx)
            error2=1;
            if(isempty(find(skiplist==2)))
                display_string2=[display_string2,'(',num2str(i),',2)::'];
            end
        end
        if(GUI.path_table(i,3)>GUI.nx)
            error2=1;
            if(isempty(find(skiplist==2)))
                display_string2=[display_string2,'(',num2str(i),',3)::'];
            end
        end
    end    
    if((error2>0)&&(error1>0))
        display_string=strcat(display_string1,display_string2);
        errordlg(display_string,'Invalid Entries Found!!!','modal');
        GUI.update_in_progress=0;
        return;
    else if(error1>0)
            errordlg(display_string1,'Invalid Entries Found!!!','modal');
            GUI.update_in_progress=0;
            return;
        else if(error2>0)
            errordlg(display_string2,'Invalid Entries Found!!!','modal');
            GUI.update_in_progress=0;
            return; 
            end
        end
    end
    %%%END of correctness checking%%%
    %%%Transmission of the updated tables to board%%%
    %the number of rows and columns in the node table is converted to string to
    %be sent to the board
    nx_string=num2str(GUI.nx);
    ny_string=num2str(GUI.ny);
    %commas seperate every number sent to the board
    transmit=strcat(nx_string,',',ny_string);
    for i=1:GUI.nx,
        for j=1:GUI.ny,
            transmit=strcat(transmit,',',num2str(GUI.node_table(i,j)));
        end
    end
    %'x' seperates the node table data from the path table data
    transmit=strcat(transmit,',','x,');
    %number of rows and columns of the path table converted to string to be
    %appended to the data sent to the board
    px_string=num2str(GUI.px);
    py_string=num2str(GUI.py);
    transmit=strcat(transmit,px_string,',',py_string);
    for i=1:GUI.px,
        for j=1:GUI.py,
            if((j==2)||(j==3))
                %*******IMPORTANT*******%
                %The table used for matlab considers the first node to be
                %number 1 but in C, first element of the array is indexed 0,
                %hence the path source and destination nodes should be reduced
                %by 1 to make sense in C
                transmit=strcat(transmit,',',num2str(GUI.path_table(i,j)-1));
            else
                transmit=strcat(transmit,',',num2str(GUI.path_table(i,j)));
            end
        end
    end
    %The character 'z' indicates end of transmission
    transmit=strcat(transmit,',z');
    delete(instrfindall);
    delete(timerfindall);
    GUI.udp_handle = udp(GUI.IP{1}, 4950, 'LocalPort', 4950);
    set(GUI.udp_handle,'DatagramTerminateMode','off');
    fopen(GUI.udp_handle);
    fprintf(GUI.udp_handle,'a');
    pause(1);
    fprintf(GUI.udp_handle,'u');
    pause(1);
    flushinput(GUI.udp_handle);
    fprintf(GUI.udp_handle,transmit);
    in=(fscanf(GUI.udp_handle));
    if(strcmp(in,[num2str(transmit) '\n']))
        msgbox('Update Complete!','Success');
    else
        %msgbox('Update Failed, please try again','Error','error');
    end
    fclose(GUI.udp_handle);
    clear GUI.udp_handle;
    %clear and initialize lookup tables
    GUI.node_activation_code_table=zeros(1,GUI.nx+1);
    GUI.node_status_code_table=ones(1,GUI.nx+1);
    GUI.node_status_code_table(1,1)=0;
    GUI.path_status_code_table=ones(1,GUI.px+1);
    GUI.path_status_code_table(1,1)=0;
    GUI.update_in_progress=0;
    response=1;
end

function response=config_check
global GUI
    response=0;
    if((size(GUI.node_table,1)<1)||(size(GUI.node_table,2)~=(GUI.heart_model*12+(1-GUI.heart_model)*7))||(size(GUI.path_table,1)<1)||(size(GUI.path_table,2)~=(GUI.heart_model*8+(1-GUI.heart_model)*7))...
            ||(GUI.nx<1)||(GUI.px<1)||(GUI.ny<1)||(GUI.py<1)||(size(GUI.node_table,1)~=GUI.nx)||(size(GUI.path_table,1)~=GUI.px))
        errordlg('Tables not loaded correctly','Check Tables','modal');
    else
        response=1;
    end
end
    
function save_model(~,~)
    global GUI
    %if(config_check~=1)
    %    return;
    %end
    [fname,path] = uiputfile('*.mat', 'Save VHM Model');
    dir=[path fname];
    node_table=get(GUI.node_table_handle,'Data');
    path_table=get(GUI.path_table_handle,'Data');
    node_pos(:,1)=get(GUI.node_pos,'XData');
    node_pos(:,2)=get(GUI.node_pos,'YData');
    trigger_table=get(GUI.trigger_table_handle,'Data');
    save(dir,'node_table','path_table','node_pos','trigger_table');
end

function button_press(hObject,~)
global GUI
persistent press_count start_point end_point source_node dest_node
    tolerance=10;
    minimum_dist=10;
    pt=round(get(hObject,'CurrentPoint'))
    if(GUI.add_path_mode==0)%mouse clicks results in adding a node
        press_count=0;
        GUI.nodes_position(end+1,:)=[pt(1,1) pt(1,2)];
        if(size(find((abs(GUI.nodes_position(:,1)-GUI.nodes_position(end,1))<minimum_dist)&(abs(GUI.nodes_position(:,2)-GUI.nodes_position(end,2))<minimum_dist)),1)==1)
            set(GUI.node_pos,'XData',GUI.nodes_position(:,1),'YData',GUI.nodes_position(:,2));
            set_node_configuration(pt(1,1:2),size(GUI.nodes_position,1));%setup dialog box to request node information
        else
            GUI.nodes_position(end,:)=[];
        end
    else %mouse clicks results in adding a path
        distancesToMouse = hypot(GUI.nodes_position(:,1) - pt(1,1), GUI.nodes_position(:,2) - pt(1,2));%find the distance between the mouse click and all other nodes using sqrt((x1-x2)^2 + (y1-y2)^2)
        [val, ind] = min(abs(distancesToMouse));%find the shortest distance
        if abs(pt(1,1) - GUI.nodes_position(ind,1)) < tolerance && abs(pt(1,2) - GUI.nodes_position(ind,2)) < tolerance%find out if the distance is within tolerance
            if(press_count==0)
                start_point=GUI.nodes_position(ind,:);
                set(GUI.selected_node_pos,'XData',start_point(1),'YData',start_point(2));
                source_node=ind;%mark this node as the source node for the path
            else
                end_point=GUI.nodes_position(ind,:);
                if(start_point~=end_point)
                    set(GUI.selected_node_pos,'XData',[],'YData',[]);
                    GUI.paths_handle(end+1)=line([start_point(1) end_point(1)],[start_point(2) end_point(2)],'LineWidth',5);
                    dest_node=ind;%mark this node as the destination node for the path
                    set_path_configuration(source_node,dest_node,end_point,size(GUI.paths_handle,1));%display dialog box for more details about the path
                    start_point=[];
                    end_point=[];
                    source_node=[];
                    dest_node=[];
                    press_count=-1;
                end
            end
            press_count=press_count+1;
        end 
    end  
end

function hinter(hObject,eventdata)
    global GUI
    enable=1;
    if(GUI.nx>0)% if any nodes present, display node number
        tolerance=10;
        sign=[-2,1];
        mousePoint=get(GUI.heart_axes_handle,'CurrentPoint');
        mouseX = mousePoint(1,1);
        mouseY = mousePoint(1,2);
        distancesToMouse = hypot(GUI.nodes_position(:,1) - mouseX, GUI.nodes_position(:,2) - mouseY);
        [val, ind] = min(abs(distancesToMouse));
        if abs(mouseX - GUI.nodes_position(ind,1)) < tolerance && abs(mouseY - GUI.nodes_position(ind,2)) < tolerance
            GUI.node_in_focus=ind;
            set(GUI.node_hint_text_handle, 'String', ['Node ' num2str(ind)]);
            set(GUI.node_hint_text_handle, 'Position', [GUI.nodes_position(ind,1) + sign((rand()>0.5)+1)*tolerance, GUI.nodes_position(ind,2) + sign((rand()>0.5)+1)*tolerance]);%rand for varying the position of the hint text to prevent hidden text
            enable=0;%node text displayed, don't display path hint
        else
            GUI.node_in_focus=0;
            set(GUI.node_hint_text_handle, 'String', '');
        end
        if(GUI.px>0)%if any paths present, display path number
            pathLengths=hypot(GUI.nodes_position(GUI.path_table(:,2),1)-GUI.nodes_position(GUI.path_table(:,3),1),GUI.nodes_position(GUI.path_table(:,2),2)-GUI.nodes_position(GUI.path_table(:,3),2));
            [val,ind]=min(abs(pathLengths-(hypot(GUI.nodes_position(GUI.path_table(:,2),1)-mouseX,GUI.nodes_position(GUI.path_table(:,2),2)-mouseY)+hypot(mouseX-GUI.nodes_position(GUI.path_table(:,3),1),mouseY-GUI.nodes_position(GUI.path_table(:,3),2)))));
            if(enable && val<1)%if node text not displayed, display path hint
                set(GUI.path_hint_text_handle,'String',['Path ' num2str(ind)]);
                set(GUI.path_hint_text_handle,'Position',[mouseX+5,mouseY+5]);
            else
                set(GUI.path_hint_text_handle,'String','');
            end
        end
    end
end

function add_path(hObject,~)
global GUI
    GUI.add_path_mode=mod((GUI.add_path_mode+1),2);
    if(GUI.add_path_mode==1)
        set(hObject,'ForegroundColor',[1 0.5 0]);
        set(hObject,'Checked','on');
    else
        set(GUI.selected_node_pos,'XData',[],'YData',[]);
        set(hObject,'ForegroundColor','k');
        set(hObject,'Checked','off');
    end
%     set(GUI.main_gui_handle,'KeyPressFcn',@get_key);
%     set(GUI.main_gui_handle,'
    
end

function set_node_configuration(position,node_count)
global current_node_config GUI
    set(GUI.heart_axes_handle,'ButtonDownFcn','');
    current_node_config.figure_handle=figure('Units', 'Pixels'...
    ,'Position', [position(1) position(2) 370*(1-GUI.heart_model)+700*GUI.heart_model 100]...
    ,'Resize','off'...
    ,'Name',strcat('Node ',num2str(node_count),' Settings')...
    ,'NumberTitle','Off','CloseRequestFcn',@remove_last_node,'MenuBar','none');
    uicontrol('Style','text','String','Node State','Position',[5,70,60,20]);
    current_node_config.node_number=uicontrol('Parent',current_node_config.figure_handle,'Style','text','String','1','Position',[5,50,60,20],'BackgroundColor','white');
    uicontrol('Style','text','String','Current TERP','Position',[70,70,70,20]);
    current_node_config.current_erp=uicontrol('Parent',current_node_config.figure_handle,'Style','edit','String','9999','Position',[70,50,70,20],'BackgroundColor','white');
    uicontrol('Style','text','String','Default TERP','Position',[145,70,70,20]);
    current_node_config.erp=uicontrol('Parent',current_node_config.figure_handle,'Style','edit','String','9999','Position',[145,50,70,20],'BackgroundColor','white');
    if(GUI.heart_model)
        uicontrol('Style','text','String','Current TRRP','Position',[220,70,70,20]);
        current_node_config.current_rrp=uicontrol('Parent',current_node_config.figure_handle,'Style','edit','String','9999','Position',[220,50,70,20],'BackgroundColor','white');
        uicontrol('Style','text','String','Default TRRP','Position',[295,70,70,20]);
        current_node_config.rrp=uicontrol('Parent',current_node_config.figure_handle,'Style','edit','String','9999','Position',[295,50,70,20],'BackgroundColor','white');
        uicontrol('Style','text','String','Current Trest','Position',[370,70,70,20]);
        current_node_config.current_rest=uicontrol('Parent',current_node_config.figure_handle,'Style','edit','String','9999','Position',[370,50,70,20],'BackgroundColor','white');
        uicontrol('Style','text','String','Default Trest','Position',[445,70,70,20]);
        current_node_config.rest=uicontrol('Parent',current_node_config.figure_handle,'Style','edit','String','9999','Position',[445,50,70,20],'BackgroundColor','white');
        uicontrol('Style','text','String','ERP_min','Position',[520,70,50,20]);
        current_node_config.erp_min=uicontrol('Parent',current_node_config.figure_handle,'Style','edit','String','9999','Position',[520,50,50,20],'BackgroundColor','white');
        uicontrol('Style','text','String','ERP_max','Position',[575,70,50,20]);
        current_node_config.erp_max=uicontrol('Parent',current_node_config.figure_handle,'Style','edit','String','9999','Position',[575,50,50,20],'BackgroundColor','white');
        uicontrol('Style','text','String','Node Type','Position',[630,70,70,20]);
        current_node_config.node_type=uicontrol('Parent',current_node_config.figure_handle,'Style','checkbox','String','AV Node','Position',[630,50,70,20],'BackgroundColor','white');
        uicontrol('Parent',current_node_config.figure_handle,'Style','pushbutton','Position',[265,10,80,30],'String','OK','Callback',@read_node_data);
        uicontrol('Parent',current_node_config.figure_handle,'Style','pushbutton','Position',[350,10,80,30],'String','Cancel','Callback',@remove_last_node);
    else
        uicontrol('Style','text','String','Current Trest','Position',[220,70,70,20]);
        current_node_config.current_rest=uicontrol('Parent',current_node_config.figure_handle,'Style','edit','String','9999','Position',[220,50,70,20],'BackgroundColor','white');
        uicontrol('Style','text','String','Default Trest','Position',[295,70,70,20]);
        current_node_config.rest=uicontrol('Parent',current_node_config.figure_handle,'Style','edit','String','9999','Position',[295,50,70,20],'BackgroundColor','white');
        uicontrol('Parent',current_node_config.figure_handle,'Style','pushbutton','Position',[105,10,80,30],'String','OK','Callback',@read_node_data);
        uicontrol('Parent',current_node_config.figure_handle,'Style','pushbutton','Position',[190,10,80,30],'String','Cancel','Callback',@remove_last_node);
    end
end

function read_node_data(~,~)
global current_node_config GUI
    if GUI.heart_model
        temp=[str2double(get(current_node_config.node_number,'String')) str2double(get(current_node_config.current_erp,'String')) str2double(get(current_node_config.erp,'String'))...
        str2double(get(current_node_config.current_rrp,'String')) str2double(get(current_node_config.rrp,'String')) str2double(get(current_node_config.current_rest,'String'))...
        str2double(get(current_node_config.rest,'String')) str2double(get(current_node_config.erp_min,'String')) str2double(get(current_node_config.erp_max,'String'))...
        0 0 get(current_node_config.node_type,'Value')];
    else
        temp=[str2double(get(current_node_config.node_number,'String')) str2double(get(current_node_config.current_erp,'String')) str2double(get(current_node_config.erp,'String'))...
        str2double(get(current_node_config.current_rest,'String')) str2double(get(current_node_config.rest,'String')) 0 0]; 
    end
    if(size(temp,2)~=(12*GUI.heart_model+(1-GUI.heart_model)*7))
        errordlg('Invalid Entries for node!!!','Check values','modal');
        return;
    end
    GUI.nx=GUI.nx+1;
    GUI.node_table(GUI.nx,:)=temp;
    set(GUI.node_table_handle,'Data',GUI.node_table);
    delete(current_node_config.figure_handle);
    GUI.trigger_table=[get(GUI.trigger_table_handle,'Data');zeros(1,max(1,size(get(GUI.trigger_table_handle,'Data'),2)))];
    set(GUI.trigger_table_handle,'Data',GUI.trigger_table);
    update_t_table_on_GUI(0,GUI.trigger_table,GUI.trigger_table);
    set(GUI.heart_axes_handle,'ButtonDownFcn',@button_press);
end

function remove_last_node(~,~)
global GUI current_node_config
    GUI.nodes_position(end,:)=[];
    try
        set(GUI.node_pos,'XData',GUI.nodes_position(:,1),'YData',GUI.nodes_position(:,2));
    catch
    end
    delete(current_node_config.figure_handle);
    set(GUI.heart_axes_handle,'ButtonDownFcn',@button_press);
end

function set_path_configuration(source_node,dest_node,position,path_count)
global current_path_config GUI
    set(GUI.heart_axes_handle,'ButtonDownFcn','');
    current_path_config.figure_handle=figure('Units', 'Pixels'...
    ,'Position', [position(1) position(2) 550*(1-GUI.heart_model)+620*GUI.heart_model 100]...
    ,'Resize','off'...
    ,'Name','Path Settings'...
    ,'NumberTitle','Off','CloseRequestFcn',@remove_last_path,'MenuBar','none');
    uicontrol('Style','text','String','Path Number','Position',[20,70,70,20]);  
    current_path_config.path_number=uicontrol('Parent',current_path_config.figure_handle,'Style','text','String',num2str(path_count),'Position',[20,50,70,20],'BackgroundColor','white');
    uicontrol('Style','text','String','Source Node','Position',[95,70,70,20]);  
    current_path_config.source_node=uicontrol('Parent',current_path_config.figure_handle,'Style','text','String',num2str(source_node),'Position',[95,50,70,20],'BackgroundColor','white');
    uicontrol('Style','text','String','Dest. Node','Position',[170,70,70,20]);  
    current_path_config.dest_node=uicontrol('Parent',current_path_config.figure_handle,'Style','text','String',num2str(dest_node),'Position',[170,50,70,20],'BackgroundColor','white');
    uicontrol('Style','text','String','Cur. Fwd Dur.','Position',[245,70,70,20]);  
    current_path_config.current_fc=uicontrol('Parent',current_path_config.figure_handle,'Style','edit','String','999','Position',[245,50,70,20],'BackgroundColor','white');
    uicontrol('Style','text','String','Def. Fwd Dur.','Position',[320,70,70,20]);  
    current_path_config.def_fc=uicontrol('Parent',current_path_config.figure_handle,'Style','edit','String','999','Position',[320,50,70,20],'BackgroundColor','white');
    uicontrol('Style','text','String','Cur. Bwd Dur.','Position',[395,70,70,20]);  
    current_path_config.current_bc=uicontrol('Parent',current_path_config.figure_handle,'Style','edit','String','999','Position',[395,50,70,20],'BackgroundColor','white');
    uicontrol('Style','text','String','Def. Bwd Dur.','Position',[470,70,70,20]);  
    current_path_config.def_bc=uicontrol('Parent',current_path_config.figure_handle,'Style','edit','String','999','Position',[470,50,70,20],'BackgroundColor','white');
    if(GUI.heart_model)
        uicontrol('Style','text','String','All Default','Position',[545,70,70,20]);  
        current_path_config.all_def=uicontrol('Parent',current_path_config.figure_handle,'Style','edit','String','999','Position',[545,50,70,20],'BackgroundColor','white');
        uicontrol('Parent',current_path_config.figure_handle,'Style','pushbutton','Position',[225,10,80,30],'String','OK','Callback',@read_path_data);
        uicontrol('Parent',current_path_config.figure_handle,'Style','pushbutton','Position',[310,10,80,30],'String','Cancel','Callback',@remove_last_path);
    else
        uicontrol('Parent',current_path_config.figure_handle,'Style','pushbutton','Position',[180,10,80,30],'String','OK','Callback',@read_path_data);
        uicontrol('Parent',current_path_config.figure_handle,'Style','pushbutton','Position',[265,10,80,30],'String','Cancel','Callback',@remove_last_path);
    end
end

function read_path_data(~,~)
global current_path_config GUI
    if(GUI.heart_model)
        temp=[str2double(get(current_path_config.path_number,'String')) str2double(get(current_path_config.source_node,'String')) str2double(get(current_path_config.dest_node,'String'))...
        str2double(get(current_path_config.current_fc,'String')) str2double(get(current_path_config.def_fc,'String')) str2double(get(current_path_config.current_bc,'String')) str2double(get(current_path_config.def_bc,'String'))...
        str2double(get(current_path_config.all_def,'String'))];
    else
        temp=[str2double(get(current_path_config.path_number,'String')) str2double(get(current_path_config.source_node,'String')) str2double(get(current_path_config.dest_node,'String'))...
        str2double(get(current_path_config.current_fc,'String')) str2double(get(current_path_config.def_fc,'String')) str2double(get(current_path_config.current_bc,'String')) str2double(get(current_path_config.def_bc,'String'))];
    end
    if(size(temp,2)~=(7+GUI.heart_model))
        errordlg('Invalid Entries for Path!!!','Check values','modal');
        return;
    end
    GUI.px=GUI.px+1;
    GUI.path_table(GUI.px,:)=temp;
    set(GUI.path_table_handle,'Data',GUI.path_table);
    delete(current_path_config.figure_handle);
    set(GUI.heart_axes_handle,'ButtonDownFcn',@button_press);
end

function remove_last_path(hObject,~)
global GUI current_path_config
    delete(GUI.paths_handle(end));
    GUI.paths_handle(end)=[];
    delete(current_path_config.figure_handle);
    set(GUI.heart_axes_handle,'ButtonDownFcn',@button_press);
end

function remove_node(~,~)
global GUI
    GUI.node_table(end,:)=[];
    %set(GUI.no_of_nodes_handle,'String',num2str(size(GUI.node_table,1)));
    set(GUI.node_table_handle,'Data',GUI.node_table);
    if(GUI.nx>0)
        GUI.nx=GUI.nx-1;
        temp_data=get(GUI.trigger_table_handle,'Data');
        set(GUI.trigger_table_handle,'Data',temp_data(1:end-1,:));
    end
    if(size(GUI.nodes_position,1)>0)
        GUI.nodes_position(end,:)=[];
    end
    set(GUI.node_pos,'XData',GUI.nodes_position(:,1),'YData',GUI.nodes_position(:,2));
    %update_tooltip;
end

function remove_path(~,~)
global GUI
    GUI.path_table(end,:)=[];
    %set(GUI.no_of_paths_handle,'String',num2str(size(GUI.path_table,1)));
    set(GUI.path_table_handle,'Data',GUI.path_table);
    if(GUI.px>0)
        GUI.px=GUI.px-1;
    end
    try
        delete(GUI.paths_handle(end));
        GUI.paths_handle(end)=[];
    catch
    end
end

function close_gui(hObject,~)
global GUI
    try
        fclose(GUI.udp_handle);
        delete(hObject);
        clear all;
        close all;
    catch
    end
end