#include <stdio.h>

void main (void) {
  int i,j;

  printf ("isetFDCBxx:\n");
  for (i=0; i<256; i++) {
    printf ("\tisetFDCB%02X: dd emulFDCB%02X\n",i,i);
  }
}
