load case_cp_WB
%load pace_param_w_PVAAB
VHM_GUI('case_cp_WB');
node_table=num2cell(node_table);
path_table=num2cell(path_table);
 while 1
     [node_table,path_table]=heart_model(node_table,path_table);
    % pace_param=pacemaker_new(pace_param,node_table{1,6},node_table{end,6},1,1);
    % node_table{1,6}=logical(pace_param.a_pace);
    % node_table{end,6}=logical(pace_param.v_pace);
     VHM_GUI(node_table,path_table);
 end