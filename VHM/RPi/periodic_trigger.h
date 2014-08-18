#ifndef _PERIODIC_TABLE_H
#define _PERIODIC_TABLE_H
#define MAX_PACES 20
#define PACE_COUNT_COL 21
#define CURRENT_TIME_TO_PACE_COL 22
    void periodic_trigger(int** node_table,int* activation_column,int** trigger_table,char nx,int* sch_activation_ptr,int mode);
#endif
