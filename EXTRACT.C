#include <io.h>
#include <fcntl.h>
#include <sys/stat.h>

void main (int argc, char **argv) {
  int file;
  unsigned char buff[32768];

  file=open ("brmsx.sta",O_BINARY|O_RDONLY);
  read (file,buff,0x4b);
  read (file,buff,0x8000);
  close (file);
  file=open (argv[1],O_BINARY|O_CREAT|O_WRONLY,S_IRUSR|S_IWUSR);
  write (file,buff,0x8000);
  close (file);
}

