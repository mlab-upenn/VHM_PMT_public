function [path_para,temp_act_1,temp_act_2]=path_automatron(path_para,node_act_1,node_act_2)
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

path_state=path_para{2};
ante_cur=path_para{5};
ante_def=path_para{6};
retro_cur=path_para{7};
retro_def=path_para{8};
% naming path parameters
persistent conflict_cur
conflict_def=2;
% 2 ms delay to make sure path doesn't backfire
temp_act_1=0;
temp_act_2=0;
% variables that state whether paths will activate nodes
switch path_state
    case 1 % Idle--no conduction along path in EITHER direction
        % if activation coming from entry node
        if node_act_1
            % Antegrade conduction
            path_state=2;
        % if activation coming from exit node (and in IDLE state!!)
        else if node_act_2
                % Retrograde conduction
                path_state=3;
            end
        end
    case 2 % Antegrade conduction
        % if activation coming from exit node
        if node_act_2
            % double
            path_state=5;
        else
            % if timer running out
            if ante_cur==0
                % reset timer
                ante_cur=ante_def;
                % activate exit node (says that signal arrived)
                temp_act_2=1;
                % go to conflict state to make sure path doesn't backfire
                path_state=4;
                conflict_cur=0;
            else
                % timer counting down (i.e. signal traveling down path)
                ante_cur=ante_cur-1;
            end
        end
            
    case 3 % Retro (same thing except other way around)
        % if activation coming from entry node
        if node_act_1
            % conflict
            path_state=5;
%             
        else
            % if timer runs out
            if retro_cur==0
                % reset timer
                retro_cur=retro_def;
                % activate the entry node
                temp_act_1=1;
                % change state to conflict
                path_state=4;
                conflict_cur=0;
            else
                % timer
                retro_cur=retro_cur-1;
            end
        end
    case 4 % Conflict
        if conflict_cur>conflict_def
            % go to Idle state
            path_state=1;
        else
            conflict_cur=conflict_cur+1;
        end
    case 5 % double
               
%         if retro_cur==0
%                 % reset timer
%                 retro_cur=retro_def;
%                 % activate the entry node
%                 temp_act_1=1;
%                 % change state to conflict
%                 path_state=2;
%                 return
%         end
%         if ante_cur==0
%                 % reset timer
%                 ante_cur=ante_def;
%                 % activate exit node
%                 temp_act_2=1;
%                 % go to conflict state
%                 path_state=3;
%                 return
%         end
%         if abs(1-ante_cur/ante_def-retro_cur/retro_def)<0.9/min([ante_def,retro_def])
%                 retro_cur=retro_def;
%                 ante_cur=ante_def;
%                 path_state=4;
%                 
%         else
%             
%             ante_cur=ante_cur-1;
%             retro_cur=retro_cur-1;
%         end
        path_state=4;
        % state 4 says that there is a conflict in the path (two signals in
        % opposite directions)
        % state 5 says that both nodes are activated
        conflict_cur=0;
end

path_para{2}=path_state;
path_para{5}=ante_cur;
path_para{7}=retro_cur;
