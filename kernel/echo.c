#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
kecho(int argc, char *argv[])
{
  int i;

  for(i = 1; i < argc; i++){
    printf("echo");
  }
  return(0);
}
