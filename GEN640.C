#include <stdio.h>

void main (void) {
  int i,j,k;

  printf ("screen_640_table:\n");
  for (i=0; i<212; i++) {
    j=(640*28+64+i*640*2)&0xFFFF;
    k=(640*28+64+i*640*2)>>16;
    printf ("\t; %d\n",i);
    printf ("\tdw\t0%04Xh\n",j);
    j=0x10000-j;
    if (j>512)
      printf ("\tdb\t%d,128\n",k);
    else
      printf ("\tdb\t%d,%d\n",k,j/4);
    printf ("\n");
  }
}
