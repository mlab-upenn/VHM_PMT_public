function Log_plot_helper2(option,response,no_of_nodes,no_of_paths,fill)
global UT_GUI start_time
[current_nodes_states,current_node_activation_status,current_path_states,current_time]=data_decoder2(response,no_of_nodes,no_of_paths);
    if(option==0)
        start_time=current_time;
        UT_GUI.node_activation_status_history=current_node_activation_status;
        UT_GUI.nodes_states_history=current_nodes_states;
        UT_GUI.path_states_history=current_path_states;
        UT_GUI.time_stamp_history=current_time;
    else
        if(fill)
            for i=start_time+1:current_time-1,
                UT_GUI.node_activation_status_history=[UT_GUI.node_activation_status_history;UT_GUI.node_activation_status_history(end,:)];
                UT_GUI.nodes_states_history=[UT_GUI.nodes_states_history;UT_GUI.nodes_states_history(end,:)];
                UT_GUI.path_states_history=[UT_GUI.path_states_history;UT_GUI.path_states_history(end,:)];
            end
        end
        UT_GUI.node_activation_status_history(end+1,:)=current_node_activation_status;
        UT_GUI.nodes_states_history(end+1,:)=current_nodes_states;
        UT_GUI.path_states_history(end+1,:)=current_path_states;
        UT_GUI.time_stamp_history(end+1,:)=current_time;
        start_time=current_time;
    end
end