#include <stdio.h>

void main (void) {
  int i;

  printf ("keyboardtable:\n");
  for (i=0; i<128; i++)
    printf ("\tkey_%02X: db 0,0\n",i);
}
