#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

int main (int argc, char **argv) {
  int file;
  unsigned char *buffer;
  int crc=0,i;

  buffer=(unsigned char *) malloc (8192);
  file=open (argv[1],O_BINARY|O_RDONLY);
  read (file,buffer,8192);
  close (file);
  for (i=0; i<8192/4; i++) 
    crc^=*((int*)buffer+i);
  printf ("%08X %s\n",crc,argv[1]);
  return 0;
}
