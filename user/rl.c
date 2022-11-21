#include "kernel/types.h"
#include "kernel/net.h"
#include "kernel/stat.h"
#include "user/user.h"

/**
 * @brief 
 * 
 * @param sport 
 * @param dport 
 * @param attempts 
 */
static void connectSocket(uint16 sport, uint16 dport, int attempts)
{
  int fd;
  char *obuf = "a message from xv6!";
  uint32 dst;

  // 10.0.2.2, which qemu remaps to the external host,
  // i.e. the machine you're running qemu on.
  dst = (10 << 24) | (0 << 16) | (2 << 8) | (2 << 0);

  // you can send a UDP packet to any Internet address
  // by using a different dst.
  
  if((fd = connect(dst, sport, dport)) < 0){
    fprintf(2, "ping: connect() failed\n");
    exit(1);
  }

  for(int i = 0; i < attempts; i++) {
    if(write(fd, obuf, strlen(obuf)) < 0){
      fprintf(2, "ping: send() failed\n");
      exit(1);
    }
  }

  char ibuf[128];
  int cc = read(fd, ibuf, sizeof(ibuf)-1);
  if(cc < 0){
    fprintf(2, "ping: recv() failed\n");
    exit(1);
  }

  close(fd);
  ibuf[cc] = '\0';
  if(strcmp(ibuf, "this is the host!") != 0){
    fprintf(2, "ping didn't receive correct payload\n");
    exit(1);
  }
}

/**
 * @brief 
 * 
 * @param argc 
 * @param argv 
 * @return int 
 */
int main(int argc, char *argv[])
{
  int i, ret;
  uint16 outPort = 2000;
  uint16 inPort = 2001;

  printf("Starting RL learning engine...")

  printf("Closing RL learning engine...")

  exit(0);
}
