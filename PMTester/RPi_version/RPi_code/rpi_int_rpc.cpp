#include <iostream>
#include <vector>
#include <string>
#include <map>
#include <arpa/inet.h>
#include <errno.h>
#include <netdb.h>
#include <netinet/in.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#define PORT 9999
#define MAX_DATA_LEN 1000

using namespace std;
extern int testData[20][3];
extern int nr;
extern int rows;
extern int created;
static map<string,void*> RPC_var_list;
static map<string,void(*)()> RPC_fcn_list;
static struct sockaddr_in si_me, si_other;
static int s, i, slen=sizeof(si_other);
char data[MAX_DATA_LEN];

void RPC_INT_Variable(void* var_ptr,string var_name);
void RPC_responder();
void RPC_VOID_Fcn(void(*fcn_ptr)(),string);

void initRPC(){
    if ((s=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP))==-1){
        perror("socket");
    }
    memset((char *) &si_me, 0, sizeof(si_me));
    si_me.sin_family = AF_INET;
    si_me.sin_port = htons(PORT);
    si_me.sin_addr.s_addr = htonl(INADDR_ANY);
    if (bind(s, (const sockaddr*)&si_me, sizeof(si_me))==-1){
        perror("bind");
    }
}

void createReport()
{
    printf("creating Report\n");
    int i;
    for(i = nr; i <rows; i++)
    {
        testData[i][2] = 0;
    }
    memset(data,0,MAX_DATA_LEN);
    for(i=0;i<rows;i++)
    {
    sprintf(data+strlen(data),"%d,%d,%d,",testData[i][0],testData[i][1],testData[i][2]);
    }
    sprintf(data+strlen(data)-1,"\n");
          //printf("%s\n",data);
    sendto(s,data,strlen(data),0,(const sockaddr*)&si_other, (socklen_t)slen);
    memset(data,0,MAX_DATA_LEN);
    created=1;
}

void RPC_INT_Variable(void* var_ptr,string var_name){
    RPC_var_list[var_name]=var_ptr;
}

void RPC_VOID_Fcn(void(*fcn_ptr)(),string fcn_name){
    RPC_fcn_list[fcn_name]=fcn_ptr;
}

void RPC_responder(){
    cout<<"waiting for connections..."<<endl;
    char delim=',';
    while(1){
        bool write_mode{false};
        memset(data,0,MAX_DATA_LEN);
        if(recvfrom(s, data, MAX_DATA_LEN , 0,
        (sockaddr*)&si_other, (socklen_t*)&slen)==-1) continue;
        vector<string> string_parts;
        char *str_piece;
        str_piece=strtok(data,&delim);
        while(str_piece!=nullptr){
        //printf("%s\n",str_piece);
            string_parts.push_back(str_piece);
            str_piece=strtok(NULL,&delim);
        }
        memset(data,0,MAX_DATA_LEN);
    if(string_parts[0]=="c"){
        if(RPC_fcn_list.find(string_parts[1])!=RPC_fcn_list.end()){
            RPC_fcn_list[string_parts[1]]();
            continue;
        }
        printf("function not called\n");
        continue;
    }
        if(string_parts[0]=="w") write_mode=true;
        if(RPC_var_list.find(string_parts[1])!=RPC_var_list.end()){
        int rows=atoi(string_parts[2].c_str());
        int cols=atoi(string_parts[3].c_str());
            if(write_mode){
          for(int i=0;i<rows;i++)
          {
            for(int j=0;j<cols;j++)
            {
                  //printf("%d\n",atoi(string_parts[4+i*cols+j].c_str()));
                  *((int*)RPC_var_list[string_parts[1]]+i*cols+j)=atoi(string_parts[4+i*cols+j].c_str());
            }
          }
        }
        else{
          for(int i=0;i<rows;i++)
          {
            for(int j=0;j<cols;j++)
            {
                              sprintf(data+strlen(data),"%d,",*((int*)RPC_var_list[string_parts[1]]+i*cols+j));
            }
          }
          sprintf(data+strlen(data)-1,"\n");
          //printf("%s\n",data);
                  sendto(s,data,strlen(data),0,(const sockaddr*)&si_other, (socklen_t)slen);
        }
        //printf("done\n");
    }
        else{
            cout<<"The variable searched for is not present"<<endl;
            sprintf(data,"ERROR\n");
            sendto(s,data,strlen(data),0,(const sockaddr*)&si_other, (socklen_t)slen);
        }
    }
}
