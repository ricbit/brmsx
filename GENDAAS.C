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

  printf ("DAA_select_table:\n");
  for (i=0; i<256; i++) {
    printf ("\t\tdd\t");
    if (i&BIT_1) {
      printf ("DAA4_table");
    }
    else {
      if (i&BIT_0) {
        if (i&BIT_4) {
          printf ("DAA4_table");
        }
        else {
          printf ("DAA1_table");
        }
      }
      else {
        if (i&BIT_4) {
          printf ("DAA2_table");
        }
        else {
          printf ("DAA3_table");
        }
      }
    }
    printf ("\t;%02x\n",i);
  }
}

