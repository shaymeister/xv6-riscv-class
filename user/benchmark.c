#include "kernel/types.h"
#include "kernel/stat.h"
#include "user.h"
#include "kernel/fcntl.h"


int main(int argc, char *argv[]) {
    int pid;
    int amountOfPro;
    int diff;
    //if we have no arguments passed run at least one process
    if(argc <2)
    {
        amountOfPro = 1;
    }
    //else the amount of process is the fiurst argument ran
    else 
    {
        amountOfPro = atoi(argv[1]);
    }
     char *args[] = { "echo","hello", 0 };
     exec("echo" , args);
    

    
    int proLoopCont;
    for (proLoopCont = 0; proLoopCont < amountOfPro; proLoopCont++ )
    {
        pid = fork();
        if ( pid < 0 ) 
        {
            fprintf(2, "%d failed in fork!\n", getpid());
        } 
        else if (pid > 0) 
        {
            // parent
            fprintf(2, "Parent %d creating child %d\n",getpid(), pid);
            wait(0);
        }
        else
        {
            
	        fprintf(2,"Child %d created\n",getpid());
            int before = uptime();
	        do
            {
                diff = uptime()-before;
                
            } while(diff <10);
	        
        }
    }
    exit(0);
}