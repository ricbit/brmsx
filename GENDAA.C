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

  printf ("DAA_table:\n");
  for (i=0; i<256; i++) {
    k=(i&BIT_1? 
        (i&BIT_0?
          (i&BIT_4?
            0x9A03
            :
            0xA003
          )
        : 
          (i&BIT_4?
            0xFA02
            :
            0x0002
          )
        )
      :
        (i&BIT_0?
          (i&BIT_4?
            0x6601
            :
            0x6001 /* somar 0x0600 caso A>=0x0a */
          )
        :
          (i&BIT_4?
            0x0600 /* somar 0x6001 caso A>=0xa0 */
            :
            0000 /* caso muito complicado */
          )
        )
      );
    printf ("\t\tdw\t0%04xh\t;%02x\n",k,i);
  }
}

