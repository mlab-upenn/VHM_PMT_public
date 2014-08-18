function [node_table,path_table]=heart_model(node_table,path_table)
% The function update the parameters for nodes and paths in one time stamp
%
% Inputs:
% node_table: Cell array, each row contains parameters for one node
%
%    format: {'node name', node_state_index, TERP_current,
%            TERP_default, TRRP_current, TRRP_default, Trest_current,
%            Trest_default, node_activation,[Terp_min,Terp_max],index_of_path_activate_the_node} 
%
% path_para: Cell array, each row contains parameters for one path
%
%    format: {'path_name',path_state_index, entry_node_index,
%            exit_node_index, amplitude_factor, forward_speed,
%            backward_speed, forward_timer_current, forward_timer_default,
%            backward_timer_current, backward_timer_default, path_length,
%            path_slope}
       
%        %**************************************************
%        % a temp path table that can be updated by node automata
%        temp_path_node=path_table;
%        %***************************************************
       
       for i=1:size(node_table,1)
           % run all nodes for one iteration (actually run simultaneously even
           % though the code runs sequentially because we don't update the
           % clock until after the entire heart model has run)
           %---------------------------------
           % find paths connecting to the node
           [path_ind,term_ind]=ind2sub([size(path_table,1),2],find(cell2mat(path_table(:,3:4))==i));
           % tells us how paths are structured (i.e. the starting and
           % ending nodes for each path)
           %---------------------------------
           % update parameters for each node
           [node_table(i,:),path_table]=node_automatron(node_table(i,:),path_ind,path_table);
           
           
       end
       
      
       for i=1:size(path_table,1)
           % update whether node is activated given parameters for each path
           [path_table(i,:),node_act_1,node_act_2]=path_automatron(path_table(i,:),node_table{path_table{i,3},11},node_table{path_table{i,4},11});
           node_table{path_table{i,3},10}=node_act_1 || node_table{path_table{i,3},10};
           node_table{path_table{i,4},10}=node_act_2 || node_table{path_table{i,4},10};
%            % update the local node activation signals of the two nodes
%            % connecting to the path by using "OR" operation
%            if node_table{path_table{i,3},2}~=2
%                 temp_act{path_table{i,3}}=temp_act{path_table{i,3}} || node_act_1;
%                 %-------------------------------------
%                 % store the path that activated the node
%                 if node_act_1==1
%                     temp_node{path_table{i,3},11}=i;
%                 end
%                 %-------------------------------------
%            else
%                temp_act{path_table{i,3}}=false;
%                 node_table{path_table{i,3},3}=node_table{path_table{i,3},4};
%            end
%            
%            if node_table{path_table{i,4},2}~=2
%                 temp_act{path_table{i,4}}=temp_act{path_table{i,4}} || node_act_2;
%                 %-------------------------------------
%                 % store the path that activated the node
%                 if node_act_2==1
%                     temp_node{path_table{i,4},11}=i;
%                 end
%                 %-------------------------------------
%            else
%                temp_act{path_table{i,4}}=false;
%                node_table{path_table{i,4},3}=node_table{path_table{i,4},4};
%            end
       end
       