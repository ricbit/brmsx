#include <stdio.h>

void main (void) {
  int i;

  printf ("psetEDxx:\n");
  for (i=0; i<256; i++)
    printf ("\tpsetED%02X: dd emulXX\n",i);
}
