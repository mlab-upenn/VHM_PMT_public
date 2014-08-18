%VHM_GUI()-->hardware heart model
%VHM_GUI(<mat_file_path>)-->heart model as software

function err_code=VHM_GUI(varargin)
    global UT_GUI time_stamp
    if(nargin==2)
       update_GUI(varargin{1},varargin{2});
    else
        err_code=0;
        UT_GUI.udp_handle=[]; 
        assignin('base','u',UT_GUI.udp_handle);
        UT_GUI.ok_to_display=0;
        UT_GUI.logging_in_progress=0;
        UT_GUI.update_in_progress=0;
        UT_GUI.screen_size=get(0,'ScreenSize');
        UT_GUI.main_gui_handle=figure('Units', 'normalized'...
            ,'Position', [0 0 1 1]...
            ,'Resize','on'...
            ,'Name','Complex Model GUI'...
            ,'NumberTitle','Off');   
        set(UT_GUI.main_gui_handle,'MenuBar','none');
        set(UT_GUI.main_gui_handle,'ToolBar','none');
        UT_GUI.toolbar_handle=uitoolbar(UT_GUI.main_gui_handle);
        UT_GUI.time_display=0;
        UT_GUI.MAX_PACES=20;
        UT_GUI.mode=0;
        UT_GUI.formal_mode=nargin;
        UT_GUI.nx=0;
        UT_GUI.px=0;
        UT_GUI.node_table=[];
        UT_GUI.path_table=[];
        UT_GUI.trigger_table=[];
        UT_GUI.paths_handle=[];
        UT_GUI.add_path_mode=0;
        UT_GUI.pause=0;
        UT_GUI.heart_axes_handle=axes('Units','normalized'...
            ,'Position',[0.005,0.195,0.47,0.8]...
            ,'Xlim',[0 530]...
            ,'Ylim',[0 530]...
            ,'XTick',[]...
            ,'YTick',[]...
            ,'ZTick',[]...
            ,'NextPlot','add');    
        UT_GUI.panel2_handle=uipanel('Parent',UT_GUI.main_gui_handle...
            ,'Title',''...
            ,'Units','normalized'...
            ,'Position',[0.005 0.005 0.47 0.185]...
            ,'BackgroundColor',[0.7 0.9 0.8]...
            ,'BorderType','etchedout'...
            ,'BorderWidth',1,...
            'ShadowColor',[0 0 0]);
        UT_GUI.play_or_stop_button=uicontrol('Parent',UT_GUI.panel2_handle...
            ,'String','Play'...
            ,'Style','pushbutton'...
            ,'Units','normalized'...
            ,'Position',[0.005 0.8 0.04 0.15],...
            'Callback',@run_model);
        UT_GUI.position_slider=uicontrol('Parent',UT_GUI.panel2_handle,'Style','slider'...
            ,'Min',0,...
            'Max',10,...
            'Value',0,...
            'Units','normalized'...
            ,'Position',[0.05 0.8 0.705 0.15]...
            ,'SliderStep',[0.0001 0.001]);
        UT_GUI.max_time_display=uicontrol('Parent',UT_GUI.panel2_handle,'Style','text','FontSize',14,'String','Inf'...
            ,'Units','normalized'...
            ,'Position',[0.76 0.8 0.055 0.15]);
        UT_GUI.speed_list=uicontrol('Parent',UT_GUI.panel2_handle,'String',{'1x','0.5x','0.25x','0.1x'},'Style',...
            'popupmenu','Units','normalized'...
            ,'Position',[0.82 0.8 0.08 0.15]);
        UT_GUI.pace_button=uicontrol('Parent',UT_GUI.panel2_handle...
            ,'String','Pace Now'...
            ,'Style','pushbutton'...
            ,'Units','normalized'...
            ,'Position',[0.905 0.8 0.09 0.15],...
            'Callback',@pace_nodes);
        UT_GUI.show_signals_handle=uicontrol('Style','pushbutton'...
            ,'String','Show Signals'...
            ,'Units','normalized'...
            ,'Position',[0.5 0.97 0.07 0.025]...
            ,'BackgroundColor',[0.7 0.9 0.8]...
            ,'Callback',@display_signals_or_tables);   
        UT_GUI.panel4_handle=uipanel('Parent',UT_GUI.main_gui_handle...
            ,'Title',''...
            ,'Units','normalized'...
            ,'Position',[0.48 0.005 0.015 .965]...
            ,'BackgroundColor',[0.7 0.9 0.8]...
            ,'BorderType','etchedout'...
            ,'BorderWidth',1,...
            'ShadowColor',[0 0 0]); 
        UT_GUI.panel3_handle=uipanel('Parent',UT_GUI.main_gui_handle...
            ,'Title',''...
            ,'Units','normalized'...
            ,'Position',[0.495 0.005 0.5 .965]...
            ,'BackgroundColor',[0.7 0.9 0.8]...
            ,'BorderType','etchedout'...
            ,'BorderWidth',1,...
            'ShadowColor',[0 0 0]); 
        UT_GUI.node_table_handle = uitable('Parent',UT_GUI.panel3_handle,'Units','normalized'...
            ,'Position',[0.005 0.5025 0.4925 0.4925]...
            ,'Data',UT_GUI.node_table...
            ,'RowName',[]...
            ,'ColumnFormat',{'numeric','numeric','numeric','numeric','numeric','numeric','numeric','numeric','numeric','numeric','numeric','numeric'}...
            ,'ColumnWidth','auto'...
            ,'ColumnEditable',[true true true true true true true true true true true true]...
            ,'ColumnName',{'Node State','TERP_current','TERP_default','TRRP_current','TRRP_default','Trest_current','Trest_default','ERP_min','ERP_max','Node activation status','Path activation status','AV Node'}...
            ,'TooltipString','Node Table');%,'CellEditCallback',@update_node_table);
        UT_GUI.path_table_handle = uitable('Parent',UT_GUI.panel3_handle,'Units','normalized'...
            ,'Position',[0.5025 0.5025 0.4925 0.4925]...
            ,'Data',UT_GUI.path_table...
            ,'RowName',[]...
            ,'ColumnFormat',{'numeric','numeric','numeric','numeric','numeric','numeric','numeric','numeric'}...
            ,'ColumnWidth','auto'...
            ,'ColumnEditable',[true true true true true true true true true]...
            ,'ColumnName',{'Path State','Source Node','Destination Node','current FC','Default FC','Current BC','Default BC','Reset Values'}...
            ,'TooltipString','Path Table');
        UT_GUI.trigger_table_handle = uitable('Parent',UT_GUI.panel3_handle,'Units','normalized'...
            ,'Position',[0.005 0.005 0.99 0.4925]...
            ,'Data',UT_GUI.trigger_table...
            ,'ColumnFormat',{'numeric'}...
            ,'ColumnWidth','auto'...
            ,'ColumnEditable',true...
            ,'ColumnName',{'Trigger Count'}...
            ,'CellEditCallback',@update_meaning...
            ,'TooltipString','Pacing setup table');
        UT_GUI.im=imread('H:\VHM\HOC_freedom\HOC_freedom\new_codes\EP.jpg');
        UT_GUI.im=imagesc(UT_GUI.im);
        UT_GUI.nodes_position=[];
        UT_GUI.node_pos=scatter([],[],'LineWidth',5,'Marker','o','MarkerEdgeColor','r','MarkerFaceColor','r','HitTest','off');
        if(nargin)
            time_stamp=1;
            trigger_table=zeros(UT_GUI.nx,1);
            try
                load(varargin{1});
            catch
                close all;
                disp('.mat file not present at the path specified');
                err_code=1;
                return;
            end
            UT_GUI.node_table=node_table;
            UT_GUI.path_table=path_table;
            try
                create_t_table_on_GUI(trigger_table,UT_GUI.trigger_table_handle);
            catch
            end
            UT_GUI.nx=size(UT_GUI.node_table,1);
            UT_GUI.px=size(UT_GUI.path_table,1);
            set(UT_GUI.node_table_handle,'Data',UT_GUI.node_table);
            set(UT_GUI.path_table_handle,'Data',UT_GUI.path_table);
            UT_GUI.nodes_position=node_pos;
            set(UT_GUI.node_pos,'XData',node_pos(:,1),'YData',node_pos(:,2));
            try
                delete(UT_GUI.paths_handle);
            catch
            end
            UT_GUI.paths_handle=[];
            for i=1:UT_GUI.px
                UT_GUI.paths_handle(end+1)=line([node_pos(path_table(i,2),1) node_pos(path_table(i,3),1)],[node_pos(path_table(i,2),2) node_pos(path_table(i,3),2)],'LineWidth',5);
            end
            UT_GUI.model_mode_handle=uipushtool(UT_GUI.toolbar_handle,'CData',customize_image('H:\VHM\HOC_freedom\HOC_freedom\icons\software-icon.png'),'TooltipString','Software Heart Model');
        else
            UT_GUI.new_file_handle=uipushtool(UT_GUI.toolbar_handle,'CData',customize_image('H:\VHM\HOC_freedom\HOC_freedom\icons\new.png'),'TooltipString','New Model','ClickedCallback',@new_model);
            UT_GUI.load_file_handle=uipushtool(UT_GUI.toolbar_handle,'CData',customize_image('H:\VHM\HOC_freedom\HOC_freedom\icons\open-file.png'),'TooltipString','Load Model','ClickedCallback',@load_model);
            UT_GUI.save_file_handle=uipushtool(UT_GUI.toolbar_handle,'CData',customize_image('H:\VHM\HOC_freedom\HOC_freedom\icons\save.png'),'TooltipString','Save Model','ClickedCallback',@save_model);
            UT_GUI.add_path_handle=uipushtool(UT_GUI.toolbar_handle,'CData',customize_image('H:\VHM\HOC_freedom\HOC_freedom\icons\add_path.png'),'TooltipString','Add path','ClickedCallback',@add_path);
            UT_GUI.delete_node_handle=uipushtool(UT_GUI.toolbar_handle,'CData',customize_image('H:\VHM\HOC_freedom\HOC_freedom\icons\delete_node.png'),'TooltipString','Remove Node','ClickedCallback',@remove_node);
            UT_GUI.delete_path_handle=uipushtool(UT_GUI.toolbar_handle,'CData',customize_image('H:\VHM\HOC_freedom\HOC_freedom\icons\delete_path.png'),'TooltipString','Remove Path','ClickedCallback',@remove_path);
            UT_GUI.model_mode_handle=uipushtool(UT_GUI.toolbar_handle,'CData',customize_image('H:\VHM\HOC_freedom\HOC_freedom\icons\heart_model.png'),'TooltipString','Hardware Heart Mode');
            UT_GUI.load_trigger_table_handle=uipushtool(UT_GUI.toolbar_handle,'CData',customize_image('H:\VHM\HOC_freedom\HOC_freedom\icons\upload.png'),'TooltipString','Upload Trigger Table','ClickedCallback',@upload_trigger_table);
            UT_GUI.pace_panel_handle=uipushtool(UT_GUI.toolbar_handle,'CData',customize_image('H:\VHM\HOC_freedom\HOC_freedom\icons\settings.png'),'TooltipString','Pace Settings','ClickedCallback',@show_pace_panel);
        end
        UT_GUI.play_mode_handle=uipushtool(UT_GUI.toolbar_handle,'CData',customize_image('H:\VHM\HOC_freedom\HOC_freedom\icons\clock.png'),'TooltipString','Current Mode','ClickedCallback',@switch_modes,'Tag','current');
        UT_GUI.pacemaker_mode_handle=uipushtool(UT_GUI.toolbar_handle,'CData',customize_image('H:\VHM\HOC_freedom\HOC_freedom\icons\no_pacemaker.png'),'TooltipString','Pacemaker Off','ClickedCallback',@switch_modes,'Tag','poff');
        UT_GUI.view_history_handle=uipushtool(UT_GUI.toolbar_handle,'CData',customize_image('H:\VHM\HOC_freedom\HOC_freedom\icons\log.png'),'TooltipString','View Heart Log','ClickedCallback',@display_log);
        UT_GUI.selected_node_pos=scatter([],[],'LineWidth',5,'Marker','o','MarkerEdgeColor','g','MarkerFaceColor','g');
        UT_GUI.activated_node_pos=scatter([],[],'LineWidth',5,'Marker','o','MarkerEdgeColor','y','MarkerFaceColor','y','HitTest','off');
        UT_GUI.excited_node_pos=scatter([],[],'LineWidth',5,'Marker','o','MarkerEdgeColor','g','MarkerFaceColor','g','HitTest','off');
        UT_GUI.relaxed_node_pos=scatter([],[],'LineWidth',5,'Marker','o','MarkerEdgeColor','r','MarkerFaceColor','r','HitTest','off');
        UT_GUI.activated_nodes_position=zeros(1,2);
        UT_GUI.excited_nodes_position=zeros(1,2);
        UT_GUI.relaxed_nodes_position=zeros(1,2);
        set(UT_GUI.im,'HitTest','off');
        set(UT_GUI.heart_axes_handle,'ButtonDownFcn',@button_press);
        set(UT_GUI.main_gui_handle,'WindowButtonMotionFcn', @hinter);
        UT_GUI.hint_text_handle = text('Color', 'white', 'VerticalAlign', 'Bottom');
    end
