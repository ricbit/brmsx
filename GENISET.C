#include <stdio.h>

void main (void) {
  int i,j;

  printf ("isetDDCBxx:\n");
  for (i=0; i<256; i++) {
    printf ("\tdd emulDDCB%02X\n",i,i);
  }
}
