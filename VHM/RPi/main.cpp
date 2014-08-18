/*********DATA ENCODING LOGIC***********
*****Node activation data encoding procedure*****
The node activation value for each node can be either 0 or 1 so
one bit is sufficient to encode this data. A variable,node_activation_status, accumulates
the node activation data for all nodes bit by bit with LSB containing the data for the first node

*****Path and Node status encoding procedure*****
Even though there are 5 possible values for the path status, only 3 are required for monitoring purposes,
these three values can be encoded into 2 bits. The variable paths_status hold the paths' status with the LSB and 
the next higher bit corresponding to the first path
Similar logic is followed to encode the Nodes' state and stored in nodes_status
****/
#include "arpa/inet.h"
#include "errno.h"
#include "heart_model.h"
#include <iostream>
#include "limits.h"
#include "netdb.h"
#include "netinet/in.h"
#include "node_automatron_complex.h"
#include "node_automatron_simple.h"
#include "periodic_trigger.h"
#include "path_automatron_complex.h"
#include "path_automatron_simple.h"
#include "pthread.h"
#include "signal.h"
#include "stdlib.h"
#include "stdio.h"
#include "string.h"
#include "sys/time.h"
#include "sys/types.h"
#include "sys/socket.h"
#include "time.h"
#include "unistd.h"
#include "wiringPi.h"
#include "wiringSerial.h"
#define PERIOD 1000		//Scheduling period in micro seconds
#define LOG_SIZE 1000
#define MYPORT "4950" // the port users will be connecting to
#define MAXBUFLEN 2000 
#define ASENSE_PIN 0  		//GPIO0 pin
#define VSENSE_PIN 1  		//GPIO1 pin
#define NODE_1_PIN 3
 		//GPIO3 pin
#define NODE_LAST_PIN 4
 	//GPIO4 pin
#define MEAS_PIN1 2  		//GPIO2 pin
#define MEAS_PIN2 5 		//GPIO5 pin
#define MAX_NODES 34
#define MAX_PATHS 35
#define MAX_NX_COLS 12
#define MAX_PX_COLS 8
#define TRANSMISSION_DELAY 50000  //in microseconds
using namespace std;
inline void displayAndLogData(char option);//function made inline mainly to increase execution speed in the heart interrupt routine
int updateTable(char option);//function to update the node and path table upon request through serial communication
int** makeTable(char row, char column);
void freeTable(int** pointer,char row);//routine to free the memory allocated to 2d integer pointers
void loadTable();//this routine populates the node table and the path table with the default values
void heart_scheduler(int sig);//wrapper function that in turn calls the heart model every 1ms
void node1_pacer(void);//wrapper function to pace the first node by making the node activation signal for the node as 1
void node_last_pacer(void);//wrapper function to pace the last node in the same way as the previous function
void* communicator(void* arg);
void startHeart(void);
void stopHeart(void);
void clearLog(void);
void change_mode(int);
void populateConnectivity();
timespec time_diff(timespec start,timespec end);

char nx = 4;
char ny = 7;
char px = 3;
char py = 7;
int max_connections;
int** node_table = makeTable(MAX_NODES,MAX_NX_COLS);
int activation_column[MAX_NODES];
int** path_table = makeTable(MAX_PATHS,MAX_PX_COLS);
int** paths_to_each_node=makeTable(MAX_NODES,MAX_PATHS);
int** trigger_table=makeTable(MAX_NODES,CURRENT_TIME_TO_PACE_COL+1);
size_t node_activation_status,prev_node_activation_status=0;//variables which store the 6th column of the node table and transmit upon change
size_t nodes_status,prev_nodes_status=0;//variables which encode the nodes' states for transmission
size_t paths_status,prev_paths_status=0;//variables to store the paths' states for transmission
int sch_activation=0;//regular activation is enabled when sch_activation is 1
volatile char connection_lost=0;
volatile int factor=1;
int mode=0;
int node_activation_index=5;
int path_activation_index=6;
int node_paced=-1;
struct heart_state{
	size_t activation_data;
	size_t node_state;
	size_t path_state;
	size_t time_in_millis;
} activation_history[LOG_SIZE];
size_t run_count=0,current_index=0;//overflow of run_count is acknowledged
long double LastA, LastV;//variables to record the time at which latest A event or V event occured
volatile int ready_to_receive=0,printed=0;
struct itimerval it;
struct timeval timeout={10,0};
struct timespec stopwatch,startwatch;
size_t highest_execution_time;
pthread_t communicator_thread;
pthread_mutex_t pace_lock=PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t a_mutex=PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t wake_up=PTHREAD_COND_INITIALIZER;
void (*node_automatron)(int*,int*,int**,int);
void (*path_automatron)(int*,int*);
//UDP related variables
	int sockfd;
	struct addrinfo hints, *servinfo, *p;
	int rv;
	int numbytes;
	struct sockaddr_storage their_addr;
	char buf[MAXBUFLEN];
	socklen_t addr_len;
	char s[INET6_ADDRSTRLEN];
