#include <stdio.h>

void main (void) {
  int i;

  printf ("SRL_table:\n");
  for (i=0; i<256; i++)
    printf ("\t\tdb\t0%02xh\t;%02x\n",i&1,i);
}

