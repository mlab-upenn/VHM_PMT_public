function RPCClose()
    global RPC_struct
    fclose(RPC_struct.udp_handle);
end