end

function update_node_table(hObject,eventdata)
global UT_GUI
    if(eventdata.Indices(2)==12)
        UT_GUI.node_table(eventdata.Indices(1),eventdata.Indices(2))=double(eventdata.EditData);
        
    else
        UT_GUI.node_table(eventdata.Indices)=eventdata.NewData;
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
                x(i,j,:)=[255 255 255];
            end
        end
    end
    
end

function change_position(~,~)
    global UT_GUI
    new_time_stamp=get(UT_GUI.position_slider,'Value');
    UT_GUI.start_point=max(find(UT_GUI.time_stamp_history<=new_time_stamp));
end

function switch_modes(hObject,~)
    global UT_GUI
    switch(get(hObject,'Tag'))
    case 'current'
        if(~UT_GUI.formal_mode)
            gather_data(0);
        end
        UT_GUI.start_point=1;
        set(UT_GUI.position_slider,'Callback',@change_position);
        set(UT_GUI.position_slider,'Min',UT_GUI.time_stamp_history(1));
        set(UT_GUI.position_slider,'Max',UT_GUI.time_stamp_history(end));
        set(UT_GUI.position_slider,'Value',UT_GUI.time_stamp_history(1));
        set(UT_GUI.max_time_display,'String',strcat(num2str(double(uint64((UT_GUI.time_stamp_history(end)-UT_GUI.time_stamp_history(1))/10))/100),'s'),'FontSize',8);
        set(hObject,'CData',customize_image('H:\VHM\HOC_freedom\HOC_freedom\icons\history.png'),'TooltipString','Playback Mode','Tag','playback');
        UT_GUI.mode=1;
    case 'playback'
        set(UT_GUI.position_slider,'Callback','');
        set(UT_GUI.position_slider,'Min',0);
        set(UT_GUI.position_slider,'Value',0);
        set(UT_GUI.position_slider,'Max',10);
        set(UT_GUI.max_time_display,'String','Inf','FontSize',14);
        set(hObject,'CData',customize_image('H:\VHM\HOC_freedom\HOC_freedom\icons\clock.png'),'TooltipString','Current Mode','Tag','current');
        UT_GUI.mode=0;
    case 'pon'
        %under construction
    case 'poff'
        %under construction
    end
end

function new_model(~,~)
global UT_GUI
    UT_GUI.ok_to_display=0;
    UT_GUI.logging_in_progress=0;
    UT_GUI.update_in_progress=0;
    UT_GUI.nx=0;
    UT_GUI.px=0;
    UT_GUI.node_table=[];
    UT_GUI.path_table=[];
    UT_GUI.trigger_table=[];
    UT_GUI.nodes_position=[];
    UT_GUI.activated_nodes_position=zeros(1,2);
    UT_GUI.excited_nodes_position=zeros(1,2);
    UT_GUI.relaxed_nodes_position=zeros(1,2);
    delete(UT_GUI.paths_handle);
    UT_GUI.paths_handle=[];
    UT_GUI.add_path_mode=0;
    UT_GUI.pause=0;
    UT_GUI.time_display=0;
    set(UT_GUI.node_pos,'XData',[],'YData',[]);
    set(UT_GUI.node_table_handle,'Data',UT_GUI.node_table);
    set(UT_GUI.path_table_handle,'Data',UT_GUI.path_table);
    set(UT_GUI.trigger_table_handle,'Data',UT_GUI.trigger_table);
    set(UT_GUI.trigger_table_handle,'ColumnFormat',{'numeric'},'ColumnWidth','auto','ColumnEditable',true,'ColumnName',{'Trigger Count'});    
end

function DatagramReceivedCallback(~,~)
global UT_GUI
    [UT_GUI.current_nodes_states(end+1,:),UT_GUI.current_node_activation_status(end+1,:),UT_GUI.current_path_states(end+1,:),UT_GUI.current_time(end+1,:)]=data_decoder2(fscanf(UT_GUI.udp_handle),UT_GUI.nx,UT_GUI.px);
end