//UDP related variables	

int main()
{
	wiringPiSetup();
	system("gpio edge 3 falling");//to set the NODE_1_PIN as falling edge triggered pin
	system("gpio edge 4 falling");//to set the NODE_LAST_PIN as falling edge triggered pin
	pinMode(NODE_1_PIN,INPUT);//make the pin as input
	pinMode(NODE_LAST_PIN,INPUT);
	pinMode(ASENSE_PIN,OUTPUT);
	pinMode(VSENSE_PIN,OUTPUT);
	pullUpDnControl(ASENSE_PIN,PUD_DOWN);
	pullUpDnControl(VSENSE_PIN,PUD_DOWN);
	pullUpDnControl(NODE_1_PIN,PUD_DOWN);//pull down the pin to ground when not driven
	pullUpDnControl(NODE_LAST_PIN,PUD_DOWN);
	if(wiringPiISR(NODE_1_PIN,INT_EDGE_FALLING,&node1_pacer)<0)
	{
		fprintf(stderr,"Unable to setup ISR for pin NODE_1_PIN");
		return 1;
	}
	if(wiringPiISR(NODE_LAST_PIN,INT_EDGE_FALLING,&node_last_pacer)<0)
	{
		fprintf(stderr,"Unable to setup ISR for pin NODE_LAST_PIN");
		return 1;
	}
	pinMode(MEAS_PIN1,OUTPUT);
	pinMode(MEAS_PIN2,OUTPUT);
	loadTable();//load default values to start heart execution
	change_mode(mode);
	signal(SIGALRM,&heart_scheduler);
	startHeart();
	int err;
	err=pthread_create(&communicator_thread, NULL, &communicator, NULL);
	if(err!=0)
	{
		printf("communicator not scheduled, thread creation error");
		exit(0);
	}
	while(1)//infinite while loop
	{
		char receive_buf[10];
		memset(receive_buf,0,10);
		while(ready_to_receive==0);
		if((numbytes = recvfrom(sockfd, receive_buf, 10 , 0,
		(struct sockaddr *)&their_addr, &addr_len))<0) {
			continue;
		}
		if(strncmp(receive_buf,"s",1)==0)
		{
			factor=atoi(receive_buf+1);
			startHeart();
		}
		else if(strncmp(receive_buf,"e",1)==0)
		{
			pthread_mutex_lock(&pace_lock);
			node_paced=atoi(receive_buf+1);
			pthread_mutex_unlock(&pace_lock);
		}
		else if(strncmp(receive_buf,"p",1)==0)
		{
			sch_activation=1;
		}		
		else if(strncmp(receive_buf,"u",1)==0)
		{
			stopHeart();			
			sleep(1);
			clearLog();
			updateTable(0);
			startHeart();
		}
		else if(strncmp(receive_buf,"l",1)==0)
		{
			stopHeart();
			sleep(1);
			timeout.tv_sec=0;
			if(setsockopt(sockfd,SOL_SOCKET,SO_RCVTIMEO,&timeout,sizeof(timeout))<0){
				perror("setsockopt");
			}
			memset(buf,0,MAXBUFLEN);
			char temp_string[6];
			for(int i=current_index+1;i!=current_index;i=(i+1)%LOG_SIZE)
			{
				sprintf(temp_string,"\r%4d",i);
				write(1,temp_string,strlen(temp_string));
				if((numbytes = recvfrom(sockfd, receive_buf, 10 , 0,
					(struct sockaddr *)&their_addr, &addr_len))<0) {
					break;
				}
				memset(buf,0,MAXBUFLEN);
				sprintf(buf,"%ld,%ld,%ld,%ld\n\r",activation_history[i].activation_data,activation_history[i].node_state,activation_history[i].path_state,activation_history[i].time_in_millis);
				//printf("%s",buf);
				if ((numbytes = sendto(sockfd,buf, strlen(buf), 0,
				(struct sockaddr *)&their_addr, addr_len)) == -1) {
					perror("talker: sendto");
				}
			}
			if ((numbytes = sendto(sockfd,"end\n\r", strlen("end\n\r"), 0,
				(struct sockaddr *)&their_addr, addr_len)) == -1) {
					perror("talker: sendto");
			}
			timeout.tv_sec=10;
			if(setsockopt(sockfd,SOL_SOCKET,SO_RCVTIMEO,&timeout,sizeof(timeout))<0){
				perror("setsockopt");
			}startHeart();
		}
		else if(strncmp(receive_buf,"t",1)==0)
		{
			stopHeart();
			sleep(1);
			updateTable(1);
			for(char i=0;i<nx;i++)
			{
				for(char j=0;j<=CURRENT_TIME_TO_PACE_COL;j++)
				{
					printf("%d\t",trigger_table[i][j]);
				}
				printf("\n");
			}
			printf("table created\n");
			for(int i=0;i<nx;i++)
			{
				trigger_table[i][PACE_COUNT_COL]=0;
				trigger_table[i][CURRENT_TIME_TO_PACE_COL]=-2;
			}
			startHeart();
		}	
			
	}
}

