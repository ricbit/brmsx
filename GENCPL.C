#include <stdio.h>

#define BIT_0   1
#define BIT_1   2
#define BIT_2   4
#define BIT_3   8
#define BIT_4   16
#define BIT_5   32
#define BIT_6   64
#define BIT_7   128

#define getbit(x) ((i&BIT_##x)>0?1:0)

void main (void) {
  int i;
  unsigned char k;

  printf ("CPL_table:\n");
  for (i=0; i<256; i++) {
    k=(i&BIT_5)|(i&BIT_3)|BIT_1|BIT_4;
    printf ("\t\tdb\t0%02xh\t;%02x\n",k,i);
  }
}

