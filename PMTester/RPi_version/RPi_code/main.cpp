#include <iostream>
#include "limits.h"
#include <thread>
#include "signal.h"
#include "stdlib.h"
#include "stdio.h"
#include "string.h"
#include "sys/time.h"
#include "time.h"
#include "unistd.h"
#include "wiringPi.h"
#include "wiringSerial.h"
#define ASENSE_PIN 0        //GPIO0 pin
#define VSENSE_PIN 1        //GPIO1 pin
#define APACE_PIN 3         //GPIO3 pin
#define VPACE_PIN 4         //GPIO4 pin
#define ATRIAL_INPUT 1
#define VENTRICULAR_INPUT 2
#define ATRIAL_OUTPUT 3
#define VENTRICULAR_OUTPUT 4

using namespace std;
//MCU output values
int pass = 1;
int give = 0;

//matlab given variables
int e_time;
int event;
int tolerance_atrial; //given only once per test
int tolerance_ventrical; //given only once per test
int allowOffsets; //given only once per test
int initialized = 0; //initialization variable
int last_event_time;
int output;//reporting variable
int currTime;
int created=1;//variable to indicate that the report has already been created in this cycle
int nr = 0;
int rows=0;
int first_pace=1;
int testData[20][3];
//timer values
int offset = 0;
//****CHANGE ALL THESE*****
timespec t;
struct itimerval tick;
//*************************

void atrial_interrupt();
void ventricular_interrupt();
void showTest();
void resetTest();
void createReport();
void tester(int sig);
void initRPC();
void RPC_INT_Variable(void*,string);
void RPC_VOID_Fcn(void(*)(),string);
void RPC_responder();

void enable_interrupts(){
    wiringPiSetup();
    system("gpio edge 3 rising");
    system("gpio edge 4 rising");
    pinMode(APACE_PIN,INPUT);//make the pin as input
    pinMode(VPACE_PIN,INPUT);
    pinMode(ASENSE_PIN,OUTPUT);
    pinMode(VSENSE_PIN,OUTPUT);
    pullUpDnControl(ASENSE_PIN,PUD_DOWN);
    pullUpDnControl(VSENSE_PIN,PUD_DOWN);
    pullUpDnControl(APACE_PIN,PUD_DOWN);//pull down the pin to ground when not driven
    pullUpDnControl(VPACE_PIN,PUD_DOWN);
    if(wiringPiISR(APACE_PIN,INT_EDGE_RISING,&atrial_interrupt)<0)
    {
    fprintf(stderr,"Unable to setup ISR for pin APACE_PIN");
    exit(0);
    }
    if(wiringPiISR(VPACE_PIN,INT_EDGE_RISING,&ventricular_interrupt)<0)
    {
    fprintf(stderr,"Unable to setup ISR for pin VPACE_PIN");
    exit(0);
    }
}
void disable_interrupts(){
    system("gpio edge 3 none");
        system("gpio edge 4 none");
    pinMode(APACE_PIN,OUTPUT);//make the pin as input
        pinMode(VPACE_PIN,OUTPUT);
}

void showTest(){
    for(int i=0;i<20;i++)
    {
        for(int j=0;j<3;j++)
        {
            printf("%d\t",testData[i][j]);
        }
        printf("\n");
    }
}

void resetTest(){
    memset(testData,0,sizeof(int)*60);
    initialized = 0; 
    nr = 0;
    offset = 0;
    first_pace=1;    
    created=1;
    rows=0;
    fprintf(stdout,"PM_Tester reset\n");
}

void startTest(){
    //showTest();    
    e_time=testData[0][0];
    event=testData[0][1];
    created=0;
    printf("starting test\n");
}

void schedule_tester(int delay){
    signal(SIGALRM,&tester);
    if(delay>=1000){
        tick.it_interval.tv_sec=0;
        tick.it_interval.tv_usec=0;
        tick.it_value.tv_sec=delay/1000;
        tick.it_value.tv_usec=1000*(delay%1000);
        setitimer(ITIMER_REAL,&tick,NULL);
    }
    else ualarm(delay*1000,0);
    //printf("tester scheduled\n");
}

