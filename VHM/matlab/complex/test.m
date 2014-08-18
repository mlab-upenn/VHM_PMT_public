%clear all
close all
load test
global Tpace
global t
global m_state
global lastSA
global lastAH
global lastHV
global Intrinsic
global slowpath
global AVNRT
global terminated
global pace_round
global A_slowed
global AV_slowed
% loading parameters of virtual heart model (VHM)
 clk=0;
 % global clock (one iteration represents 1 ms)
 data=[];
 % virtual electrogram that we want to print (matrix containing activation
 % state of each node
 % 1 = activated
 % 0 = inactivated
 Tpace=0;
 t=0;
 m_state='waitI1';
 lastSA=0;
 lastAH=0;
 lastHV=0;
 Intrinsic=0;
 slowpath=0;
 AVNRT=0;
 terminated=0;
 pace_round=0;
 A_slowed=0;
 AV_slowed=0;
 
 S1=330;
 cond=[];
 while clk<10000
     % run this algorithm for 3000 iterations (i.e. 3 seconds)
     clk=clk+1;
     Tpace=Tpace+1;
     t=t+1;
     
    if clk==3560
        1
    end
   
    if clk==1
        node_table{1,10}=1;
    end
    if ~terminated
         [pace,condition]=monitor(S1,node_table{1,11},node_table{2,10},node_table{6,10},node_table{7,10});
         if ~strcmp(condition,'R0')
             cond=[cond;{clk,condition}];
         end
    else
        break;
    end
    
     if pace
        node_table{1,10}=1;
    end
    data=[data,[node_table{1,11},node_table{2,10},node_table{4,10},node_table{7,10},node_table{3,4}]'];

    [node_table,path_table]=heart_model(node_table,path_table);
    
 end
 
 figure
 axes('nextplot','add');
 for i=1:4%size(data,1)
     plot(data(i,:)-i*1.5);
 end