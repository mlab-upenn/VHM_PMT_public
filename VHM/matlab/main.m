 load n4p3
 t=0;
 while 1
     t=t+1;
     [node_table,path_table]=heart_model(node_table,path_table);
     if node_table{1,6}
         1
     end
     if t==800
         node_table{1,6}=1;
     end
     if node_table{2,6}
         2
     end
     if node_table{3,6}
         3
     end
     if node_table{4,6}
         4
     end
 end