function signals_display(option,current_node_activation_status,no_of_nodes)
    persistent prev_value count plot_handle figure_handle axis_handle
    if(option==0)
        count=0;
        color_string='ymcrgb';
        figure_handle=figure('Name','Signals Window','NumberTitle','off','Resize','on','Units','normalized','Position',[0.5 0 0.5 1],'CloseRequestFcn',@close_plot);
        axis_handle=axes('Parent',figure_handle,'Units','normalized','Position',[0 0 1 1]);
        whitebg(figure_handle,'k');
        hold on;
        for i=1:no_of_nodes
            prev_value(:,i)=zeros(100,1)+1.5*(no_of_nodes-i);
            plot_handle(i)=plot(axis_handle,prev_value(:,i));
            set(plot_handle(i),'YDataSource','prev_value(:,i)');
            colorcode=color_string(mod(i,6)+1);
            set(plot_handle(i),'Color',colorcode);
            temp_string=strcat('Node ',num2str(i));
            text(50,1.5*(no_of_nodes-i)+0.75,temp_string);
             
%             uicontrol('Style','text','String',temp_string...
%             ,'Units','normalized'...
%             ,'Position',[0.5 (no_of_nodes-i)/no_of_nodes+0.05 0.05 0.025]...
%             ,'ForegroundColor','w','BackgroundColor','k');
        end
        set(axis_handle,'XTick',[],'YTick',[]);
        set(axis_handle,'XTickLabel',[],'YTickLabel',[]);
        set(axis_handle,'box','off');
        ylim([0 1.5*no_of_nodes]);
        xlim([0 100]);
        hold off;
        tic;
    else
        count=mod(count,100)+1;
        for i=1:no_of_nodes
            prev_value(count,i)=current_node_activation_status(i)+1.5*(no_of_nodes-i);            
            refreshdata(plot_handle(i),'caller');
        end
        pause(0.00001);
    end
end

function close_plot(hObject,eventdata)
    global UT_GUI
    UT_GUI.ok_to_display=0;
    delete(hObject);
end