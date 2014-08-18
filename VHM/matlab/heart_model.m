function [node_table,path_table]=heart_model(node_table,path_table)
% The function update the parameters for nodes and paths in one time stamp
%
% Inputs:
% node_table: Cell array, each row contains parameters for one node
%
%    format: {node_state_index, TERP_current,
%            TERP_default, Trest_current,
%            Trest_default, node_activation,path_activation} 
%
% path_para: Cell array, each row contains parameters for one path
%
%    format: {path_state_index, entry_node_index,
%            exit_node_index, forward_timer_current, forward_timer_default,
%            backward_timer_current, backward_timer_default}

       % local temp node & path table
       temp_node={};
       temp_path={};     
       
       for i=1:size(node_table,1)
           %---------------------------------
           % find paths connecting to the node
           [path_ind,term_ind]=ind2sub([size(path_table,1),2],find(cell2mat(path_table(:,3:4))==i));
           
           %---------------------------------
           % update parameters for each node
           [temp_node(i,:)]=node_automatron(node_table(i,:));
           
           % create local variables for node activation signals
           temp_act{i}=temp_node{i,7};       
       end
       
      
       for i=1:size(path_table,1)
           % update parameters for each path
           [temp_path(i,:),node_act_1,node_act_2]=path_automatron(path_table(i,:),node_table{path_table{i,2},7},node_table{path_table{i,3},7});

           % node can be activated
            temp_act{path_table{i,2}}=temp_act{path_table{i,2}} || node_act_1;
            temp_act{path_table{i,3}}=temp_act{path_table{i,3}} || node_act_2;

       end
       % update the parameters to global variables
       node_table=[temp_node(:,1:5),temp_act',temp_node(:,7)];

       path_table=temp_path;