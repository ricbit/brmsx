#include <stdio.h>

void main () {
  int i,j;

  printf ("videomask:\n");
  for (i=0; i<256; i++) {
    printf ("\t\t; %02X\n",i);
    printf ("\t\tdb ");
    for (j=7; j>=0; j--) {
      printf ("0%02Xh",((i&(1<<j))>0?255:0));
      if (j>0) printf (",");
    }
    printf ("\n");
    printf ("\t\tdb ");
    for (j=7; j>=0; j--) {
      printf ("0%02Xh",(((i^255)&(1<<j))>0?255:0));
      if (j>0) printf (",");
    }
    printf ("\n");
  }
}
