#include <stdio.h>
#include <malloc.h>

int main (int argc, char **argv) {
  FILE *fin,*fout; 
  char *buf;
  
  fin=fopen ("brmsx.sta","rb");
  buf=(char *) malloc (70000);
  fread (buf,1,65611,fin);
  fread (buf,1,16384,fin);
  fclose (fin);
  fout=fopen (argv[1],"wb");
  fwrite (buf,1,16394,fout);
  fclose (fout);

  return 0;
}
