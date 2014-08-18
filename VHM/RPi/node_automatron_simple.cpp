/*This function updates the status of the different nodes and triggers signals
on appropriate paths*/
void node_automatron_simple(int* node_para,int* path_ind,int** path_table,int max_connections)
{
    char temp_act = 0;
    char temp_path = 0;
    char state = (char)node_para[0];
    if(node_para[5] == 1)//if node is activated
    {
        switch(state) //state
        {
            case 1: //Rest
            {
                //Reset ERP
                node_para[1]= node_para[2];
                //activate path
                temp_path = 1;
                //reset trest
                node_para[3]= node_para[4];
                //change state to ERP
                node_para[0]= 2;
                break;
            }
            case 2: //ERP
            {
                //RESET TERP
                node_para[1]= node_para[2];
                break;
            }
        }
    }
    else
    {
        switch(state)
        {
            case 1:
            {
                if(node_para[3]== 0)
                {
                    //change state to ERP
                    node_para[0]= 2;
                    //reset trest timer
                    node_para[3]= node_para[4];
                    //printf("reset %d", node_para[3]);
                    //activate the node
                    temp_path = 1;
                    temp_act = 1;
                }
                else
                {
                    //timer
                    node_para[3]= node_para[3]- 1;
                   // printf("timer %d", node_para[3]);
                }
                break;
            }
            case 2:
            {
                if(node_para[1]==0)
                {
                    //change state to ERP
                    node_para[0]= 1;
                    //reset TERP timer
                    node_para[1]= node_para[2];
                }
                else
                {
                    //timer
                    node_para[1]= node_para[1]- 1;
                }
                break;
            }
        }
    }
    node_para[5] = temp_act;
    node_para[6] = temp_path;
}