void heart_scheduler(int sig)//periodic function to call the heart model every 1ms
{
	digitalWrite(MEAS_PIN1,HIGH);
	//clock_gettime(CLOCK_REALTIME,&startwatch);
	pthread_mutex_lock(&pace_lock);
	if(node_paced>=0){
		activation_column[node_paced]|=1;		
		node_paced=-1;
	}
	pthread_mutex_unlock(&pace_lock);
	for(int i=0;i<nx;i++)
	{
		node_table[i][5+mode*4]=activation_column[i];
	}
	heart_model(node_table,nx,path_table,px,paths_to_each_node,max_connections,node_automatron,path_automatron,mode);//heart_model function to update the table every 1ms
	for(int i=0;i<nx;i++)
	{
		activation_column[i]=node_table[i][5+mode*4];
		node_table[i][5+mode*4]|=node_table[i][6+mode*4];
	}
	if(sch_activation==1)
	{
		periodic_trigger(node_table,activation_column,trigger_table,nx,&sch_activation,mode);
		if(sch_activation==0)
		{
			for(int i=0;i<nx;i++)
			{
				trigger_table[i][PACE_COUNT_COL]=0;
				trigger_table[i][CURRENT_TIME_TO_PACE_COL]=-2;
			}
		}
	}
	digitalWrite(ASENSE_PIN,node_table[0][5+mode*4]);
	digitalWrite(VSENSE_PIN,node_table[nx-1][5+mode*4]);
	displayAndLogData(0);
	//printf("%ld\n",run_count);
	run_count++;
	//clock_gettime(CLOCK_REALTIME,&stopwatch);
	/*size_t this_time=time_diff(startwatch,stopwatch).tv_nsec;
	if(this_time>highest_execution_time)
	{
		highest_execution_time=this_time;
		cout<<highest_execution_time<<endl;
	}*/
	digitalWrite(MEAS_PIN1,LOW);
}

void node1_pacer(void)//this function is called when the first node of the heart is paced
{
	pthread_mutex_lock(&pace_lock);
	node_paced=0;
	pthread_mutex_unlock(&pace_lock);
	//node_table[0][5+mode*4]|=1;//activate the first node
	//trigger_table[1][0]=trigger_table[2][0];//load fresh values to start another countdown whenever the node is activated
	//displayAndLogData(1);
}

void node_last_pacer(void)//this function is called upon a pacing signal to the last node of the heart
{
	pthread_mutex_lock(&pace_lock);
	node_paced=nx-1;
	pthread_mutex_unlock(&pace_lock);
	//node_table[nx-1][5+mode*4]|=1;//activate the last node
	//trigger_table[1][nx-1]=trigger_table[2][nx-1];//load fresh values to start another countdown whenever the node is activated
	//displayAndLogData(1);
}

