#include "kernel/types.h"
#include "kernel/net.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    int aiStarted = 0;
    int inputBufferSize = 128;
    int runIter = 0;
    int socket;
    uint16 sport = 2000;

    /**
     * @brief 
     * 
     */
    char *stringEngineStarted = "engineStarted";
    char *stringEngineNotStarted = "engineStopped";
    char *stringRunIter = "runIter";
    char *stringEndSession = "endSession";
    char *stringStopSM = "stopSM";

    /**
     * @brief 10.0.2.2, which qemu remaps to the external host,
     * i.e. the machine you're running qemu on.
     */
    uint32 hostName = (10 << 24) | (0 << 16) | (2 << 8) | (2 << 0);

    /**
     * @brief This value for `dport` comes from the `make grade` command and it
     * appears to be a magic value at the moment.
     */
    uint16 dport = 25600;

    printf("\nStarting XV6 State Machine\n");
    printf("--------------------------\n");
    printf("Host Name: %d\n", hostName);
    printf("S Port: %d\n", sport);
    printf("D Port: %d\n", dport);
    printf("\n");

    /**
     * @brief initialize the socket
     */
    socket = connect(hostName, sport, dport);
    if (socket < 0)
    {
        fprintf(2, "connect() failed.");
        exit(1);
    }
    else
    {
        printf("Socket has been initialized.\n");
    }

    char *outputBuffer = "Hello from XV6!";

    printf("Sending a message to Python\n");
    int outputStatus = write(socket, outputBuffer, strlen(outputBuffer));
    if (outputStatus < 0)
    {
        fprintf(2, "Unable to reach out to Python...\n");
        exit(1);
    }
    else
    {
        printf("Successfully sent message to Python.\n");
    }

    int currentIter = 0;
    /**
     * @brief allow the state machine to loop forever
     */
    while (1)
    {
        printf("Iteration %d: ", currentIter);
        currentIter++;
        char inputBuffer[inputBufferSize];
        int inputStatus = read(socket, inputBuffer, sizeof(inputBuffer) - 1);

        if (inputStatus < 0)
        {
            fprintf(2, "no message received from host\n");
            exit(1);
        }

        if (strcmp(stringEngineStarted, inputBuffer) == 0)
        {
            aiStarted = 1;
            runIter = 0;
        }
        else if (strcmp(stringEngineNotStarted, inputBuffer) == 0)
        {
            aiStarted = 0;
            runIter = 0;
        }
        else if (strcmp(stringRunIter, inputBuffer) == 0)
        {
            aiStarted = 1;
            runIter = 1;
        }
        else if (strcmp(stringEndSession, inputBuffer) == 0)
        {
            aiStarted = 1;
            runIter = 2;
        }
        else if (strcmp(stringStopSM, inputBuffer) == 0)
        {
            printf("Stopping the state machine.\n");
            return 0;
        }
        else
        {
            printf("Received unknown code word: %s \n", inputBuffer);
            aiStarted = 0;
            runIter = 0;
            continue;
        }
        
        
        if (aiStarted == 1)
        {
            printf("(1) AI has been started. ");
            if (runIter == 1)
            {
                printf("(2) Running the next iteration. ");

                char *outputBuffer = "012,345,678|012,345,678|012,345,678|";
                int outputStatus = write(socket, outputBuffer, strlen(outputBuffer));
                if (outputStatus < 0)
                {
                    fprintf(2, "(3) Unable to reach out to Python...\n");
                    exit(1);
                }
                else
                {
                    printf("(3) Sent log to Python ");

                }

                char inputBuffer[inputBufferSize];
                int inputStatus = read(socket, inputBuffer, sizeof(inputBuffer) - 1);

                if (inputStatus < 0)
                {
                    fprintf(2, "no message received from host\n");
                    exit(1);
                }
                else
                {
                    printf("(4) Running process: %s\n", inputBuffer);
                }
            }
            else if (runIter == 0)
            {
                printf("Not running iteration this round.\n");
            }
            else
            {
                printf("Finished running iterations.\n");
            }
        }
        else
        {
            printf("AI is not running.\n");
        }
    }

    printf("\n");
    return 0;
}