#include <stdio.h>

void main (void) {
  FILE *file;
  char str[200];
  int i,j;
  int color[16*3]={
                0,0,0,
                0,0,0,
                32,192,32,
                96,224,96,
                32,32,224,
                64,96,224,
                160,32,32,
                64,192,224,
                224,32,32  ,
                224,96,96   ,
                192,192,32,
                192,192,128,
                32,128,32,
                192,64,160,
                160,160,160,
                224,224,224,
        };

  printf ("filtered_palette:\n");
  for (i=0; i<16; i++)
    for (j=0; j<16; j++) {
      printf 
        ("\tdb\t%d,%d,%d\n",
          (color[3*i]+color[3*j])/8,
          (color[3*i+1]+color[3*j+1])/8,
          (color[3*i+2]+color[3*j+2])/8
        );
    }
}
