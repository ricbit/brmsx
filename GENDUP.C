#include <stdio.h>

void main (void) {
  int i,j;
  int buffer[256];

  printf ("dup_table:\n");

  for (i=0; i<32; i++) {
    
    for (j=0; j<256; j++)
      buffer[j]=j; 
   
    if ((i&1)==0) {
      for (j=255; j>=0; j--)
        buffer[j]=buffer[j/2];        
    }
    
    if ((i&2)==0) {
      for (j=255; j>=0; j--)
        buffer[j]=buffer[(j/4)*2+(j&1)];        
    }
    
    if ((i&4)==0) {
      for (j=255; j>=0; j--)
        buffer[j]=buffer[(j/64)*32+(j&31)];        
    }
    
    if ((i&8)==0) {
      for (j=255; j>=0; j--)
        buffer[j]=buffer[(j/128)*64+(j&63)];        
    }
    
    if ((i&16)==0) {
      for (j=255; j>=0; j--)
        buffer[j]=buffer[(j&127)];        
    }
    
    printf ("; table %d\n\n",i);
    for (j=0; j<256; j++) {
      if (j%8==0)
        printf ("\tdb\t");
      printf ("0%02Xh",buffer[j]);
      if (j%8==7)
        printf ("\n");
      else
        printf (",");
    }
  }
}
