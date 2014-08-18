/*function [node_table,path_table]=heart_model(node_table,path_table)
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

       % local temp node & path table
       
%        %**************************************************
%        % a temp path table that can be updated by node automata
%        temp_path_node=path_table;
%        %***************************************************/

#include "stdio.h"
void heart_model(int** node_table,int nx,int** path_table,int px,int** paths_to_each_node,int max_connections,void (*node_automatron)(int*,int*,int**,int),void (*path_automatron)(int*, int*),int mode)
{
	int act_array[2];
	for(int i=0;i<nx;i++)
	{
		node_automatron(node_table[i],paths_to_each_node[i],path_table,max_connections);
	}
	
	for (int i=0;i<px;i++)
	{
		act_array[0]=node_table[path_table[i][1]][6+mode*4];
		act_array[1]=node_table[path_table[i][2]][6+mode*4];
		path_automatron(path_table[i],act_array);
		node_table[path_table[i][1]][5+mode*4]|=act_array[0];
		node_table[path_table[i][2]][5+mode*4]|=act_array[1];
	}
}
