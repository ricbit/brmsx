#include <stdio.h>

void main (void) {
  int i,j,k,l;

  printf ("binary_zoom:\n");
  for (i=0; i<256; i++) {
    k=0;
    l=i;
    for (j=0; j<8; j++) {
      k=4*k+((!!(l&128))*3);
      l<<=1;
    }
    printf ("\tdb\t0%02Xh,0%02Xh\t;%02X\n",k>>8,k&0xff,i);
  }
}
