#include <stdio.h>

#define SEL     7
#define SELBIT  (1<<SEL)

#define BIT_0   1
#define BIT_1   2
#define BIT_2   4
#define BIT_3   8
#define BIT_4   16
#define BIT_5   32
#define BIT_6   64
#define BIT_7   128

void main (void) {
  int i;
  int k;

  printf ("BIT%d_table:\n",SEL);
  for (i=0; i<256; i++) {
    k=((i&BIT_5)|(i&BIT_3)|(BIT_4)) 
      | ((i&(SELBIT))==0 ? (BIT_6|BIT_2) :0)
      | ((i&BIT_7)>0? BIT_7 : 0);
    printf ("\t\tdb\t0%02xh\t;%02x\n",k,i);
  }
}
