function RPCWrite(var_name,value)
    global RPC_struct
    %DO NOT USE fprintf HERE, IT WILL RUIN THE DATA THAT WILL ACTUALLY BE
    %SENT TO THE RPI
    data=['w,',var_name,',',num2str(size(value,1)),',',num2str(size(value,2))];
    for i=1:size(value,1),
        for j=1:size(value,2),
            data=[data,',',num2str(value(i,j))];
        end
    end
    fwrite(RPC_struct.udp_handle,data);
end
    
