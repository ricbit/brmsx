#include <stdio.h>

void main (void) {
  int i;

  printf ("info_table_ed:\n");
  for (i=0; i<256; i++) {
    printf ("\t; ED%02X\n",i);
    printf ("\tdd\t0; offset compED%02X\n",i);
    printf ("\tdb\t0; (offset compED%02X_end)-(offset compED%02X)\n",i,i);
    printf ("\tdb\t0,0,0\n");
  }
}