function plot_signals(option,current_node_activation_status,time_now,no_of_nodes)
    persistent prev_value plot_handle text_handle time_frame offset_matrix working_handle_index handle_list
    global UT_GUI change changed_node signals_list
    if(option==0)
        time_frame=100;
        working_handle_index=9999*ones(1,no_of_nodes);
        color_string='ymcrgb';
        UT_GUI.plot_axis_handle=axes('Parent',UT_GUI.panel3_handle,'Units','normalized','Position',[0 0 1 1]);
        set(gca,'Color','k');
        handle_list=[];
        handle_list(1,1)=time_now;
        handle_list(2,1)=text('Parent',UT_GUI.plot_axis_handle,'Units','data','Position',[time_frame,0],'String',[],'Color','k');
        handle_list(3,1)=1;
        handle_list(4,1)=0;
        handle_list(5,1)=1;
        offset_matrix=zeros(1,no_of_nodes);
        prev_value=[];
        plot_handle=[];
        text_handle=[];
        hold on;%allows adding plots onto the same axes
        for i=1:no_of_nodes
            offset_matrix(i)=1.5*(no_of_nodes-i);
            prev_value(:,i)=offset_matrix(i)*ones(time_frame,1);
            plot_handle(i)=plot(UT_GUI.plot_axis_handle,prev_value(:,i));
            colorcode=color_string(mod(i,6)+1);
            set(plot_handle(i),'Color',colorcode);
            temp_string=strcat('Node ',num2str(i));
            text_handle(i)=text('Parent',UT_GUI.plot_axis_handle,'Units','data','Position',[0,1.5*(no_of_nodes-i)+0.75],'String',temp_string,'Color','w');
        end
        set(UT_GUI.plot_axis_handle,'XTick',[],'YTick',[]);
        set(UT_GUI.plot_axis_handle,'XTickLabel',[],'YTickLabel',[]);
        set(UT_GUI.plot_axis_handle,'box','off');
        ylim([0 1.5*no_of_nodes]);
        xlim([0 time_frame]);
        hold off;%stop addition
    end
    if(change~=0)
        %remove offset from the signals for easier computation
        prev_value=prev_value-repmat(offset_matrix,100,1);
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
            %update the position of the timings with the new location
            for i=1:no_of_nodes
                set(text_handle(i),'Position',[0,offset_matrix(i)+0.75]);
            end
            %reduce the number of nodes in the graph, resize the remaining
            %plots
            %make sure to maintain the labels of the y axis
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
                prev_value(:,end+1)=zeros(time_frame,1);
                plot_handle(end+1)=plot(UT_GUI.plot_axis_handle,prev_value(:,end));
                colorcode=color_string(mod(changed_node,6)+1);
                set(plot_handle(end),'Color',colorcode);
                temp_string=strcat('Node ',num2str(changed_node));
                text_handle(end+1)=text('Parent',UT_GUI.plot_axis_handle,'Units','data','Position',[0,offset_matrix(end)+0.75],'String',temp_string,'Color','w');
                working_handle_index(end+1)=9999;
                for i=1:no_of_nodes
                    set(text_handle(i),'Position',[0,offset_matrix(i)+0.75]);
                end
            else if(changed_node==min(signals_list)) % new plot is the first plot
                    prev_value=[zeros(time_frame,1) prev_value];
                    plot_handle=[plot(UT_GUI.plot_axis_handle,prev_value(:,1)) plot_handle];
                    colorcode=color_string(mod(changed_node,6)+1);
                    set(plot_handle(1),'Color',colorcode);
                    temp_string=strcat('Node ',num2str(changed_node));
                    text_handle=[text('Parent',UT_GUI.plot_axis_handle,'Units','data','Position',[0,offset_matrix(1)+0.75],'String',temp_string,'Color','w') text_handle];
                    working_handle_index=[9999 working_handle_index];
                    for i=1:no_of_nodes
                        set(text_handle(i),'Position',[0,offset_matrix(i)+0.75]);
                    end
                else %new plot has to be inserted in between plots
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
                                temp_prev_value(:,i)=zeros(time_frame,1);
                                temp_plot_handle(i)=plot(UT_GUI.plot_axis_handle,temp_prev_value(:,i));
                                colorcode=color_string(mod(changed_node,6)+1);
                                set(temp_plot_handle(i),'Color',colorcode);
                                temp_string=strcat('Node ',num2str(changed_node));
                                temp_text_handle(i)=text('Parent',UT_GUI.plot_axis_handle,'Units','data','Position',[0,offset_matrix(i)+0.75],'String',temp_string,'Color','w');
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
        prev_value=prev_value+repmat(offset_matrix,100,1);
        ylim([0 1.5*no_of_nodes]);
        change=0;
    end
    prev_value(1,:)=[];
    prev_value(end+1,:)=current_node_activation_status+offset_matrix;
    handle_list(3,:)=handle_list(3,:)-1;
    handle_list(5,:)=handle_list(5,:)-1;
    for i=1:no_of_nodes,
        if((current_node_activation_status(i)==1)&&(offset_matrix(i)==prev_value(end-1,i)))
            temp_array(1)=time_now;%start time
            temp_array(3)=time_frame;%current_position
            temp_array(4)=1.5*(no_of_nodes-i)+1;%y axis position
            temp_array(5)=time_frame;%start position on plot
            temp_array(2)=text('Parent',UT_GUI.plot_axis_handle,'Units','data','Position',[time_frame,temp_array(4)],'String',[],'HitTest','off','Color','w');
            handle_list(:,end+1)=temp_array;
            almost_finished_handle=working_handle_index(i);
            working_handle_index(i)=size(handle_list,2);
            if(almost_finished_handle<=size(handle_list,2))
                handle_list(5,almost_finished_handle)=handle_list(3,almost_finished_handle);
                handle_list(3,almost_finished_handle)=(time_frame+handle_list(3,almost_finished_handle))/2-1;
                set(handle_list(2,almost_finished_handle),'Position',[handle_list(3,almost_finished_handle),handle_list(4,almost_finished_handle)],'String',num2str(time_now-handle_list(1,almost_finished_handle)));
            end
        end
        set(plot_handle(i),'YData',prev_value(:,i));
    end
    hit_list=find(handle_list(5,:)<=1);
    delete(handle_list(2,hit_list));
    handle_list(:,hit_list)=[];
    for i=1:no_of_nodes,
        working_handle_index(i)=working_handle_index(i)-sum(working_handle_index(i)>hit_list);
    end
    for i=1:size(handle_list,2)
        set(handle_list(2,i),'Position',[handle_list(3,i),handle_list(4,i)]);
    end
    pause(0.000001);
end

function pace_nodes(~,~)
    global UT_GUI
    fprintf(UT_GUI.udp_handle,'pppp');
end

function emergency_pacer(~,~)
    global UT_GUI
    disp(UT_GUI.node_in_focus)
    if(UT_GUI.node_in_focus)        
        fprintf(UT_GUI.udp_handle,['e' num2str(UT_GUI.node_in_focus-1)]); 
        set(UT_GUI.hint_text_handle,'String','Paced');
    end
end

function run_model(hObject,~)
    global UT_GUI
    persistent button_states
    if(config_check~=1)
        return;
    end
    if(strcmp(get(hObject,'String'),'Play'))
        response=1;
        if(~UT_GUI.mode&&~UT_GUI.formal_mode)
            response=update_tables;
        end
        if(response==1)
             set(hObject,'String','Stop');