size_t read_ms(struct timespec *timer){
    clock_gettime(CLOCK_REALTIME,timer);
    return (timer->tv_sec*1000+(float)timer->tv_nsec/1000000);
}

void reset_timer(struct timespec *timer){
    timer->tv_sec=0;
    timer->tv_nsec=0;
    clock_settime(CLOCK_REALTIME,(const struct timespec *)timer);
}

void atrial_interrupt()
{
    if(created) return;
    int exp_time=testData[nr][0];
    //printf("apace\n");
        if (event == ATRIAL_OUTPUT)
        {
            if(first_pace) {
        //printf("first apace\n");
        reset_timer(&t);
        first_pace=0;//added by Honnesh
        currTime=0;
        }
            else currTime = read_ms(&t);//get the current time
            int a_lowBound;
            int a_highBound;
            a_lowBound = (e_time + offset*allowOffsets) - tolerance_atrial;
            a_highBound = (e_time + offset*allowOffsets) + tolerance_atrial;
            
            if (currTime >= a_lowBound && currTime <= a_highBound)//response within bounds
            {
                testData[nr][0] = currTime;
                //adjust offset
                offset = offset + (currTime - e_time);
                //load event and time
                e_time = testData[++nr][0];
                event = testData[nr][1];
                //increment
                //adjust offset
                //offset = offset + (currTime - e_time);
                last_event_time = currTime; 
        //printf("calling scheduler from apace routine\n");
            if(event!=ATRIAL_OUTPUT&&event!=VENTRICULAR_OUTPUT){
            exp_time=e_time-exp_time;
            if(exp_time<=0) tester(0);
            else schedule_tester(exp_time);
        }
            }
        else if (currTime < a_lowBound)
            {
                output = ATRIAL_OUTPUT;
                last_event_time = currTime; //tell matlab when the event happened for reporting
                pass = 0;
                testData[nr][0] = currTime;
                testData[nr][1] = ATRIAL_OUTPUT;
            //disable_interrupts();
                createReport();
                // TODO: send fail report
            }
            
            else if (currTime > a_highBound)
            {
                output = ATRIAL_OUTPUT;
                last_event_time = currTime; //tell matlab when the event happened for  error reporting
                testData[nr][0] = currTime;
                testData[nr][1] = ATRIAL_OUTPUT;
            //disable_interrupts();
                createReport();
                // TODO: send fail report
            }
        } 
    else if (event == ATRIAL_INPUT || event == VENTRICULAR_INPUT)
        {
            last_event_time = read_ms(&t);//tell matlab when the error happened
            output = ATRIAL_OUTPUT;
            currTime = last_event_time;
            testData[nr][0] = currTime;
            if(event == ATRIAL_INPUT) testData[nr][1] = ATRIAL_INPUT;
            else testData[nr][1] = VENTRICULAR_INPUT;
        //disable_interrupts();
        createReport();
            // TODO: send fail report
        }
        else if (!first_pace && event ==  VENTRICULAR_OUTPUT)//edited by Honnesh
        {
            last_event_time = read_ms(&t);//tell matlab when the error happened
        output = VENTRICULAR_OUTPUT;
            currTime = last_event_time;
            pass = 0;
            testData[nr][0] = currTime;
            testData[nr][1] = VENTRICULAR_OUTPUT;
        //disable_interrupts();
            createReport();
            // TODO: send fail report
        }
        
}


