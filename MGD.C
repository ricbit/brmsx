#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>

void main (int argc, char **argv) {
  int file,len;
  unsigned char *buffer;
  int i,addr;

  file=open (argv[1],O_BINARY|O_RDONLY);
  len=filelength (file);
  buffer=(unsigned char *) malloc (len);
  read (file,buffer,len);
  close (file);
  for (i=0; i<len-3; i++) {
    if (buffer[i]==0x32) {
      addr=buffer[i+1]+buffer[i+2]*256;
      if (addr>=0x4000 && addr<=0xbfff && buffer[i+1]==0)
        printf ("found: %04X\n",buffer[i+1]+buffer[i+2]*256);
    }
  }
}