%             button_states.view_history=get(UT_GUI.view_history_handle,'Enable');
%             button_states.new_option=get(UT_GUI.new_file_handle,'Enable');
%             button_states.load_option=get(UT_GUI.load_file_handle,'Enable');
%             button_states.save_option=get(UT_GUI.save_file_handle,'Enable');
%             button_states.add_path_option=get(UT_GUI.add_path_handle,'Enable');
%             button_states.upload_trigger_table=get(UT_GUI.load_trigger_table_handle,'Enable');
%             set(UT_GUI.view_history_handle,'Enable','off');
%             set(UT_GUI.new_file_handle,'Enable','off');
%             set(UT_GUI.load_file_handle,'Enable','off');
%             set(UT_GUI.save_file_handle,'Enable','off');
%             set(UT_GUI.load_trigger_table_handle,'Enable','off');
%             set(UT_GUI.node_table_handle,'Enable','off');
%             set(UT_GUI.path_table_handle,'Enable','off');
%             set(UT_GUI.trigger_table_handle,'Enable','off');
            set(UT_GUI.pace_button,'Enable','on');
            set(UT_GUI.activated_node_pos,'XData',[],'YData',[]);
            set(UT_GUI.relaxed_node_pos,'XData',[],'YData',[]);
            set(UT_GUI.excited_node_pos,'XData',[],'YData',[]);
            set(UT_GUI.activated_node_pos,'Visible','on');
            set(UT_GUI.relaxed_node_pos,'Visible','on');
            set(UT_GUI.excited_node_pos,'Visible','on');
            set(UT_GUI.heart_axes_handle,'ButtonDownFcn',@emergency_pacer);
            %set up of the buffers
            if(UT_GUI.mode)
                if(UT_GUI.start_point==size(UT_GUI.time_stamp_history,1))
                    UT_GUI.start_point=1;
                end
                UT_GUI.current_nodes_states=UT_GUI.nodes_states_history(UT_GUI.start_point:end,:);
                UT_GUI.current_node_activation_status=UT_GUI.node_activation_status_history(UT_GUI.start_point:end,:);
                UT_GUI.current_path_states=UT_GUI.path_states_history(UT_GUI.start_point:end,:);
                UT_GUI.current_time=UT_GUI.time_stamp_history(UT_GUI.start_point:end,:);
                setup_display_routine(0.5,99999999,@plot_refresher);
                start(UT_GUI.periodic_function_handle);
            else
                if(~UT_GUI.formal_mode)
                    UT_GUI.current_nodes_states=ones(1,UT_GUI.nx);
                    UT_GUI.current_node_activation_status=zeros(1,UT_GUI.nx);
                    UT_GUI.current_path_states=ones(1,UT_GUI.px);
                    UT_GUI.current_time=0;
                    setup_display_routine(0,99999999,@plot_refresher);%very large number of executions for approximation to infinite executions
                    UT_GUI.udp_handle = udp('192.168.90.90', 4950, 'LocalPort', 4950);
                    set(UT_GUI.udp_handle,'DatagramTerminateMode','on');
                    set(UT_GUI.udp_handle, 'ReadAsyncMode', 'continuous');
                    UT_GUI.udp_handle.DatagramReceivedFcn=@DatagramReceivedCallback;
                    fopen(UT_GUI.udp_handle);
                    fprintf(UT_GUI.udp_handle,'x');
                    start(UT_GUI.periodic_function_handle);
                end
            end
            
        else
            errordlg('Could not run model','error','modal');
            return;
        end
    else
        if(~UT_GUI.mode&&~UT_GUI.formal_mode)
            UT_GUI.udp_handle.DatagramReceivedFcn='';
            flushinput(UT_GUI.udp_handle);
            fclose(UT_GUI.udp_handle);
            clear UT_GUI.udp_handle;
        end
        if(~UT_GUI.formal_mode)
            stop_display_routine;
        end
        set(UT_GUI.activated_node_pos,'Visible','off');
        set(UT_GUI.relaxed_node_pos,'Visible','off');
        set(UT_GUI.excited_node_pos,'Visible','off');
%         set(UT_GUI.view_history_handle,'Enable',button_states.view_history);
%         set(UT_GUI.new_file_handle,'Enable',button_states.new_option);
%         set(UT_GUI.load_file_handle,'Enable',button_states.load_option);
%         set(UT_GUI.save_file_handle,'Enable',button_states.save_option);
%         set(UT_GUI.edit_menu,'Enable',button_states.edit_menu);
%         set(UT_GUI.play_mode,'Enable',button_states.mode_menu);
%         set(UT_GUI.load_trigger_table_handle,'Enable',button_states.upload_trigger_table);
%         set(UT_GUI.pause_button_handle,'Enable','off');
        UT_GUI.pause=0;
        UT_GUI.ok_to_display=0;
        try
            delete(UT_GUI.plot_axis_handle);
            delete(UT_GUI.signals_selection_button_handle);
        catch
        end
        set(UT_GUI.node_table_handle,'Visible','on');
        set(UT_GUI.path_table_handle,'Visible','on');
        set(UT_GUI.trigger_table_handle,'Visible','on');   
        set(UT_GUI.show_signals_handle,'String','Show Signals');
%         set(UT_GUI.pace_button,'Enable','off');
        set(UT_GUI.heart_axes_handle,'ButtonDownFcn',@button_press);
        %display_signals_or_tables(UT_GUI.show_signals_handle,0);
        set(hObject,'String','Play');
    end
end

function setup_display_routine(start_delay,no_of_executions,function_name)
    global UT_GUI
    UT_GUI.periodic_function_handle=timer('StartDelay',start_delay,'Period',0.001,'TasksToExecute',no_of_executions,'ExecutionMode','fixedDelay','BusyMode','drop');%Period should be 0.001
    UT_GUI.periodic_function_handle.TimerFcn=function_name;
end

function stop_display_routine
    global UT_GUI
    stop(UT_GUI.periodic_function_handle);
    UT_GUI.current_nodes_states=[];
    UT_GUI.current_node_activation_status=[];
    UT_GUI.current_path_states=[];
    UT_GUI.current_time=[];
    delete(UT_GUI.periodic_function_handle);
end

function plot_refresher(varargin)
    global UT_GUI change signals_list no_of_nodes
    persistent option temp_nodes_states temp_node_activation_status temp_path_states temp_current_time
    if(~isempty(UT_GUI.current_nodes_states))
        temp_nodes_states=UT_GUI.current_nodes_states(1,:);
        temp_node_activation_status=UT_GUI.current_node_activation_status(1,:);
        temp_path_states=UT_GUI.current_path_states(1,:);
        temp_current_time=UT_GUI.current_time(1,:);
        UT_GUI.current_nodes_states(1,:)=[];
        UT_GUI.current_node_activation_status(1,:)=[];
        UT_GUI.current_path_states(1,:)=[];
        UT_GUI.current_time(1,:)=[];
    end 
    if(UT_GUI.pause==0)
        if(UT_GUI.ok_to_display==1)
            if(change~=0)
                no_of_nodes=size(signals_list,2);
            end
            plot_signals(option,temp_node_activation_status(signals_list),temp_current_time,no_of_nodes);
            option=mod(option,2)+1;
        else 
            pause(0.000001);
            option=0;
        end
        colorcodes='bgrcw';
        UT_GUI.relaxed_nodes_position=UT_GUI.nodes_position(temp_nodes_states==1,:);
        UT_GUI.excited_nodes_position=UT_GUI.nodes_position(temp_nodes_states==2,:);
        UT_GUI.activated_nodes_position=UT_GUI.nodes_position(temp_node_activation_status==1,:);
        set(UT_GUI.relaxed_node_pos,'XData',UT_GUI.relaxed_nodes_position(:,1),'YData',UT_GUI.relaxed_nodes_position(:,2));
        set(UT_GUI.excited_node_pos,'XData',UT_GUI.excited_nodes_position(:,1),'YData',UT_GUI.excited_nodes_position(:,2));
        set(UT_GUI.activated_node_pos,'XData',UT_GUI.activated_nodes_position(:,1),'YData',UT_GUI.activated_nodes_position(:,2));
        for i=1:UT_GUI.px
            set(UT_GUI.paths_handle(i),'Color',colorcodes(temp_path_states(i)));
        end
    end
    if(UT_GUI.mode)
        if((temp_current_time>=UT_GUI.time_stamp_history(end))||(UT_GUI.time_stamp_history(1)>=UT_GUI.time_stamp_history(end)))
            %disp('ending routine');
            run_model(UT_GUI.play_or_stop_button,0);
        end
        set(UT_GUI.position_slider,'Value',temp_current_time);
        UT_GUI.start_point=find(temp_current_time==UT_GUI.time_stamp_history);
    end
end

function update_GUI(node_table,path_table)
    global time_stamp UT_GUI
    persistent prev_nodes_states prev_node_activation_status prev_path_states
    if(iscell(node_table)==iscell(path_table))
        if(iscell(node_table))
            current_nodes_states=cell2mat(node_table(:,1))';
            current_node_activation_status=cell2mat(node_table(:,6))';
            current_path_states=cell2mat(path_table(:,1))';
        else if(isnumeric(node_table))
                current_nodes_states=node_table(:,1)';
                current_node_activation_status=node_table(:,6)';
                current_path_states=path_table(:,1)';
            else
                disp('invalid datatype for node_table and path_table');
                return;
            end
        end
    else
        disp('Datatype for node table and path table are not valid');
        return;
    end
    if((time_stamp==1)||sum(prev_nodes_states-current_nodes_states)||sum(prev_node_activation_status-current_node_activation_status)||sum(prev_path_states-current_path_states))
        prev_nodes_states=current_nodes_states;
        UT_GUI.current_nodes_states=prev_nodes_states;
        prev_node_activation_status=current_node_activation_status;
        UT_GUI.current_node_activation_status=prev_node_activation_status;
        prev_path_states=current_path_states;
        UT_GUI.current_path_states=prev_path_states;
        UT_GUI.current_time=time_stamp;
        plot_refresher;
    end
    time_stamp=time_stamp+1;
end

