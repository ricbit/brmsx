#include <stdio.h>

void main (void) {
  int i;

  printf ("DAA_select_table:\n");
  for (i=0; i<256; i++) {
    printf ("\t; %02x\n",i);
    printf ("\tdb\t%d\n",((i&16)>>2)+(i&3));
  }
}