void ventricular_interrupt()
{
        if(created) return;
        int exp_time=testData[nr][0];
    //printf("vpace\n");
        if (event == VENTRICULAR_OUTPUT)
        {
            if(first_pace) {
        //printf("first vpace\n");
        reset_timer(&t);
        first_pace=0;//added by Honnesh
        currTime=0;
        }
            else currTime = read_ms(&t);//get the current time
            int v_lowBound;
            int v_highBound;
            v_lowBound = (e_time + offset*allowOffsets) - tolerance_ventrical;
            v_highBound = (e_time + offset*allowOffsets) + tolerance_ventrical;
            if (currTime >= v_lowBound && currTime <= v_highBound)//response within bounds
            {
                testData[nr][0] = currTime;
                //adjust offset
                offset = offset + (currTime - e_time);
                //load event and time
                e_time = testData[++nr][0];
                event = testData[nr][1];
                last_event_time = currTime;
            //printf("calling scheduler from vpace routine\n");
        if(event!=ATRIAL_OUTPUT&&event!=VENTRICULAR_OUTPUT){
            exp_time=e_time-exp_time;
            if(exp_time<=0) tester(0);
            else schedule_tester(exp_time);
        }
        }
        else if (currTime < v_lowBound)
            {
                last_event_time = currTime; //tell matlab when the event happened for error reporting
                output = VENTRICULAR_OUTPUT;
                pass = 0;
                testData[nr][0] = currTime;
                testData[nr][1] = VENTRICULAR_OUTPUT;
        //disable_interrupts();
                createReport();
                // TODO: send fail report
            }
            else if (currTime > v_highBound)
            {
                last_event_time = currTime; //tell matlab when the event happened for error reporting
                output = VENTRICULAR_OUTPUT;
                pass = 0;
                testData[nr][0] = currTime;
                testData[nr][1] = VENTRICULAR_OUTPUT;
        //disable_interrupts();
        createReport();
                // TODO: send fail report
            }
        }
    else if (event == ATRIAL_INPUT || event == VENTRICULAR_INPUT)
        {
            last_event_time = read_ms(&t);//tell matlab when the error happened
            currTime = last_event_time;
            output = VENTRICULAR_OUTPUT;
            pass = 0;
            testData[nr][0] = currTime;
            if(event == ATRIAL_INPUT) testData[nr][1] = ATRIAL_INPUT;
            else testData[nr][1] = VENTRICULAR_INPUT;
        //disable_interrupts();
            createReport();
            // TODO: send fail report
        }
        else if (!first_pace && event == ATRIAL_OUTPUT)//edited by Honnesh
        {
            last_event_time = read_ms(&t);//tell matlab when the error happened
            currTime = last_event_time;
            output = ATRIAL_OUTPUT;
            pass = 0;
            testData[nr][0] = currTime;
            testData[nr][1] = ATRIAL_OUTPUT;
            //disable_interrupts();
            createReport();
            // TODO: send fail report
        }
        
}

void tester(int sig)
{
    //printf("Tester called!!!\n");
    if(testData[nr][0]==0&&testData[nr][1]==0){//indicates the test is complete
        //printf("%d:testData[nr][0]=%d,testData[nr][1]=%d\n",nr,testData[nr][0],testData[nr][1]);
        reset_timer(&t);
        createReport();
        printf("test passed\n");
        return;
    }
    int exp_time=testData[nr][0];
    currTime = read_ms(&t);//get the current time
    if (event == ATRIAL_INPUT)
    {
        digitalWrite(ASENSE_PIN,HIGH);
        usleep(800);
        digitalWrite(ASENSE_PIN,LOW);
        testData[nr][0] = (int)currTime;
        testData[nr][1] = 1;
    }
    else if (event == VENTRICULAR_INPUT)
    {
        digitalWrite(VSENSE_PIN,HIGH);
        usleep(800);
        digitalWrite(VSENSE_PIN,LOW);
        testData[nr][0] = (int)currTime;
        testData[nr][1] = 2;
    }
    //load event and time
    e_time = testData[++nr][0];
    event = testData[nr][1];
    last_event_time = currTime; //tell matlab when the event happened for reporting
    if(event!=ATRIAL_OUTPUT&&event!=VENTRICULAR_OUTPUT){
            exp_time=e_time-exp_time;
            if(exp_time<=0) tester(0);
            else schedule_tester(exp_time);
    }
}

int main()
{
    RPC_INT_Variable(&tolerance_atrial, "tolerance_atrial");
    RPC_INT_Variable(&tolerance_ventrical, "tolerance_ventrical");
    RPC_INT_Variable(&allowOffsets, "allowOffsets");
    RPC_INT_Variable(&testData,"testData");
    RPC_INT_Variable(&rows,"rows");
    RPC_VOID_Fcn(resetTest,"reset");
    RPC_VOID_Fcn(startTest,"start");
    initRPC();
    enable_interrupts();
    thread RPC_server(RPC_responder);
    RPC_server.join();
}