function display_signals_or_tables(hObject,~)
    global UT_GUI change signals_list no_of_nodes
    if(strcmp(get(hObject,'String'),'Show Signals')==1)
        if(config_check~=1)
            return;
        end
        if(strcmp(get(UT_GUI.play_or_stop_button,'String'),'Play'))
            errordlg('Model not running','error','modal');
            return;
        end

        if((UT_GUI.logging_in_progress==1)||(UT_GUI.update_in_progress==1))
            errordlg('Close other Windows before continuing','Multiple windows open!','modal');
            return;
        end
        set(UT_GUI.node_table_handle,'Visible','off');
        set(UT_GUI.path_table_handle,'Visible','off');
        set(UT_GUI.trigger_table_handle,'Visible','off');
        uipanel_position=getpixelposition(UT_GUI.panel4_handle);
        for i=1:UT_GUI.nx,
            UT_GUI.signals_selection_button_handle(i)=uicontrol('Parent',UT_GUI.panel4_handle,'Style','radiobutton'...
            ,'String',''...
            ,'Units','Normalized'...
            ,'Position',[0.005 ((2*(UT_GUI.nx-i+1)-1)/(UT_GUI.nx*2)) 0.99 0.99*uipanel_position(3)/uipanel_position(4)]...
            ,'BackgroundColor',[0.7 0.9 0.8]...
            ,'Callback',@signals_to_display_picker,'Value',1);
        end
        no_of_nodes=UT_GUI.nx;
        change=0;
        signals_list=1:UT_GUI.nx;
        UT_GUI.ok_to_display=1;
        set(hObject,'String','Show Tables');
    else
        UT_GUI.ok_to_display=0;
        try
            delete(UT_GUI.plot_axis_handle);
            delete(UT_GUI.signals_selection_button_handle);
        catch
        end
        set(UT_GUI.node_table_handle,'Visible','on');
        set(UT_GUI.path_table_handle,'Visible','on');
        set(UT_GUI.trigger_table_handle,'Visible','on');   
        set(hObject,'String','Show Signals');
    end        
end

function signals_to_display_picker(hObject,eventdata)
global UT_GUI signals_list change changed_node
    for i=1:UT_GUI.nx
        if(eq(hObject,UT_GUI.signals_selection_button_handle(i)))
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
       
function gather_data(fill)
    global UT_GUI
    waitbar_handle=waitbar(0,'Gathering Data...');
    UT_GUI.udp_handle = udp('192.168.90.90', 4950, 'LocalPort', 4950);
    set(UT_GUI.udp_handle,'DatagramTerminateMode','off');
    fopen(UT_GUI.udp_handle);
    fprintf(UT_GUI.udp_handle,'x');
    pause(1);
    fprintf(UT_GUI.udp_handle,'l');
    pause(1);
    while(UT_GUI.udp_handle.BytesAvailable)
        fscanf(UT_GUI.udp_handle);
    end
    fprintf(UT_GUI.udp_handle,'ok');
    data=fscanf(UT_GUI.udp_handle);
    Log_plot_helper2(0,data,UT_GUI.nx,UT_GUI.px,fill);
    loop_count=1;
    while(1)
      fprintf(UT_GUI.udp_handle,'ok');%send acknowledgement for every datagram received, without this, heart won't continue sending data
      data=fscanf(UT_GUI.udp_handle);
      if(~isempty(find(data=='e',1)))
          break;
      end
      Log_plot_helper2(1,data,UT_GUI.nx,UT_GUI.px,fill);
      waitbar(loop_count/1000,waitbar_handle);
      loop_count=loop_count+1;
    end
    fclose(UT_GUI.udp_handle);
    clear UT_GUI.udp_handle;
    close(waitbar_handle);
end

function display_log(hObject,~)
    global UT_GUI
    global start_time;
    global duration current_range x_range;
    global Heart_log;
    global click_count;
    if(config_check~=1)
        return;
    end
    UT_GUI.logging_in_progress=1;
    current_range=zeros(1000,UT_GUI.nx);
    if((UT_GUI.ok_to_display==1)||(UT_GUI.update_in_progress==1))
        errordlg('Close other Windows before continuing','Multiple windows open!','modal');
        UT_GUI.logging_in_progress=0;
        return;
    end
    if(~UT_GUI.mode)
        gather_data(1);
    end
    duration=size(UT_GUI.node_activation_status_history,1);
    Heart_log.figure_handle=figure('Units', 'normalized'...
        ,'Position', [0 0 1 1]...
        ,'Resize','on'...
        ,'Name','Test Sample'...
        ,'NumberTitle','Off');
    Heart_log.axes_handle=axes('Units','normalized'...
        ,'Parent',Heart_log.figure_handle...
        ,'YTick',[]...
        ,'NextPlot','add'...
        ,'Position',[0.1 0.2 0.8 0.75]);
    uicontrol('Style','text','String','0s'...
        ,'Units','normalized'...
        ,'Position',[0.125 0.125 0.025 0.025]);
    Heart_log.slider1_handle=uicontrol('Style','slider'...
        ,'Min',1,...
        'Max',duration...
        ,'Value',1,...
        'Units','normalized'...
        ,'Position',[0.15 0.15 0.70 0.025]...
        ,'SliderStep',[0.0001 0.001]...
        ,'Callback',@replot);
    Heart_log.slider2_handle=uicontrol('Style','slider'...
        ,'Min',1,...
        'Max',duration...
        ,'Value',1000,...
        'Units','normalized'...
        ,'Position',[0.15 0.125 0.70 0.025]...
        ,'SliderStep',[0.0001 0.001]...
        ,'Callback',@replot);
    uicontrol('Style','text','String',strcat(num2str(duration/1000),'s')...
        ,'Units','normalized'...
        ,'Position',[0.85 0.15 0.03 0.025]);
    whitebg(Heart_log.figure_handle,'k');
    Heart_log.interval_text_handle=text('Units','data','Position',[0 0],'String','','HitTest','off');
    set(Heart_log.axes_handle,'ButtonDownFcn',@set_time_interval);
    x_range=(1:1000)';
    click_count=0;
    color_string='ymcrgb';
    hold on;
    for i=1:UT_GUI.nx
        current_range(:,i)=UT_GUI.node_activation_status_history(1:1000,i)+1.5*(UT_GUI.nx-i);
        temp_string=strcat('Node ',num2str(i));
        Heart_log.label_handle(i)=text('Units','data','Position',[500,1.5*(UT_GUI.nx-i)+0.75],'String',temp_string,'HitTest','off');
        Heart_log.plot_handle(i)=plot(current_range(:,i));
        colorcode=color_string(mod(i,6)+1);
        set(Heart_log.plot_handle(i),'XDataSource','x_range','Color',colorcode);
        set(Heart_log.plot_handle(i),'YDataSource','current_range(:,i)','HitTest','off');
    end
    hold off;
    set(Heart_log.axes_handle,'YTickLabel',[]);
    set(Heart_log.axes_handle,'box','off');
    ylim([0 1.5*UT_GUI.nx]);
    %set(hObject,'String','Plot Heart Log');
    UT_GUI.logging_in_progress=0;
end

function replot(~,~)
    global Heart_log current_range UT_GUI x_range
    lower_limit=uint64(get(Heart_log.slider2_handle,'Value'));
    higher_limit=uint64(get(Heart_log.slider1_handle,'Value'));
    if(lower_limit>higher_limit)
        temp=lower_limit;
        lower_limit=higher_limit;
        higher_limit=temp;
    end
    x_range=(lower_limit:higher_limit)';
    current_range=zeros(higher_limit-lower_limit+1,UT_GUI.nx);
    %sum(current_range)
    for i=1:UT_GUI.nx
        current_range(:,i)=UT_GUI.node_activation_status_history(lower_limit:higher_limit,i)+1.5*(UT_GUI.nx-i);
        set(Heart_log.label_handle(i),'Position',[(higher_limit+lower_limit)/2,1.5*(UT_GUI.nx-i)+0.75]);
        refreshdata(Heart_log.plot_handle(i),'caller');
    end
end

function set_time_interval(hObject,~)
    global Heart_log click_count UT_GUI
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
        Heart_log.start_marker_handle=stem(Heart_log.axes_handle,mark_pt(1,1),1.5*UT_GUI.nx,'Color',[1 0.5 0],'LineStyle',':','Marker','<');
    else
        click_count=2;
        end_position=mark_pt;
        Heart_log.end_marker_handle=stem(Heart_log.axes_handle,mark_pt(1,1),1.5*UT_GUI.nx,'Color',[1 0.5 0],'LineStyle',':','Marker','>');
        if(start_position(1)>end_position(1))
            pos=end_position(1)+(start_position(1)-end_position(1))/2;
        else
            pos=start_position(1)+(end_position(1)-start_position(1))/2;
        end
        set(Heart_log.interval_text_handle,'String',strcat(num2str(abs(start_position(1)-end_position(1))),'ms'),'Position',[pos 1.5*UT_GUI.nx]);
        hold off;
    end        
end