void* communicator(void* arg){
	memset(&hints, 0, sizeof hints);
	hints.ai_family = AF_UNSPEC; // set to AF_INET to force IPv4
	hints.ai_socktype = SOCK_DGRAM;
	hints.ai_flags = AI_PASSIVE; // use my IP
	if ((rv = getaddrinfo(NULL, MYPORT, &hints, &servinfo)) != 0) {
		fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
		exit(0);
	}
	// loop through all the results and bind to the first we can
	for(p = servinfo; p != NULL; p = p->ai_next) {
		if ((sockfd = socket(p->ai_family, p->ai_socktype,
			p->ai_protocol)) == -1) {
			perror("listener: socket");
			continue;
		}
		if (bind(sockfd, p->ai_addr, p->ai_addrlen) == -1) {
			close(sockfd);
			perror("listener: bind");
			continue;
		}
		break;
	}
	if (p == NULL) {
		fprintf(stderr, "listener: failed to bind socket\n");
		exit(0);
	}
	freeaddrinfo(servinfo);
	if(setsockopt(sockfd,SOL_SOCKET,SO_RCVTIMEO,&timeout,sizeof(timeout))<0){
		perror("setsockopt");
	}
	printf("waiting for client...\n");
	addr_len = sizeof their_addr;
	while(1)
	{
		if ((numbytes = recvfrom(sockfd, buf, MAXBUFLEN-1 , 0,
		(struct sockaddr *)&their_addr, &addr_len))<0) {
			continue;
		}
		ready_to_receive=1;
		while(1){	
			int rc=pthread_mutex_lock(&a_mutex);
			if(rc)
			{
				perror("pthread_mutex_lock");
				pthread_exit(NULL);
			}
			printed=0;
			rc=pthread_cond_wait(&wake_up,&a_mutex);
			printed=1;
			digitalWrite(MEAS_PIN2,HIGH);	
			sprintf(buf,"%ld,%ld,%ld,%ld\n\r",prev_node_activation_status,prev_nodes_status,prev_paths_status,run_count);
			if ((numbytes = sendto(sockfd,buf, strlen(buf), 0,
			(struct sockaddr *)&their_addr, addr_len)) == -1) {
				perror("");
				printed=0;
				ready_to_receive=0;
				break;
			}
			digitalWrite(MEAS_PIN2,LOW);
			pthread_mutex_unlock(&a_mutex);
		}
	}
	close(sockfd);
}

inline void log_data()
{
	current_index=run_count%LOG_SIZE;
	//activation_history[current_index]=prev_node_activation_status;    
}

void clearLog(void)
{
	for(int i=0;i<LOG_SIZE;i++)
	{
		activation_history[i].activation_data=0;
		activation_history[i].node_state=0;
		activation_history[i].path_state=0;
		activation_history[i].time_in_millis=0;	
	}
}

inline void displayAndLogData(char option)
{
	//initialize status values to zero so that first multiplication operation won't change these variables
	node_activation_status=0;
	nodes_status=0;
	paths_status=0;
	for(char i=0;(i<nx);i++)//combined 'for' loop to populate data from both the node table and the path table
	{
		//one bit of node_activation_status used for indication of each node's activation value, first node's data is the lowest bit
		node_activation_status=node_activation_status<<1;//multiplication by 2 has the effect of right shift, right shift is not allowed on float values, hence this workaround
		//two bits of nodes_status for every node's state, the first node's data is the lowest two bits
		nodes_status=nodes_status<<2;
		node_activation_status|=node_table[nx-i-1][5+mode*4];//stuff last node first to get the first node's data in the least significant position
		nodes_status|=(node_table[nx-i-1][0]-1);//stuff last node first for same reasons as previous operation,'or' operation could have yielded faster results but restricted to use '+' because of data type
	}
	for(char i=0;(i<px);i++)
	{
		//two bits per path for state information recording
		paths_status=paths_status<<2;
		paths_status|=path_table[px-i-1][0]>4?0:(path_table[px-i-1][0]-1);//last path's information first to get the first path's information in the least significant position
	}
	if((prev_paths_status!=paths_status)||(prev_nodes_status!=nodes_status)||(prev_node_activation_status!=node_activation_status))
	{
		prev_node_activation_status=node_activation_status;
		prev_nodes_status=nodes_status;
		prev_paths_status=paths_status;
		activation_history[current_index].activation_data=node_activation_status;
		activation_history[current_index].node_state=nodes_status;
		activation_history[current_index].path_state=paths_status;
		activation_history[current_index].time_in_millis=run_count;
		pthread_cond_signal(&wake_up);
		//while(printed==1);  //This line makes this thread wait till the communicator has finished execution
//wait for the communicator thread to finish sending the data
		current_index=(current_index+1)%LOG_SIZE;
	}
}

