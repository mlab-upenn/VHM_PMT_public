function read_value=RPCRead(var_name,rows,cols)
    global RPC_struct
    %DO NOT USE fprintf HERE, IT WILL MODIFY THE DATA THAT WILL ACTUALLY BE
    %SENT TO THE RPI
    fwrite(RPC_struct.udp_handle,['r,',var_name,',',num2str(rows),',',num2str(cols)]);
    temp_value=fscanf(RPC_struct.udp_handle);
    if(temp_value(1)=='E')
        disp('ERROR reading variable');
    else
        temp_value=str2double(strsplit(temp_value,','));
        read_value=zeros(rows,cols);
        for i=1:rows,
            for j=1:cols,
                read_value(i,j)=temp_value((i-1)*cols+j);
            end
        end
    end
end