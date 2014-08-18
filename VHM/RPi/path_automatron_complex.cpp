/*function [path_para,temp_act_1,temp_act_2]=path_automatron(path_para,node_act_1,node_act_2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function update the status of a single path
%
% Inputs:
% path_para: Cell array, parameters for the paths
%
%            format: {'path_name',path_state_index, entry_node_index,
%            exit_node_index, amplitude_factor, forward_speed,
%            backward_speed, forward_timer_current, forward_timer_default,
%            backward_timer_current, backward_timer_default, path_length,
%            path_slope}
% node_act_1: boolean, activation status of the entry node
% node_act_2: boolean, activation status of the exit node
%
% Outputs:
% temp_act_1: boolean, local temporary node activation of the entry node
% temp_act_2: boolean, local temporary node activation of the exit node
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#include "stdio.h"
void path_automatron_complex(int* path_para,int* act_array)
{
	static int conflict_cur=0;
	int temp_act_1=0;
//There is a deviation from the matlab heart model where the first node activation signal doesn't show up in the node activation but is made to appear in this code
	int temp_act_2=0;
	switch(path_para[0]) //path_state
	{
		case 1: 
			if(act_array[0])
			{
				path_para[0]=2; //path_state
			}
			else
			{
				if(act_array[1])
				{	
					path_para[0]=3; //path_state
				}
			}
			break;
		case 2:
			if(act_array[1])
			{
				path_para[0]=5; //path_state
			}
			else
			{
				if(path_para[3]==0) //ante_cur
				{
					path_para[3]=path_para[4]; //ante_cur=ante_def
					//temp_act_2=1;
					temp_act_2=1;
					path_para[0]=4; //path_state
					conflict_cur=0;
				}
				else
				{
					--path_para[3]; //ante_cur=ante_cur-1
				}
			}
			break;
		case 3:
			if(act_array[0])
			{
				path_para[0]=5; //path_state
			}
			else
			{
				if(path_para[5]==0)
				{
					path_para[5]=path_para[6];
					//temp_act_1=1;
					temp_act_1=1;
					path_para[0]=4; //path_state
					conflict_cur=0;
				}
				else
				{
					--path_para[5];
				}
			}
			break;
		case 4:
			if(conflict_cur>2)
			{
				path_para[0]=1; //path_state
			}
			else
			{
				++conflict_cur;
			}
			break;
		case 5:
			path_para[0]=4; //path_state
			conflict_cur=0;
			break;
	}
	act_array[0]=temp_act_1;
	act_array[1]=temp_act_2;
}
