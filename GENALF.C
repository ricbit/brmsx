#include <stdio.h>
#include <io.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>

void main (void) {
  int file,i,j,k,b;
  unsigned char buff[32768];
  FILE *f;

  file=open ("alf.alf",O_BINARY|O_RDONLY);
  read (file,buff,7);
  read (file,buff,2048);
  close (file);
  /*
  printf ("alf_pattern:\n");
  for (i=0; i<256; i++) {
    printf ("\t; %02x\n",i);
    for (j=0; j<8; j++) {
      printf ("\t db ");
      for (k=0; k<8; k++) {
        if ((buff[i*8+j]>>(7-k))&1)
          printf ("255");
        else
          printf ("000");
        if (k!=7)
          printf (",");
        else
          printf ("\n");
      }
    }
  }   
  */
  f=fopen ("lixo.gry","w");
  for (j=0; j<16; j++) {
    for (k=0; k<8; k++) {
      for (i=0; i<16; i++) {
        for (b=0; b<8; b++) {
          if ((buff[(i+j*16)*8+k]>>(7-b))&1)
            fprintf (f,"%c",255);
          else
            fprintf (f,"%c",0);
        }
      }
    }
  }   
  fclose (f);

}

