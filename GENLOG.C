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

  printf ("LOGICAL_table:\n");
  for (i=0; i<256; i++) {
    k=(i&BIT_5)|(i&BIT_3)|(i==0?BIT_6:0)|(i&BIT_7)|
      ((getbit(0)^getbit(1)^getbit(2)^getbit(3)^
        getbit(4)^getbit(5)^getbit(6)^getbit(7)^1)>0?BIT_2:0);
    printf ("\t\tdb\t0%02xh\t;%02x\n",k,i);
  }
}

