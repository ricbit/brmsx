#include <stdio.h>

void main (void) {
  FILE *file;
  char str[200];
  int i,j;
  int color[16*3]={
               0,0,0,          
               0,0,0,          
               0,34*4,0,         
               0,43*4,0,         
               0,26*4,0,         
               0,34*4,0,         
               0,30*4,0,         
               0,47*4,0,         
               0,34*4,0,         
               0,43*4,0,         
               0,47*4,0,         
               0,51*4,0,         
               0,30*4,0,         
               0,34*4,0,         
               0,51*4,0,         
               0,63*4,0         
          
        };

  printf ("filtered_palette_green:\n");
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
