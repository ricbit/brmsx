#include <io.h>
#include <fcntl.h>
#include <sys/stat.h>

void main (void) {
  int i,j,max;
  int file;
  int buff[256];

  file=open ("histogr.sta",O_BINARY|O_RDONLY);
  read (file,buff,256*4);
  close (file);
  for (i=0; i<256; i++)
    printf ("op %02X : %d\n",i,buff[i]);
  printf ("ordered:\n");
  do {
    max=0;
    for (i=0; i<256; i++) 
      if (buff[i]>max) { max=buff[i]; j=i; }
    printf ("op %02X : %d\n",j,buff[j]);
    buff[j]=0;
  } while (max!=0);
}

