#include <stdio.h>
#include <sys/movedata.h>

void main (void) {
  int i,j,s;

  s=512;
  j=(s>>5)-1;
  for (i=0;j&(1<<i);i++);
  printf ("j=%d i=%d\n",j,i);
}
