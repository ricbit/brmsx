#include <stdio.h>

void main (void) {
  int i,j;

  printf ("SCC_table:\n");
  for (i=0; i<16; i++) {
    printf ("; values for volume %d\n",i);
    for (j=0; j<256; j++) {
      printf ("\tdb\t%d\t;%02x\n",((((int)((signed char)j))+128)*i)>>7,j);
    }
  }
}
