#include <stdio.h>

void main (void) {
  int i,j;
  int b;

  printf ("screen0_table1:\n");
  for (i=0; i<256; i++) {
    printf ("\tdb\t");
    b=i&0xfc;
    for (j=0; j<6; j++) {
      printf ("%d,",(i>>(7-j))&1);
    }
    printf ("0,0\n");
  }
  printf ("\nscreen0_table2:\n");
  for (i=0; i<256; i++) {
    printf ("\tdb\t");
    b=i&0xfc;
    for (j=0; j<2; j++) {
      printf ("%d,",(i>>(7-j))&1);
    }
    printf ("0,0,");
    for (j=2; j<6; j++) {
      printf ("%d",(i>>(7-j))&1);
      if (j<5) printf (",");
    }
    printf ("\n");
  }
}
