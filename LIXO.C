#include <io.h>
#include <fcntl.h>
#include <sys/stat.h>

void main (void) {
  int i;
  int file;
  unsigned char buff[32768];

  file=open ("screen0.grp",O_BINARY|O_RDONLY);
  read (file,buff,7);
  read (file,buff,16384);
  close (file);
  printf ("msxvram: \n");
  for (i=0; i<16384; i++) {
    if (i%8==0)
      printf ("db ");
    printf ("0%02xh",buff[i]);
    if (i%8==7)
      printf ("\n");
    else 
      printf (",");
  }
}

