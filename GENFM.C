#include <stdio.h>
#include <math.h>

#define PI 3.14159265358979323

void main (void) {
  int i;

  printf ("sine_table:\n");
  for (i=0; i<256; i++)  
    printf ("\tdb\t0%02Xh\n",(unsigned char)
      ((signed char)(127.0*sin(2.0*PI*(double)i/256.0+3.0*PI/2.0))));
}
