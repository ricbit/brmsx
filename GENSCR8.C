#include <stdio.h>

void main (void) {
  int i;
  printf ("palette_screen8:\n");
  for (i=0; i<256; i++) {
    printf ("\tdb\t%d,%d,%d\n",
            ((i&0x1C)<<1)+((i&0x1C)>>2),
            ((i&0xE0)>>2)+((i&0xE0)>>5),
            ((i&0x3)<<4)+((i&0x3)<<2)+((i&0x3)<<0)
            );
  }
}
