#include <stdio.h>

void main (void) {
  int i;

  printf ("timp_table:\n");
  for (i=0; i<256; i++)
    printf ("\tdb\t0%02Xh\n",(((i>>4)?0:0xf)<<4) + ((i&0xF)?0:0xf));
}
