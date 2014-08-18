function [current_nodes_states,current_node_activation_status,current_path_states,current_time]=data_decoder2(response,no_of_nodes,no_of_paths)        
    global UT_GUI
    persistent prev_time
    parts=str2double(strsplit(response,','));
    try
        current_time=parts(4);
    catch
        if(size(parts,2)<4)
           parts(size(parts,2):3)=0;
           if(isempty(prev_time))
                current_time=0;
           else
                current_time=prev_time;
           end
        end
    end
    if(current_time>prev_time)
        prev_time=current_time;
    end
    if(sum(UT_GUI.node_activation_code_table(:,1)==parts(1)))
        current_node_activation_status=UT_GUI.node_activation_code_table(UT_GUI.node_activation_code_table(:,1)==parts(1),2:end);
    else
        UT_GUI.node_activation_code_table(end+1,:)=zeros(1,no_of_nodes+1);
        UT_GUI.node_activation_code_table(end,1)=parts(1);
        for i=1:no_of_nodes,
            UT_GUI.node_activation_code_table(end,i+1)=mod(parts(1),2);
            parts(1)=floor(parts(1)/2);
        end
        current_node_activation_status=UT_GUI.node_activation_code_table(end,2:end);
    end
    size(UT_GUI.node_activation_code_table);
    if(sum(UT_GUI.node_status_code_table(:,1)==parts(2)))
        current_nodes_states=UT_GUI.node_status_code_table(UT_GUI.node_status_code_table(:,1)==parts(2),2:end);
    else
        UT_GUI.node_status_code_table(end+1,:)=zeros(1,no_of_nodes+1);
        UT_GUI.node_status_code_table(end,1)=parts(2);
        for i=1:no_of_nodes,
            UT_GUI.node_status_code_table(end,i+1)=mod(parts(2),4)+1;
            parts(2)=floor(parts(2)/4);
        end
        current_nodes_states=UT_GUI.node_status_code_table(end,2:end);
    end         
    
    if(sum(UT_GUI.path_status_code_table(:,1)==parts(3)))
        current_path_states=UT_GUI.path_status_code_table(UT_GUI.path_status_code_table(:,1)==parts(3),2:end);
    else
        UT_GUI.path_status_code_table(end+1,:)=zeros(1,no_of_paths+1);
        UT_GUI.path_status_code_table(end,1)=parts(3);
        for i=1:no_of_paths,
            UT_GUI.path_status_code_table(end,i+1)=mod(parts(3),4)+1;
            parts(3)=floor(parts(3)/4);
        end
        current_path_states=UT_GUI.path_status_code_table(end,2:end);
    end
end