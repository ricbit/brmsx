#include <stdio.h>
#include <io.h>
#include <sys\stat.h>
#include <fcntl.h>
#include <unistd.h>

void main (int argc, char **argv) {
  int i,file,j;
  unsigned char b;

  file=open (argv[1],O_BINARY|O_RDONLY);
  printf ("%s: \n\tdb\t",argv[2]);
  for (i=0; i<filelength (file); i++) {
    read (file,&b,1);
    printf ("%03d",b);
    if (i!=filelength (file)-1)
      if (i%8==7) 
        printf ("\n\tdb\t");
      else
        printf (", ");
  }
  printf ("\n\t\n");
  close (file);
}
