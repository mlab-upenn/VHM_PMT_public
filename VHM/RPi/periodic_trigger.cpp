#include "stdio.h"
#include "periodic_trigger.h"
void periodic_trigger(int** node_table,int* activation_column,int** trigger_table,char nx,int* sch_activation_ptr,int mode)
{
	*sch_activation_ptr=0;
	for(char i=0;i<nx;i++)
	{
		if((trigger_table[i][PACE_COUNT_COL]<=trigger_table[i][0])&&(trigger_table[i][0]>0))
		{
			if((trigger_table[i][CURRENT_TIME_TO_PACE_COL]==-1)||((trigger_table[i][PACE_COUNT_COL]==0)&&(node_table[i][5+mode*4]==1)))
			{
				trigger_table[i][CURRENT_TIME_TO_PACE_COL]=trigger_table[i][++trigger_table[i][PACE_COUNT_COL]];
			}
			else if(trigger_table[i][CURRENT_TIME_TO_PACE_COL]>=0)
			{
				trigger_table[i][CURRENT_TIME_TO_PACE_COL]--;
			}
			if((trigger_table[i][CURRENT_TIME_TO_PACE_COL]==0)&&(trigger_table[i][PACE_COUNT_COL]<=trigger_table[i][0]))
			{
				activation_column[i]|=1;
				trigger_table[i][CURRENT_TIME_TO_PACE_COL]=-1;
			}
			*sch_activation_ptr=1;
		}
	}
}
