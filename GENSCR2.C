#include <stdio.h>

void main (void) {
  int i,j;
  int b;

  printf ("backgroundcolor_MMX:\n");
  for (i=0; i<256; i++) {
    printf ("\tdb\t");
    b=(i)&0xf;
    for (j=0; j<8; j++) {
      printf ("0%02xh",b);
      if (j==7) 
        printf ("\t; %2x\n",i);
      else
        printf (",");
    }
  }
}
