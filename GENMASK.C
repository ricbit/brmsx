#include <stdio.h>

void main () {
  int i,j;

  printf ("foregroundcolor:\n");
  for (i=0; i<256; i++) {
    printf ("\tforecolor%02X: db ",i);
    for (j=3; j>=0; j--) {
      printf ("0%02Xh",i>>4);
      if (j>0) printf (",");
    }
    printf ("\n");
  }
}
