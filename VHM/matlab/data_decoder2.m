function [current_nodes_states,current_node_activation_status,current_path_states,current_time]=data_decoder2(response,no_of_nodes,no_of_paths)        
    global GUI
    persistent prev_time
    parts=str2double(strsplit(response,','));
    %attempt to find the timestamp field, assign prev timestamp if not
    %found
    try
        current_time=parts(4);
    catch
        if(size(parts,2)<4)
           parts(size(parts,2):3)=0;
           if(isempty(prev_time))
                current_time=0;
           else
                current_time=prev_time+1;
           end
        end
    end
    %update prev_time
    if(current_time>prev_time)
        prev_time=current_time;
    end
    if(sum(GUI.node_activation_code_table(:,1)==parts(1)))%check if decoded value already present in node_activation_code_table
        current_node_activation_status=GUI.node_activation_code_table(GUI.node_activation_code_table(:,1)==parts(1),2:end);%assign decoded value by lookup in the table
    else
        %compute decoded value and add to the table as well
        GUI.node_activation_code_table(end+1,:)=zeros(1,no_of_nodes+1);
        GUI.node_activation_code_table(end,1)=parts(1);
        for i=1:no_of_nodes,
            GUI.node_activation_code_table(end,i+1)=mod(parts(1),2);
            parts(1)=floor(parts(1)/2);
        end
        current_node_activation_status=GUI.node_activation_code_table(end,2:end);
    end
    if(sum(GUI.node_status_code_table(:,1)==parts(2)))%check if decoded value already present in node_status_code_table
        current_nodes_states=GUI.node_status_code_table(GUI.node_status_code_table(:,1)==parts(2),2:end);%assign decoded value by lookup in the table
    else
        %compute decoded value and add to the table as well
        GUI.node_status_code_table(end+1,:)=zeros(1,no_of_nodes+1);
        GUI.node_status_code_table(end,1)=parts(2);
        for i=1:no_of_nodes,
            GUI.node_status_code_table(end,i+1)=mod(parts(2),4)+1;
            parts(2)=floor(parts(2)/4);
        end
        current_nodes_states=GUI.node_status_code_table(end,2:end);
    end         
    if(sum(GUI.path_status_code_table(:,1)==parts(3)))%check if decoded value already present in path_status_code_table
        current_path_states=GUI.path_status_code_table(GUI.path_status_code_table(:,1)==parts(3),2:end);%assign decoded value by lookup in the table
    else
        %compute decoded value and add to the table as well
        GUI.path_status_code_table(end+1,:)=zeros(1,no_of_paths+1);
        GUI.path_status_code_table(end,1)=parts(3);
        for i=1:no_of_paths,
            GUI.path_status_code_table(end,i+1)=mod(parts(3),4)+1;
            parts(3)=floor(parts(3)/4);
        end
        current_path_states=GUI.path_status_code_table(end,2:end);
    end
end