function [path_para,temp_act_1,temp_act_2]=path_automatron(path_para,node_act_1,node_act_2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function update the status of a single path
%
% Inputs:
% path_para: Cell array, parameters for the paths
%
%            format: {,path_state_index, entry_node_index,
%            exit_node_index,forward_timer_current, forward_timer_default,
%            backward_timer_current, backward_timer_default}
% node_act_1: boolean, activation status of the entry node
% node_act_2: boolean, activation status of the exit node
%
% Outputs:
% temp_act_1: boolean, local temporary node activation of the entry node
% temp_act_2: boolean, local temporary node activation of the exit node
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

temp_act_1=0;
temp_act_2=0;
switch path_para{1}
    case 1 % Idle
        % if activation coming from entry node
        if node_act_1
            % Antegrade conduction
            path_para{1}=2;
        % if activation coming from exit node
        else if node_act_2
                % Retrograde conduction
                path_para{1}=3;
            end
        end
    case 2 % Antegrade conduction
        % if activation coming from exit node
        if node_act_2
            % double
            path_para{1}=4;
%             % reset timer
%             path_para{8}=path_para{9};
        else
            % if timer running out
            if path_para{4}==0
                % reset timer
                path_para{4}=path_para{5};
                % activate exit node
                temp_act_2=1;
                % go to conflict state
                path_para{1}=4;
            else
                % timer
                path_para{4}=path_para{4}-1;
            end
        end
            
    case 3 % Retro
        % if activation coming from entry node
        if node_act_1
            % conflict
            path_para{1}=4;
        else
            % if timer runs out
            if path_para{6}==0
                % reset timer
                path_para{6}=path_para{7};
                % activate the entry node
                temp_act_1=1;
                % change state to conflict
                path_para{1}=4;
            else
                % timer
                path_para{6}=path_para{6}-1;
            end
        end
    case 4 % Conflict
        % use state 5 to delay 2ms
        path_para{1}=5;
    case 5
        path_para{1}=1;
        
end

