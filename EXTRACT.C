#include <io.h>
#include <malloc.h>
#include <fcntl.h>
#include <sys/stat.h>

void main (int argc, char **argv) {
  int file;
  unsigned char *buff;

  buff=(unsigned char *) malloc (4e6);
  file=open ("disk2.rom",O_BINARY|O_RDONLY);
  read (file,buff,3*16384);
  close (file);
  file=open (argv[1],O_BINARY|O_CREAT|O_WRONLY,S_IRUSR|S_IWUSR);
  write (file,buff,3*16384);
  close (file);
}

