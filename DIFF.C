#include <io.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <stdio.h>
#include <malloc.h>

void main (int argc, char **argv) {
  int file;
  int i;
  unsigned char *buff1,*buff2,*buffx;

  buff1=(unsigned char *) malloc (131072);
  buff2=(unsigned char *) malloc (131072);
  buffx=(unsigned char *) malloc (131072);
  file=open (argv[1],O_BINARY|O_RDONLY);
  read (file,buff1,131072);
  close (file);
  file=open (argv[2],O_BINARY|O_RDONLY);
  read (file,buff2,131072);
  close (file);
  for (i=0; i<131072; i++)
    buffx[i]=buff1[i]^buff2[i];
  file=open (argv[3],O_BINARY|O_CREAT|O_WRONLY,S_IRUSR|S_IWUSR);
  write (file,buffx,131072);
  close (file);
}

