#include <io.h>
#include <fcntl.h>
#include <sys/stat.h>

void main (void) {
  int i;
  int file;
  unsigned char buff[32768];

  file=open ("adc.com",O_BINARY|O_RDONLY);
  read (file,buff,3);
  read (file,buff,16384);
  close (file);
  file=open ("adc.rom",O_BINARY|O_WRONLY|O_CREAT);
  write (file,buff,16384);
  close (file);
}

