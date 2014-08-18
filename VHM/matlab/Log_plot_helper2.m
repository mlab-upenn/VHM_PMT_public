function Log_plot_helper2(option,response,no_of_nodes,no_of_paths,fill)
global GUI start_time
persistent not_ready blanks
    [current_nodes_states,current_node_activation_status,current_path_states,current_time]=data_decoder2(response,no_of_nodes,no_of_paths);
    if((option==0)||(not_ready==1))%initialize various history
        blanks=0;
        start_time=current_time;
        GUI.node_activation_status_history=current_node_activation_status;
        GUI.nodes_states_history=current_nodes_states;
        GUI.path_states_history=current_path_states;
        GUI.time_stamp_history=current_time;            
        if(current_time==0)
            not_ready=1;
        else
            not_ready=0;
        end
    else
        if((current_time==0)||(blanks==1))
            blanks=1;
            return;
        end
        if(fill)%interpolate values between two time stamps
            for i=start_time+1:current_time-1,
                GUI.node_activation_status_history=[GUI.node_activation_status_history;GUI.node_activation_status_history(end,:)];
                GUI.nodes_states_history=[GUI.nodes_states_history;GUI.nodes_states_history(end,:)];
                GUI.path_states_history=[GUI.path_states_history;GUI.path_states_history(end,:)];
                GUI.time_stamp_history=[GUI.time_stamp_history;i];
            end
        end
        %add to the history of signals
        GUI.node_activation_status_history(end+1,:)=current_node_activation_status;
        GUI.nodes_states_history(end+1,:)=current_nodes_states;
        GUI.path_states_history(end+1,:)=current_path_states;
        GUI.time_stamp_history(end+1,:)=current_time;
        start_time=current_time;
    end
end