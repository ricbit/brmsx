#include <stdio.h>
#include <string.h>

int getbyte (char *str, int pos) {
  int value;
  value=str[pos*2]<'A'?str[pos*2]-'0':str[pos*2]-'A'+10;
  value<<=4;
  value|=str[pos*2+1]<'A'?str[pos*2+1]-'0':str[pos*2+1]-'A'+10;
  return value;
}

void main (int argc, char **argv) {
  char str[60];
  FILE *f;

  f=fopen (argv[1],"r");
  while (fgets (str,50,f)) {
    if (strlen (str)==31)
      printf ("%s\n",str);
      switch (getbyte (str,0)&0xF0) {
        case 0x00:
          printf ("STOP ");
          break;
        case 0x10:
          printf ("RESERVED-1 ");
          break;
        case 0x20:
          printf ("RESERVED-2 ");
          break;
        case 0x30:          
          printf ("RESERVED-3 ");
          break;
        case 0x40:
          printf ("POINT ");
          break;
        case 0x50:
          printf ("PSET ");
          break;
        case 0x60:
          printf ("SEARCH ");
          break;
        case 0x70:
          printf ("LINE ");
          break;
        case 0x80:
          printf ("LMMV ");
          break;
        case 0x90:
          printf ("LMMM ");
          break;
        case 0xA0:
          printf ("LMCM ");
          break;
        case 0xB0:
          printf ("LMMC ");
          break;
        case 0xC0:
          printf ("HMMV ");
          break;
        case 0xD0:
          printf ("HMMM ");
          break;
        case 0xE0:
          printf ("YMMM ");
          break;
        case 0xF0:
          printf ("HMMC ");
          break;
      }
    printf ("\n");
  }
}
