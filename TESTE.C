#include <stdio.h>
#include <sys/movedata.h>

void main (void) {
  int i;
  unsigned char b;

  for (i=0; i<16; i++) {
    dosmemget (0x18*16+i-0x80,1,&b);
    printf ("%d %d\n",i,b);
  }
}
