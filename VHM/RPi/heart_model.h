#ifndef HEARTMODEL_H
#define HEARTMODEL_H

void heart_model(int** node_table,int nx,int** path_table,int px,int** paths_to_each_node,int max_connections,void (*node_automatron)(int*,int*,int**,int),void (*path_automatron)(int*, int*),int mode);
#endif
