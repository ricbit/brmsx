#include <stdio.h>

void main (void) {
  int i;

  printf ("info_table:\n");
  for (i=0; i<256; i++) {
    printf ("\t; %02X\n",i);
    printf ("\tdd\toffset comp%02X\n",i);
    printf ("\tdb\t(offset comp%02X_end)-(offset comp%02X)\n",i,i);
    printf ("\tdb\t0,0,0\n");
  }
}
