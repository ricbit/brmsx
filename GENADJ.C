#include <stdio.h>

void main (void) {
  int i,j,k;

  printf ("set_adjust_table_512:\n");
  for (i=0; i<256; i++) {
    j=i>>4;
    j|=(j&8)?0xFFFFFFF0:0;
    k=i&0xF;
    k|=(k&8)?0xFFFFFFF0:0;
    printf ("\t; %02X\n",i);
    printf ("\tdd\t%d\n",512*j);
    printf ("\tdd\t%d\n",k*2);
  }
}

