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
  unsigned short k;

  printf ("DAA3_table:\n");
  for (i=0; i<256; i++) {
    k=(((i&0xf)<0xa)?
        ((i<0xa0)?0:0x6001)
      :
        ((i<0x90)?0x0600:0x6601)
      );
    printf ("\t\tdw\t0%04xh\t;%02x\n",k,i);
  }
}

