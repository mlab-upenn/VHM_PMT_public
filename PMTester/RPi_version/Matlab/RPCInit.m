function RPCInit(IP_address,Port_no)
    delete(instrfindall);
    delete(timerfindall);
    global RPC_struct
    RPC_struct=[];
    RPC_struct.udp_handle=udp(IP_address, Port_no, 'LocalPort', Port_no);
    set(RPC_struct.udp_handle,'DatagramTerminateMode','on');
    set(RPC_struct.udp_handle, 'ReadAsyncMode', 'continuous');
    fopen(RPC_struct.udp_handle);
end
    