int updateTable(char option)
{
	//These variables are limited to only this code
	char temp_char=0,no_of_rows=0,no_of_cols=0,table_no=0;
	int buffer=0,no_of_cmas=0,char_count=0;
	printf("Enter new table data, previous mode was %d\n",mode);
	if ((numbytes = recvfrom(sockfd, buf, MAXBUFLEN-1, 0,
		(struct sockaddr *)&their_addr, &addr_len))<0) {
		perror("recvfrom");
		return 2;
	}
	printf("%s\n",buf);
	while(buf[char_count]!='\0')//keep running the loop till exited upon encounter of character 'z' in the data stream
	{
		temp_char=buf[char_count];
		char_count++;
		if((temp_char>='0')&&(temp_char<='9')) {//if numbers are encountered, build up the numbers till a ',' is encountered
			buffer*=10;
			buffer+=(temp_char-'0');
		}
		else if(temp_char==',') 
		{//used to indicate new values in the stream
			if(no_of_cmas<2)//first two numbers seperated by commas are the number of rows and columns in each table
			{
				if(no_of_cmas==0)
				{
					no_of_rows=buffer;//first number is the number of rows of the new table
				}
				else if(no_of_cmas==1)
				{
					no_of_cols=buffer;//second number is the number of columns in the new table, even though fixed at 7, included for symmetry
					if(table_no==0)
					{
						//node_table=makeTable(no_of_rows,no_of_cols);//create a table based on the new row and column counts for node_table
						nx=no_of_rows;
						ny=no_of_cols;
						mode=(ny==12);
						printf("Mode is %d\n",mode);
					}
					else
					{
						//path_table=makeTable(no_of_rows,no_of_cols);//create a table based on the new row and column counts for the path table
						px=no_of_rows;
						py=no_of_cols;
						if(mode && py==7) return 1;
					}
					
				}
			}
			if(no_of_cmas>=2)
			{
				if(option==0)//option=0 corresponds to update of node and path table, option=1 corresponds to update of trigger	table
				{
					if(table_no==0)
					{
						node_table[(no_of_cmas-2)/ny][(no_of_cmas-2)%ny]=buffer;//assign the values to appropriate elements in the node table
					}
					else
					{
						path_table[(no_of_cmas-2)/py][(no_of_cmas-2)%py]=buffer;//assign the values to appropriate elements in the path table
					}
				}
				else
				{
					if(table_no==0)
					{
						trigger_table[(no_of_cmas-2)/PACE_COUNT_COL][(no_of_cmas-2)%PACE_COUNT_COL]=buffer;
					}
				}
			}
			no_of_cmas++;//increment the number of commas encountered
			buffer=0;//clear buffer upon every comma to build up new number
		}
		else if(temp_char=='x')// 'x' seperates the node table from the path table
		{
			//reset required values in preparation of next table population
			no_of_rows=0;
			no_of_cols=0;
			no_of_cmas=-1;
			table_no=1;
		}
		else if(temp_char=='z')
		{
			char count_buf[5];
			printf("%d\n",char_count);
			sprintf(count_buf,"%d\n\r",char_count);
			if ((numbytes = sendto(sockfd,count_buf, strlen(count_buf), 0,
				(struct sockaddr *)&their_addr, addr_len)) == -1) {
				perror("talker: sendto");
			}
			break;//exit from the tables updation loop
		}
	}//end of while(1) loop
	//displayData(0);
	change_mode(mode);
	return 0;
}

