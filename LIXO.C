#include <io.h>
#include <fcntl.h>
#include <sys/stat.h>

void main (void) {
  int i;
  int file;
  unsigned char buff[32768];

  file=open ("msxdos23.dsk",O_BINARY|O_RDONLY);
  read (file,buff,512);
  close (file);
  printf ("label1: \n");
  for (i=0; i<512; i++) {
    if (i%8==0)
      printf ("db ");
    printf ("0%02xh",buff[i]);
    if (i%8==7)
      printf ("\n");
    else 
      printf (",");
  }
}

