#include <stdio.h>

void main (void) {
  int i,j;

  printf ("screen0_table:\n");
  for (i=0; i<256; i++) {
    printf ("\tscr0_%02X: db ",i);
    for (j=7; j>=0; j--) {
      printf ("%d",(i>>j)&1);
      if (j>0) printf (",");
    }
    printf ("\n");
  }
}