int** makeTable(char row, char column)
{
	int** theArray;
	theArray = (int**) malloc(row*sizeof(int*));
	for (char i = 0; i < row; i++)
	{
		theArray[i] = (int*) calloc(column,sizeof(int));
		//memset(theArray[i],0,column);
	}
	if(theArray==NULL)
	{
		printf("Not enough memory\n\r");//if not able to allocate memory
		exit(1);
	}
	return theArray;

}

void freeTable(int** pointer,char row)
{
	for(char i=0;i<row;i++)
	{
		free(pointer[i]);
		pointer[i]=NULL;
	}
	free(pointer);
	pointer=NULL;
}

/* NOTE: indices have to be checked...
 path has to less than no. of rows*/
void loadTable()//function to load the default values to the variables
{
     node_table[0][0] = 1; node_table[0][1] = 131; node_table[0][2] = 220; node_table[0][3] = 700; node_table[0][4] = 700; node_table[0][5] = 0; node_table[0][6] = 0;
     node_table[1][0] = 1; node_table[1][1] = 320; node_table[1][2] = 400; node_table[1][3] = 9209; node_table[1][4] = 9999; node_table[1][5] = 0; node_table[1][6] = 0;
     node_table[2][0] = 1; node_table[2][1] = 320; node_table[2][2] = 350; node_table[2][3] = 9209; node_table[2][4] = 9999; node_table[2][5] = 0; node_table[2][6] = 0;
     node_table[3][0] = 1; node_table[3][1] = 320; node_table[3][2] = 450; node_table[3][3] = 9209; node_table[3][4] = 9999; node_table[3][5] = 0; node_table[3][6] = 0;

     path_table[0][0] = 1; path_table[0][1] = 0; path_table[0][2] = 1; path_table[0][3] = 57; path_table[0][4] = 57; path_table[0][5] = 29; path_table[0][6] = 57;
     path_table[1][0] = 1; path_table[1][1] = 1; path_table[1][2] = 2; path_table[1][3] = 57; path_table[1][4] = 85; path_table[1][5] = 85; path_table[1][6] = 85;
     path_table[2][0] = 1; path_table[2][1] = 2; path_table[2][2] = 3; path_table[2][3] = 57; path_table[2][4] = 85; path_table[2][5] = 85; path_table[2][6] = 85;

}

void startHeart(void)
{
	it.it_interval.tv_sec=0;
	it.it_interval.tv_usec=PERIOD*factor;
	it.it_value.tv_sec=1;
	it.it_value.tv_usec=0;
	setitimer(ITIMER_REAL,&it,NULL);
}

void stopHeart(void)
{
	
	it.it_interval.tv_sec=0;
	it.it_interval.tv_usec=0;
	it.it_value.tv_sec=0;
	it.it_value.tv_usec=0;
	setitimer(ITIMER_REAL,&it,NULL);
}

void change_mode(int mode)
{
	node_automatron=mode?&node_automatron_complex:&node_automatron_simple;
	path_automatron=mode?&path_automatron_complex:&path_automatron_simple;
	if(mode) populateConnectivity();
}
	

void populateConnectivity()
{
	int i;
	int j;
	int index;
	max_connections=0;
	for(i=0;i<nx;i++)
	{
		index=0;
		for(j=0;j<px;j++)
		{
			if(path_table[j][1]==i||path_table[j][2]==i)
			{
				index++;
				if(index>max_connections) max_connections=index;
 
			}
		}
	}

	//paths_to_each_node=makeTable(nx,max_connections);

	for(i=0;i<nx;i++)
	{
		index=0;
		for(j=0;j<px;j++)
		{
			if(j<max_connections) paths_to_each_node[i][j]=-1;
			if(path_table[j][1]==i||path_table[j][2]==i) paths_to_each_node[i][index++]=j;
		}
	}
}


timespec time_diff(timespec start,timespec end){
	timespec temp;
	if((end.tv_nsec-start.tv_nsec)<0){
		temp.tv_sec=end.tv_sec-start.tv_sec-1;
		temp.tv_nsec=1000000000+end.tv_nsec-start.tv_nsec;
	}
	else
	{
		temp.tv_sec=end.tv_sec-start.tv_sec;
		temp.tv_nsec=end.tv_nsec-start.tv_nsec;
	}
	return temp;
}
