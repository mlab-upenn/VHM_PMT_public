function [node_para,path_table]=node_automatron(node_para,path_ind,path_table)
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
node_state=node_para{2};
ERP_cur=node_para{3};
ERP_def=node_para{4};
RRP_cur=node_para{5};
RRP_def=node_para{6};
Rest_cur=node_para{7};
Rest_def=node_para{8};
ERP_min=node_para{9}(1);
ERP_max=node_para{9}(2);

act_node=node_para{10};
node_type='NA';
if node_para{12}==1
    node_type='AV';
end

act_path=0;
% says whether path is activated
if act_node % if node is activated
    node_para{10}=0;
    switch node_state
        
        case 1 %Rest
           act_path=1;
           
                % set ERP to longest
                ERP_def=ERP_max;
                ERP_cur=ERP_def;
           
            
           
            % reset path conduction speed
            for i=1:length(path_ind)
                    path_table{path_ind(i),5}=path_table{path_ind(i),9};
                    path_table{path_ind(i),6}=path_table{path_ind(i),9};
                    path_table{path_ind(i),7}=path_table{path_ind(i),9};
                    path_table{path_ind(i),8}=path_table{path_ind(i),9};
            end
     
            
            % Reset Trest
            Rest_cur=Rest_def;
            % change state to ERP
            node_state=2;
        case 2 %ERP
         
            % set ERP to the lowest
            ERP_def=ERP_min;
            % reset TERP
            ERP_cur=ERP_def;
           
        case 3 %RRP
            act_path=1;
            % calculate the ratio of early activation
            ratio=RRP_cur/RRP_def;
           
            % calculate the ERP timer for the next round
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % don't get mad Paja, only AV node has different response
            % pattern. so just change the reaction function of node AV to
            % the first one
            if node_type=='AV'
                ERP_def=ERP_max+round(1-(1-ratio)^3)*(ERP_min-ERP_max);
            else
                ERP_def=ERP_min+round((1+(rand-0.5)*0)*(1-ratio^3)*(ERP_max-ERP_min));
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            ERP_cur=ERP_def;
            
      
            % change the conduction speed of connecting path
            for i=1:length(path_ind)
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % same here, only AV node has faster trend
                if node_type=='AV'
                   
                        path_table{path_ind(i),6}=round(path_table{path_ind(i),9}*(1+ratio*3));
                        path_table{path_ind(i),5}=path_table{path_ind(i),6};
                        path_table{path_ind(i),7}=path_table{path_ind(i),6};
                        path_table{path_ind(i),8}=path_table{path_ind(i),6};
                else
                        path_table{path_ind(i),6}=round(path_table{path_ind(i),9}*(1+ratio^2*3));
                        path_table{path_ind(i),5}=path_table{path_ind(i),6};
                        path_table{path_ind(i),7}=path_table{path_ind(i),6};
                        path_table{path_ind(i),8}=path_table{path_ind(i),6};
                    
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
              
            end
            
           
            
            % reset TRRP
            RRP_cur=RRP_def;
            % change state to ERP
            node_state=2;
    end
   
else % if node is not activated
    switch node_state
        case 1 %Rest
            if Rest_cur==0 % self depolarize
                % change state to ERP
                node_state=2;
                % reset Trest timer
                Rest_cur=Rest_def;
                % activate the node
                act_path=1;
            else
                % timer
                Rest_cur=Rest_cur-1;
            end
            % maintains periodicity of SA node
        case 2 %ERP
            if ERP_cur==0 %timer running out
                % change state to RRP
                node_state=3;
                % reset TERP timer
                ERP_cur=ERP_def;
            else
                % timer
                ERP_cur=ERP_cur-1;
            end
            % keeps reducing timer during ERP until it hits zero; then
            % change to RRP
        case 3 % RRP
            if RRP_cur==0 % timer running out
                % change state to rest
                node_state=1;
                % reset TRRP timer
                RRP_cur=RRP_def;
            else
                % timer
                RRP_cur=RRP_cur-1;
            end
            % keep reducing RRP until you get to zero, then change to rest
            % state
    end
end
%--------------------------------------
node_para{2}=node_state;
node_para{3}=ERP_cur;
node_para{4}=ERP_def;
node_para{5}=RRP_cur;
node_para{7}=Rest_cur;
node_para{11}=act_path;
%---------------------------------------
return