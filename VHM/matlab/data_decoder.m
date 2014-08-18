function [current_nodes_states,current_node_activation_status,current_path_states]=data_decoder(response,no_of_nodes,no_of_paths)        
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
    current_nodes_states=zeros(1,no_of_nodes);
    current_node_activation_status=zeros(1,no_of_nodes);
    current_path_states=zeros(1,no_of_paths);
    for j=1:no_of_nodes,
        %undo the encoding done by the board to retrieve information
        current_nodes_states(j)=mod(temp_node_data,4)+1;%convert the encoding from "0 to 1" to "1 to 2", this is the reason for addition by 1 
        current_node_activation_status(j)=mod(temp_activation_data,2);%offset of 1.5 added to show the signals seperately on the plot
        temp_node_data=floor(temp_node_data/4);%since MATLAB represents data in floating numbers, round it off to integer values
        temp_activation_data=floor(temp_activation_data/2);%since MATLAB represents data in floating numbers, round it off to integer values
    end
    for j=1:no_of_paths,
        %undo the encoding done by the board to retrieve information
       current_path_states(j)=mod(temp_path_data,4)+1;%convert the encoding from "0 to 1" to "1 to 2", this is the reason for addition by 1
       temp_path_data=floor(temp_path_data/4);%since MATLAB represents data in floating numbers, round it off to integer values
    end
end