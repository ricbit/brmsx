#include <stdio.h>

void main (void) {
  int i,j;
  int b;

  printf ("background_zoom:\n\t");
  for (i=0; i<256; i++) {
    printf ("db\t");
    for (j=0; j<8; j++) {
      printf ("0%02xh,0%02xh",0xff*(!!((i^0xff)&(1<<(7-j)))),0xff*(!!((i^0xff)&(1<<(7-j)))));
      if (j==7 || j==3) 
        printf ("\t; %2x\n\t%s",i,j==3?"db\t":"");
      else
        printf (",");
    }
  }
}
