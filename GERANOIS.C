#include <stdio.h>
#include <stdlib.h>

void main (void) {
  int i,j,n;

  printf ("noise_table:\n");
  for (i=0; i<16384/8; i++) {
    n=0;
    for (j=0; j<8; j++) {
      n=n<<1;
      n|=(rand()>RAND_MAX/2)?1:0;
    }
    printf ("\tdb\t%d\n",n);
  }
}