function upload_trigger_table(~,~)
    global UT_GUI
    if(size(get(UT_GUI.trigger_table_handle,'Data'),1)~=UT_GUI.nx)
        errordlg('Trigger Table does not have the same number of nodes as the heart configuration','Configuration Mismatch','modal');
        return;
    end
    UT_GUI.trigger_table=get(UT_GUI.trigger_table_handle,'Data');
    max_paces=max(UT_GUI.trigger_table(:,1));
    nx_string=num2str(UT_GUI.nx);
    ny_string=num2str(7);
    transmit=strcat(nx_string,',',ny_string);
    edited_trigger_table=zeros(UT_GUI.nx,21);
    for i=1:UT_GUI.nx,
        for j=max_paces+1:-1:1,
            if((~isnan(UT_GUI.trigger_table(i,j)))&&((round(UT_GUI.trigger_table(i,j))~=UT_GUI.trigger_table(i,j))||(UT_GUI.trigger_table(i,j)<0)))
                errordlg('Invalid data found in the table','Data error','modal');
                return;
            end
            if((UT_GUI.trigger_table(i,1)~=0)&&(j~=1)&&(j<=(UT_GUI.trigger_table(i,1)+1))&&(UT_GUI.trigger_table(i,j)==0))
                errordlg('Zero interval between paces found in the table','Hazardous Pacing Setup','modal');
                return;
            end
            if(isnan(UT_GUI.trigger_table(i,j)))
                edited_trigger_table(i,j)=0;
            else
                edited_trigger_table(i,j)=UT_GUI.trigger_table(i,j);
            end
        end
    end
    
    %The character 'z' indicates end of transmission
    for i=1:UT_GUI.nx,
        for j=1:21,
            transmit=strcat(transmit,',',num2str(edited_trigger_table(i,j)));
        end
    end
    transmit=strcat(transmit,',z');
    UT_GUI.udp_handle = udp('192.168.90.90', 4950, 'LocalPort', 4950);
    set(UT_GUI.udp_handle,'DatagramTerminateMode','off');
    fopen(UT_GUI.udp_handle);
    fprintf(UT_GUI.udp_handle,'a');
    pause(1);
    fprintf(UT_GUI.udp_handle,'t');
    pause(1);
    flushinput(UT_GUI.udp_handle);
    fprintf(UT_GUI.udp_handle,transmit);
    in=str2double(fscanf(UT_GUI.udp_handle));
    if(in==size(transmit))
        msgbox('Update Complete!','Success');
    else
        %msgbox('Update Failed, please try again','Error','error');
    end
    fclose(UT_GUI.udp_handle);
    clear UT_GUI.udp_handle;
end

function update_meaning(~,eventdata)
    global UT_GUI
    edited_cell=eventdata.Indices(1,:);
    if(edited_cell(2)==1)
        if(eventdata.NewData<0)
            errordlg('Invalid number for this field, only non negative numbers allowed','Wrong Entry','modal'); 
            set(UT_GUI.trigger_table_handle,'Data',UT_GUI.trigger_table);
        else if(eventdata.NewData>UT_GUI.MAX_PACES)
                errordlg('Maximum number of Paces allowed is 20','Reduce Paces','modal'); 
                set(UT_GUI.trigger_table_handle,'Data',UT_GUI.trigger_table);
            else
                update_t_table_on_GUI(eventdata.NewData,UT_GUI.trigger_table,get(UT_GUI.trigger_table_handle,'Data'));
            end
        end
    end
end

function update_t_table_on_GUI(newdata,old_table,new_table)
    global UT_GUI
    col_count=max(0,max(old_table(:,1)));
    if(col_count<newdata)   
        UT_GUI.trigger_table=[new_table zeros(UT_GUI.nx,newdata-col_count)];
        temp_columnformat_string={'numeric'};
        temp_columneditable_array=true;
        temp_columnname_string={'Pace Count'};
        for i=1:newdata,
            temp_columnformat_string{1,1+i}='numeric';
            temp_columneditable_array=[temp_columneditable_array,true];
            temp_columnname=['Pace ',num2str(i),' interval'];
            temp_columnname_string{1,1+i}=temp_columnname;      
        end
        set(UT_GUI.trigger_table_handle,'Data',UT_GUI.trigger_table,...
            'ColumnFormat',temp_columnformat_string,'ColumnEditable',temp_columneditable_array,'ColumnName',temp_columnname_string);
    else
       new_col_count=max(0,max(new_table(:,1)));
       if(col_count>new_col_count)
            new_table(:,new_col_count+2:end)=[];
            UT_GUI.trigger_table=new_table;
            temp_columnformat_string=get(UT_GUI.trigger_table_handle,'ColumnFormat');
            temp_columneditable_array=get(UT_GUI.trigger_table_handle,'ColumnEditable');
            temp_columnname_string=get(UT_GUI.trigger_table_handle,'ColumnName');
            temp_columnformat_string(new_col_count+2:end)=[];
            temp_columneditable_array(new_col_count+2:end)=[];
            temp_columnname_string(new_col_count+2:end)=[];
            set(UT_GUI.trigger_table_handle,'Data',UT_GUI.trigger_table,...
                'ColumnFormat',temp_columnformat_string,'ColumnEditable',temp_columneditable_array,'ColumnName',temp_columnname_string);
       end
    end
    UT_GUI.trigger_table=get(UT_GUI.trigger_table_handle,'Data');
    for i=1:UT_GUI.nx
        for j=2:size(UT_GUI.trigger_table,2)
            if(isnan(UT_GUI.trigger_table(i,j))&&(j<=(UT_GUI.trigger_table(i,1)+1)))
                UT_GUI.trigger_table(i,j)=0;
            end
            if(j>(UT_GUI.trigger_table(i,1)+1))
                UT_GUI.trigger_table(i,j)=NaN;
            end
        end
    end
    set(UT_GUI.trigger_table_handle,'Data',UT_GUI.trigger_table);
end

function create_t_table_on_GUI(trigger_table,figure_handle)
    global UT_GUI
    col_count=max(trigger_table(:,1));
    UT_GUI.trigger_table=trigger_table;
    temp_columnformat_string={'numeric'};
    temp_columneditable_array=true;
    temp_columnname_string={'Trigger Count'};
    for i=1:col_count,
        temp_columnformat_string{1,1+i}='numeric';
        temp_columneditable_array=[temp_columneditable_array,true];
        temp_columnname=['Pace ',num2str(i),' interval'];
        temp_columnname_string{1,1+i}=temp_columnname;
    end
    set(figure_handle,'Data',UT_GUI.trigger_table,...
    'ColumnFormat',temp_columnformat_string,'ColumnEditable',temp_columneditable_array,'ColumnName',temp_columnname_string);
end

function load_model(~,~)
    global UT_GUI
    [fname,path] = uigetfile('*.mat', 'Load VHM Model');
    load([path fname]);
    UT_GUI.node_table=node_table;
    UT_GUI.path_table=path_table;
    try
        create_t_table_on_GUI(trigger_table,UT_GUI.trigger_table_handle);
    catch
    end
    UT_GUI.nx=size(UT_GUI.node_table,1);
    UT_GUI.px=size(UT_GUI.path_table,1);
    set(UT_GUI.node_table_handle,'Data',UT_GUI.node_table);
    set(UT_GUI.path_table_handle,'Data',UT_GUI.path_table);
    UT_GUI.nodes_position=node_pos;
    set(UT_GUI.node_pos,'XData',node_pos(:,1),'YData',node_pos(:,2));
    try
        delete(UT_GUI.paths_handle);
    catch
    end
    UT_GUI.paths_handle=[];
    for i=1:UT_GUI.px
        UT_GUI.paths_handle(end+1)=line([node_pos(path_table(i,2),1) node_pos(path_table(i,3),1)],[node_pos(path_table(i,2),2) node_pos(path_table(i,3),2)],'LineWidth',5,'HitTest','off');
    end
    %update_tooltip;
end

