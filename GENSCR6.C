#include <stdio.h>

void main (void) {
  int i;

  printf ("screen6_table:\n");
  for (i=0; i<256; i++)
    printf ("\tdb\t0%02Xh,0%02Xh,0%02Xh,0%02Xh\n",
            16+((i>>6)&3),16+((i>>4)&3),16+((i>>2)&3),16+((i>>0)&3));
}
