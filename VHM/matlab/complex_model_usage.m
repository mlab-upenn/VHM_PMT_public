load case3_AVNRT %your complex heart model suited for matlab VHM
load pace_param_w_PVAAB
VHM_GUI('AVRNT_complex.mat');       %equivalent complex heart model created using the GUI
 while 1
     [node_table,path_table]=heart_model(node_table,path_table);
     pace_param=pacemaker_new(pace_param,node_table{1,10},node_table{end,10},1,1);
     node_table{1,10}=logical(pace_param.a_pace);
     node_table{end,10}=logical(pace_param.v_pace);
     VHM_GUI(node_table,path_table);
 end