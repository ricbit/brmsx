#include <stdio.h>

void main (void) {
  int i;

  printf ("screen5_table:\n");
  for (i=0; i<256; i++)
    printf ("\tdd\t0%08Xh\n",((i&0xF)*0x01010000)+((i>>4)*0x0101));
}
