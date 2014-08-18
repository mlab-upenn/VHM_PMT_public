/*function [node_para,path_table]=node_automatron(node_para,path_ind,path_table)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The function update the  status of a single node by considering the current status of
% the node
%
% Inputs:
% node_para: Cell array, parameters for the nodes
%
%            format: {'node name', node_state_index, TERP_current,
%            TERP_default, TRRP_current, TRRP_default, Trest_current,
%            Trest_default, activation,[Terp_min,Terp_max],index_of_path_activate_the_node}
% path_ind: paths connecting to the node except the one activated the node
% term_ind: which terminal the node connecting to the paths(1 or 2)
%
% Outputs:
% The same as inputs, just updated values.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#include "math.h"
#include "stdio.h"
void node_automatron_complex(int* node_para,int* path_ind,int** path_table,int max_connections)
{
	float ratio;
	float factor;
	
	node_para[10]=0; //act_path=0
	
	if(node_para[9]) //act_node==1
	{
		node_para[9]=0; //act_node=0
		switch(node_para[0]) //node_state
		{
			case 1: //Rest
				node_para[10]=1; //act_path=1
				node_para[2]=node_para[8]; //ERP_def=ERP_max;
				node_para[1]=node_para[8]; //ERP_cur=ERP_def;
				
				for(int i=0;(path_ind[i]>-1)&&(i<max_connections);i++)
				{
					path_table[path_ind[i]][3]=path_table[path_ind[i]][7]; //path_table{path_ind(i),5}=path_table{path_ind(i),9};
					path_table[path_ind[i]][4]=path_table[path_ind[i]][7];
					path_table[path_ind[i]][5]=path_table[path_ind[i]][7];
					path_table[path_ind[i]][6]=path_table[path_ind[i]][7];
				}
				node_para[5]=node_para[6]; //Rest_cur=Rest_def;
				node_para[0]=2;
				//printf("case 1 done\n");
				break;
			case 2: //ERP
				node_para[2]=node_para[7]; //ERP_def=ERP_min;
				node_para[1]=node_para[7]; //ERP_cur=ERP_def;
				break;
			case 3: //RRP
				node_para[10]=1; //act_path=1;
				ratio=(float)node_para[3]/node_para[4]; //ratio=RRP_cur/RRP_def;
				//printf("%d,%d,%f\t",node_para[3],node_para[4],ratio);
				
				if(node_para[11]==1) //node_type=='AV'
				{
					node_para[2]=node_para[8]+(1.0-pow((1-ratio),3))*(float)(node_para[7]-node_para[8]);
					factor=(1.0+ratio*3);
				}
				else
				{
					node_para[2]=node_para[7]+(1.0-pow(ratio,3))*(float)(node_para[8]-node_para[7]);
					factor=(1.0+pow(ratio,2)*3);
				}
				
				node_para[1]=node_para[2]; //ERP_cur=ERP_def;
				
				for(int i=0;(path_ind[i]>-1)&&(i<max_connections);i++)
				{
					path_table[path_ind[i]][3]=(float)path_table[path_ind[i]][7]*factor;
					path_table[path_ind[i]][4]=path_table[path_ind[i]][3];
					path_table[path_ind[i]][5]=path_table[path_ind[i]][3];
					path_table[path_ind[i]][6]=path_table[path_ind[i]][3];
				}
				node_para[3]=node_para[4]; //RRP_cur=RRP_def;
				node_para[0]=2; //node_state
				//printf("%f\t%f\t%d\t%d\t%d\n",ratio,factor,node_para[2],node_para[7],node_para[8]);
				break;
		}
	}
	else
	{
		switch(node_para[0]) //node_state
		{
			case 1: //Rest
				if(node_para[5]) //not fully depolarized
				{
					node_para[5]--;
				}
				else
				{
					node_para[0]=2; //change state to ERP
					node_para[5]=node_para[6]; //Reset Rest timer
					node_para[10]=1; //act_path=1
				}
				break;
			case 2:// ERP
				if(node_para[1])
				{
					node_para[1]--;
				}
				else
				{
					node_para[0]=3;
					node_para[1]=node_para[2];
				}
				break;
			case 3: //Rest
				if(node_para[3])
				{
					node_para[3]--;
				}
				else
				{
					node_para[0]=1;
					node_para[3]=node_para[4];
				}
				break;
		}
	}	
}