function response=update_tables
    global UT_GUI
    if(config_check~=1)
        return;
    end
    UT_GUI.update_in_progress=1;
    UT_GUI.node_table=get(UT_GUI.node_table_handle,'Data');
    UT_GUI.path_table=get(UT_GUI.path_table_handle,'Data');
    %%%Check for correctness of entries first%%%
    response=0;
    if(sum(sum((round(UT_GUI.node_table)~=UT_GUI.node_table)))||sum(sum(round(UT_GUI.path_table)~=UT_GUI.path_table)))
        errordlg('decimal values found in the table(s)','Decimal values not allowed!!!','modal');
        UT_GUI.update_in_progress=0;
        return;
    end
    display_string1='Node table Entries:';
    error1=0;
    for i=1:UT_GUI.nx,
        skiplist=[];
        for j=1:11,
            if(UT_GUI.node_table(i,j)<0)
                error1=1;
                skiplist=[skiplist,j];
                display_string1=[display_string1,'(',num2str(i),',',num2str(j),')::'];
            end
        end
        if(UT_GUI.node_table(i,1)>3)
            error1=1;
            if(isempty(find(skiplist==1)))
                display_string1=[display_string1,'(',num2str(i),',1)::'];
            end
        end
        if(UT_GUI.node_table(i,3)<UT_GUI.node_table(i,2))
            error1=1;
            if(isempty(find(skiplist==2)))
                display_string1=[display_string1,'(',num2str(i),',2)::'];
            end
        end
        if(UT_GUI.node_table(i,5)<UT_GUI.node_table(i,4))
            error1=1;
            if(isempty(find(skiplist==4)))
                display_string1=[display_string1,'(',num2str(i),',4)::'];
            end
        end
        if(UT_GUI.node_table(i,7)<UT_GUI.node_table(i,6))
            error1=1;
            if(isempty(find(skiplist==6)))
                display_string1=[display_string1,'(',num2str(i),',6)::'];
            end
        end
        if(UT_GUI.node_table(i,12)>1)
            error1=1;
            if(isempty(find(skiplist==12)))
                display_string1=[display_string1,'(',num2str(i),',12)::'];
            end
        else
            if(UT_GUI.node_table(i,12)==0 && UT_GUI.node_table(i,9)<UT_GUI.node_table(i,8))
                error1=1;
                if(isempty(find(skiplist==8)))
                    display_string1=[display_string1,'(',num2str(i),',8)::'];
                end
            end
            if(UT_GUI.node_table(i,12)==1 && UT_GUI.node_table(i,9)>UT_GUI.node_table(i,8))
                error1=1;
                if(isempty(find(skiplist==8)))
                    display_string1=[display_string1,'(',num2str(i),',8)::'];
                end
            end
        end
        if(UT_GUI.node_table(i,10)>1)
            error1=1;
            if(isempty(find(skiplist==10)))
                display_string1=[display_string1,'(',num2str(i),',10)::'];
            end
        end
        if(UT_GUI.node_table(i,11)>1)
            error1=1;
            if(isempty(find(skiplist==11)))
                display_string1=[display_string1,'(',num2str(i),',11)::'];
            end
        end
    end
    error2=0;
    display_string2='Path table Entries:';
    for i=1:UT_GUI.px,
        skiplist=[];
        for j=1:8,
            if(UT_GUI.path_table(i,j)<=0)
                error2=1;
                skiplist=[skiplist,j];
                display_string2=[display_string2,'(',num2str(i),',',num2str(j),')::'];
            end
        end
        if(UT_GUI.path_table(i,5)<UT_GUI.path_table(i,4))
            error2=1;
            if(isempty(find(skiplist==4)))
                display_string2=[display_string2,'(',num2str(i),',4)::'];
            end
        end
        if(UT_GUI.path_table(i,7)<UT_GUI.path_table(i,6))
            error2=1;
            if(isempty(find(skiplist==6)))
                display_string2=[display_string2,'(',num2str(i),',6)::'];
            end
        end
        if(UT_GUI.path_table(i,2)>UT_GUI.nx)
            error2=1;
            if(isempty(find(skiplist==2)))
                display_string2=[display_string2,'(',num2str(i),',2)::'];
            end
        end
        if(UT_GUI.path_table(i,3)>UT_GUI.nx)
            error2=1;
            if(isempty(find(skiplist==2)))
                display_string2=[display_string2,'(',num2str(i),',3)::'];
            end
        end
    end    
    if((error2>0)&&(error1>0))
        display_string=strcat(display_string1,display_string2);
        errordlg(display_string,'Invalid Entries Found!!!','modal');
        UT_GUI.update_in_progress=0;
        return;
    else if(error1>0)
            errordlg(display_string1,'Invalid Entries Found!!!','modal');
            UT_GUI.update_in_progress=0;
            return;
        else if(error2>0)
            errordlg(display_string2,'Invalid Entries Found!!!','modal');
            UT_GUI.update_in_progress=0;
            return; 
            end
        end
    end
    %%%END of correctness checking%%%
    %%%Transmission of the updated tables to board%%%
    %the number of rows and columns in the node table is converted to string to
    %be sent to the board
    nx_string=num2str(UT_GUI.nx);
    ny_string=num2str(12);
    %commas seperate every number sent to the board
    transmit=strcat(nx_string,',',ny_string);
    for i=1:UT_GUI.nx,
        for j=1:12,
            transmit=strcat(transmit,',',num2str(UT_GUI.node_table(i,j)));
        end
    end
    %'x' seperates the node table data from the path table data
    transmit=strcat(transmit,',','x,');
    %number of rows and columns of the path table converted to string to be
    %appended to the data sent to the board
    px_string=num2str(UT_GUI.px);
    py_string=num2str(8);
    transmit=strcat(transmit,px_string,',',py_string);
    for i=1:UT_GUI.px,
        for j=1:8,
            if((j==2)||(j==3))
                %*******IMPORTANT*******%
                %The table used for matlab considers the first node to be
                %number 1 but in C, first element of the array is indexed 0,
                %hence the path source and destination nodes should be reduced
                %by 1 to make sense in C
                transmit=strcat(transmit,',',num2str(UT_GUI.path_table(i,j)-1));
            else
                transmit=strcat(transmit,',',num2str(UT_GUI.path_table(i,j)));
            end
        end
    end
    %The character 'z' indicates end of transmission
    transmit=strcat(transmit,',z');
    UT_GUI.udp_handle = udp('192.168.90.90', 4950, 'LocalPort', 4950);
    set(UT_GUI.udp_handle,'DatagramTerminateMode','off');
    fopen(UT_GUI.udp_handle);
    fprintf(UT_GUI.udp_handle,'a');
    pause(1);
    fprintf(UT_GUI.udp_handle,'u');
    pause(1);
    flushinput(UT_GUI.udp_handle);
    fprintf(UT_GUI.udp_handle,transmit);
    in=(fscanf(UT_GUI.udp_handle));
    if(strcmp(in,[num2str(transmit) '\n']))
        msgbox('Update Complete!','Success');
    else
        %msgbox('Update Failed, please try again','Error','error');
    end
    fclose(UT_GUI.udp_handle);
    clear UT_GUI.udp_handle;
    UT_GUI.node_activation_code_table=zeros(1,UT_GUI.nx+1);
    UT_GUI.node_status_code_table=ones(1,UT_GUI.nx+1);
    UT_GUI.node_status_code_table(1,1)=0;
    UT_GUI.path_status_code_table=ones(1,UT_GUI.px+1);
    UT_GUI.path_status_code_table(1,1)=0;
    UT_GUI.update_in_progress=0;
    response=1;
end

function response=config_check
global UT_GUI
    response=0;
    if((size(UT_GUI.node_table,1)<1)||(size(UT_GUI.node_table,2)~=12)||(size(UT_GUI.path_table,1)<1)||(size(UT_GUI.path_table,2)~=8)...
            ||(UT_GUI.nx<1)||(UT_GUI.px<1)||(size(UT_GUI.node_table,1)~=UT_GUI.nx)||(size(UT_GUI.path_table,1)~=UT_GUI.px))
        errordlg('Tables not loaded correctly','Check Tables','modal');
    else
        response=1;
    end
end
    
function save_model(~,~)
    global UT_GUI
    if(config_check~=1)
        return;
    end
    [fname,path] = uiputfile('*.mat', 'Save VHM Model');
    dir=[path fname];
    node_table=get(UT_GUI.node_table_handle,'Data');
    path_table=get(UT_GUI.path_table_handle,'Data');
    node_pos(:,1)=get(UT_GUI.node_pos,'XData');
    node_pos(:,2)=get(UT_GUI.node_pos,'YData');
    trigger_table=get(UT_GUI.trigger_table_handle,'Data');
    save(dir,'node_table','path_table','node_pos','trigger_table');
end

function button_press(hObject,~)
global UT_GUI
persistent press_count start_point end_point source_node dest_node
    tolerance=10;
    pt=round(get(hObject,'CurrentPoint'));
    if(UT_GUI.add_path_mode==0)
        press_count=0;
        UT_GUI.nodes_position(end+1,:)=[pt(1,1) pt(1,2)];
        set(UT_GUI.node_pos,'XData',UT_GUI.nodes_position(:,1),'YData',UT_GUI.nodes_position(:,2));
        set_node_configuration(pt(1,1:2),size(UT_GUI.nodes_position,1));
    else
        distancesToMouse = hypot(UT_GUI.nodes_position(:,1) - pt(1,1), UT_GUI.nodes_position(:,2) - pt(1,2));
        [val, ind] = min(abs(distancesToMouse));
        if abs(pt(1,1) - UT_GUI.nodes_position(ind,1)) < tolerance && abs(pt(1,2) - UT_GUI.nodes_position(ind,2)) < tolerance        
            if(press_count==0)
                start_point=UT_GUI.nodes_position(ind,:);
                set(UT_GUI.selected_node_pos,'XData',start_point(1),'YData',start_point(2));
                source_node=ind;
            else
                end_point=UT_GUI.nodes_position(ind,:);
                set(UT_GUI.selected_node_pos,'XData',[],'YData',[]);
                UT_GUI.paths_handle(end+1)=line([start_point(1) end_point(1)],[start_point(2) end_point(2)],'LineWidth',5);
                dest_node=ind;
                set_path_configuration(source_node,dest_node,end_point,size(UT_GUI.paths_handle,1));
                start_point=[];
                end_point=[];
                source_node=[];
                dest_node=[];
                press_count=-1;
            end
            press_count=press_count+1;
        end 
    end  
