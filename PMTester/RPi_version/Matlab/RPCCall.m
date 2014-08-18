function RPCCall(function_name)
    global RPC_struct
    fwrite(RPC_struct.udp_handle,['c,',function_name]);
end