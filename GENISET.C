#include <stdio.h>

void main (void) {
  int i,j;

  printf ("psetDDCBxx:\n");
  for (i=0; i<256; i++) {
    printf ("\tpsetDDCB%02X: dd prinXX\n",i);
  }
}