end

function hinter(hObject,eventdata)
    global UT_GUI
    if(UT_GUI.nx>0)
        tolerance=10;
        mousePoint=get(UT_GUI.heart_axes_handle,'CurrentPoint');
        mouseX = mousePoint(1,1);
        mouseY = mousePoint(1,2);
        distancesToMouse = hypot(UT_GUI.nodes_position(:,1) - mouseX, UT_GUI.nodes_position(:,2) - mouseY);
        [val, ind] = min(abs(distancesToMouse));
        if abs(mouseX - UT_GUI.nodes_position(ind,1)) < tolerance && abs(mouseY - UT_GUI.nodes_position(ind,2)) < tolerance
            UT_GUI.node_in_focus=ind;
            set(UT_GUI.hint_text_handle, 'String', ['node ' num2str(ind)]);
            set(UT_GUI.hint_text_handle, 'Position', [UT_GUI.nodes_position(ind,1) + 2*(rand()-0.5)*tolerance, UT_GUI.nodes_position(ind,2) + 2*(rand()-0.5)*tolerance])
        else
            UT_GUI.node_in_focus=0;
            set(UT_GUI.hint_text_handle, 'String', '')
        end
    end
end

function add_path(hObject,~)
global UT_GUI
    UT_GUI.add_path_mode=mod((UT_GUI.add_path_mode+1),2);
    if(UT_GUI.add_path_mode==1)
        set(hObject,'ForegroundColor',[1 0.5 0]);
        set(hObject,'Checked','on');
    else
        set(hObject,'ForegroundColor','k');
        set(hObject,'Checked','off');
    end
%     set(UT_GUI.main_gui_handle,'KeyPressFcn',@get_key);
%     set(UT_GUI.main_gui_handle,'
    
end

function set_node_configuration(position,node_count)
global current_node_config
    current_node_config.figure_handle=figure('Units', 'Pixels'...
    ,'Position', [position(1) position(2) 700 100]...
    ,'Resize','off'...
    ,'Name',strcat('Node ',num2str(node_count),' Settings')...
    ,'NumberTitle','Off','CloseRequestFcn',@remove_last_node,'MenuBar','none');
    uicontrol('Style','text','String','Node State','Position',[5,70,60,20]);
    current_node_config.node_number=uicontrol('Parent',current_node_config.figure_handle,'Style','text','String','1','Position',[5,50,60,20],'BackgroundColor','white');
    uicontrol('Style','text','String','Current TERP','Position',[70,70,70,20]);
    current_node_config.current_erp=uicontrol('Parent',current_node_config.figure_handle,'Style','edit','String','9999','Position',[70,50,70,20],'BackgroundColor','white');
    uicontrol('Style','text','String','Default TERP','Position',[145,70,70,20]);
    current_node_config.erp=uicontrol('Parent',current_node_config.figure_handle,'Style','edit','String','9999','Position',[145,50,70,20],'BackgroundColor','white');
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
end

function read_node_data(~,~)
global current_node_config UT_GUI
    temp=[str2double(get(current_node_config.node_number,'String')) str2double(get(current_node_config.current_erp,'String')) str2double(get(current_node_config.erp,'String'))...
        str2double(get(current_node_config.current_rrp,'String')) str2double(get(current_node_config.rrp,'String')) str2double(get(current_node_config.current_rest,'String'))...
        str2double(get(current_node_config.rest,'String')) str2double(get(current_node_config.erp_min,'String')) str2double(get(current_node_config.erp_max,'String'))...
        0 0 get(current_node_config.node_type,'Value')];
    %set(UT_GUI.no_of_nodes_handle,'String',num2str(size(UT_GUI.node_table,1)));
    if(size(temp,2)~=12)
        errordlg('Invalid Entries for node!!!','Check values','modal');
        return;
    end
    UT_GUI.nx=UT_GUI.nx+1;
    UT_GUI.node_table(UT_GUI.nx,:)=temp;
    set(UT_GUI.node_table_handle,'Data',UT_GUI.node_table);
    delete(current_node_config.figure_handle);
    UT_GUI.trigger_table=[get(UT_GUI.trigger_table_handle,'Data');zeros(1,max(1,size(get(UT_GUI.trigger_table_handle,'Data'),2)))];
    set(UT_GUI.trigger_table_handle,'Data',UT_GUI.trigger_table);
    update_t_table_on_GUI(0,UT_GUI.trigger_table,UT_GUI.trigger_table);
%     UT_GUI.trigger_table=[get(UT_GUI.trigger_table_handle,'Data');zeros(1,max(1,size(get(UT_GUI.trigger_table_handle,'Data'),2)))];
%     set(UT_GUI.trigger_table_handle,'Data',UT_GUI.trigger_table);
%     %update_tooltip;
end

function remove_last_node(~,~)
global current_node_config UT_GUI
    UT_GUI.nodes_position(end,:)=[];
    try
        set(UT_GUI.node_pos,'XData',UT_GUI.nodes_position(:,1),'YData',UT_GUI.nodes_position(:,2));
    catch
    end
    delete(current_node_config.figure_handle);
end

function set_path_configuration(source_node,dest_node,position,path_count)
global current_path_config
    current_path_config.figure_handle=figure('Units', 'Pixels'...
    ,'Position', [position(1) position(2) 620 100]...
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
    uicontrol('Style','text','String','All Default','Position',[545,70,70,20]);  
    current_path_config.all_def=uicontrol('Parent',current_path_config.figure_handle,'Style','edit','String','999','Position',[545,50,70,20],'BackgroundColor','white');
    uicontrol('Parent',current_path_config.figure_handle,'Style','pushbutton','Position',[225,10,80,30],'String','OK','Callback',@read_path_data);
    uicontrol('Parent',current_path_config.figure_handle,'Style','pushbutton','Position',[310,10,80,30],'String','Cancel','Callback',@remove_last_path);
end

function read_path_data(~,~)
global current_path_config UT_GUI
    temp=[str2double(get(current_path_config.path_number,'String')) str2double(get(current_path_config.source_node,'String')) str2double(get(current_path_config.dest_node,'String'))...
        str2double(get(current_path_config.current_fc,'String')) str2double(get(current_path_config.def_fc,'String')) str2double(get(current_path_config.current_bc,'String')) str2double(get(current_path_config.def_bc,'String'))...
        str2double(get(current_path_config.all_def,'String'))];
    %set(UT_GUI.no_of_paths_handle,'String',num2str(size(UT_GUI.path_table,1)));
    if(size(temp,2)~=8)
        errordlg('Invalid Entries for Path!!!','Check values','modal');
        return;
    end
    UT_GUI.path_table(UT_GUI.px+1,:)=temp;
    UT_GUI.px=UT_GUI.px+1;
    set(UT_GUI.path_table_handle,'Data',UT_GUI.path_table);
    delete(current_path_config.figure_handle);
end

function remove_last_path(hObject,~)
global UT_GUI current_path_config
    delete(UT_GUI.paths_handle(end));
    UT_GUI.paths_handle(end)=[];
    delete(current_path_config.figure_handle);
end

function remove_node(~,~)
global UT_GUI
    UT_GUI.node_table(end,:)=[];
    %set(UT_GUI.no_of_nodes_handle,'String',num2str(size(UT_GUI.node_table,1)));
    set(UT_GUI.node_table_handle,'Data',UT_GUI.node_table);
    if(UT_GUI.nx>0)
        UT_GUI.nx=UT_GUI.nx-1;
        temp_data=get(UT_GUI.trigger_table_handle,'Data');
        set(UT_GUI.trigger_table_handle,'Data',temp_data(1:end-1,:));
    end
    if(size(UT_GUI.nodes_position,1)>0)
        UT_GUI.nodes_position(end,:)=[];
    end
    set(UT_GUI.node_pos,'XData',UT_GUI.nodes_position(:,1),'YData',UT_GUI.nodes_position(:,2));
    %update_tooltip;
end

function remove_path(~,~)
global UT_GUI
    UT_GUI.path_table(end,:)=[];
    %set(UT_GUI.no_of_paths_handle,'String',num2str(size(UT_GUI.path_table,1)));
    set(UT_GUI.path_table_handle,'Data',UT_GUI.path_table);
    if(UT_GUI.px>0)
        UT_GUI.px=UT_GUI.px-1;
    end
    try
        delete(UT_GUI.paths_handle(end));
        UT_GUI.paths_handle(end)=[];
    catch
    end
end

function close_gui(hObject,~)
global UT_GUI
    try
        delete(hObject);
        clear all;
        close all;
    catch
    end
end