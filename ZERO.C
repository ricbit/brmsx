#include <io.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <stdio.h>
#include <malloc.h>

void main (int argc, char **argv) {
  int file;
  int i;
  unsigned char *buff1;

  buff1=(unsigned char *) malloc (131072);
  file=open (argv[1],O_BINARY|O_RDONLY);
  read (file,buff1,512);
  close (file);
  for (i=0; i<512; i++)
    if (buff1[i]!=0) printf ("error at %06x:%02x\n",i,buff1[i]);
}

