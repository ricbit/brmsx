#include <stdio.h>

void main (void) {
  FILE *f; int i,j; int c;

  printf ("alf_pattern_z:\n");
  f=fopen ("alf.alf","rb");
  fgetc (f);
  fgetc (f);
  fgetc (f);
  fgetc (f);
  fgetc (f);
  fgetc (f);
  fgetc (f);
  for (i=0; i<256; i++) {
    printf ("\t; %d\n\tdb\t",i);
    for (j=0; j<8; j++) {
      c=fgetc (f);
      printf ("0%02Xh%c",c,j==7?32:',');
    }
    printf ("\n");
  }
}
