#include "kernel/types.h"
#include "kernel/stat.h"
#include "user.h"
#include "kernel/fcntl.h"

int
main(int argc, char *argv[])
{
  int priority, pid;
  if(argc < 3){
    fprintf(2,"Usage: nice pid priority\n");
    exit(1);
  }
  pid = atoi(argv[1]);
  priority = atoi(argv[2]);
  if (priority < 0 || priority > 20){
    fprintf(2,"Invalid priority (0-20)!\n");
    exit(1);
  }
  chprio(pid, priority);
  exit(0);
}