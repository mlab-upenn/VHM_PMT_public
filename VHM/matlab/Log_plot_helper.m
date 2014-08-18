function Log_plot_helper(option,response,no_of_nodes,no_of_paths)
global node_activation_status nodes_states path_states start_time
data_fields=response;
node_act_data=find(data_fields=='!');%node activation data presence status, search for '!' in the matches array, if present, it means that node 
%activation data is present in this response
    if ~isempty(node_act_data)%if no new node activation data, don't change the previous value of node_activation_status
        temp_activation_data=str2double(data_fields(1:node_act_data-1));
        data_fields(1:node_act_data)=[];
    else
        temp_activation_data=0;
    end
    node_sts_data=find(data_fields=='"');%nodes' status data presence status
    if ~isempty(node_sts_data)%if no node status change data, don't change the previous value of nodes_states
        temp_node_data=str2double(data_fields(1:node_sts_data-1));
        data_fields(1:node_sts_data)=[];
    else
        temp_node_data=0;
    end
    path_sts_data=find(data_fields=='#');%paths' status data presence status
    if ~isempty(path_sts_data)%if no node status change data, don't change the previous value of path_states
        temp_path_data=str2double(data_fields(1:path_sts_data-1));
        data_fields(1:path_sts_data)=[];
    else
        temp_path_data=0;
    end
    time_data=find(data_fields=='$');%paths' status data presence status
    if ~isempty(time_data)%if no node status change data, don't change the previous value of path_states
        temp_time_data=str2double(data_fields(1:time_data-1));
    else
        temp_time_data=start_time;
    end
    if(option==0)
        current_nodes_states=zeros(1,no_of_nodes);
        current_node_activation_status=zeros(1,no_of_nodes);
        current_path_states=zeros(1,no_of_paths);
    end
    for j=1:no_of_nodes,
        %undo the encoding done by the board to retrieve information
        current_nodes_states(j)=mod(temp_node_data,4)+1;%convert the encoding from "0 to 1" to "1 to 2", this is the reason for addition by 1 
        current_node_activation_status(j)=mod(temp_activation_data,2);
        temp_node_data=floor(temp_node_data/4);%since MATLAB represents data in floating numbers, round it off to integer values
        temp_activation_data=floor(temp_activation_data/2);%since MATLAB represents data in floating numbers, round it off to integer values
    end
    for j=1:no_of_paths,
        %undo the encoding done by the board to retrieve information
       current_path_states(j)=mod(temp_path_data,4)+1;%convert the encoding from "0 to 1" to "1 to 2", this is the reason for addition by 1
       temp_path_data=floor(temp_path_data/4);%since MATLAB represents data in floating numbers, round it off to integer values
    end
    
    if(option==0)
        start_time=temp_time_data;
        node_activation_status=current_node_activation_status;
        nodes_states=current_nodes_states;
        path_states=current_path_states;
    else
        for i=start_time+1:temp_time_data-1,
            node_activation_status=[node_activation_status;node_activation_status(end,:)];
            nodes_states=[nodes_states;nodes_states(end,:)];
            path_states=[path_states;path_states(end,:)];
        end
        node_activation_status(end+1,:)=current_node_activation_status;
        nodes_states(end+1,:)=current_nodes_states;
        path_states(end+1,:)=current_path_states;
        start_time=temp_time_data;
    end
end