#include <stdio.h>
#include <allegro.h>
#include <conio.h>

#define DELTA 12

typedef struct {
  unsigned char patt[6][6];
} letter;

letter getletter (int x, int y) {
  int i,j;
  letter l;

  for (j=0; j<6; j++)
    for (i=0; i<6; i++)
      l.patt[i][j]=getpixel (screen,x+i,y+j);
  
  return l;
}

void putletter (letter l, int x, int y) {
  int i,j;
  
  for (j=0; j<6; j++)
    for (i=0; i<6; i++)
      putpixel (screen,x+i,y+j,l.patt[i][j]);
  
}

void main (void) {
  BITMAP *bitmap;
  RGB rgb[256];
  letter let[26];
  int i,j;
  unsigned char b;

  allegro_init ();
  set_gfx_mode (GFX_VGA,320,200,320,200);
  bitmap=load_pcx ("brmsx.pcx",rgb);
  blit (bitmap,screen,0,0,0,0,320,200);
  set_palette (rgb);
  let[0]=getletter (94+DELTA*0,136);
  let[1]=getletter (94+DELTA*1,136);
  let[2]=getletter (94+DELTA*2,136);
  let[3]=getletter (94+DELTA*3,136);
  let[4]=getletter (94+DELTA*4,136);
  let[5]=getletter (94+DELTA*5,136);
  let[6]=getletter (94+DELTA*6,136);
  let[7]=getletter (94+DELTA*7,136);
  let[8]=getletter (94+DELTA*8,136);
  let[9]=getletter (94+DELTA*9,136);
  let[10]=getletter (94+DELTA*10,148);
  let[11]=getletter (94+DELTA*10,136);
  let[12]=getletter (94+DELTA*11,136);
  let[13]=getletter (94+DELTA*12,136);
  let[14]=getletter (94+DELTA*0,148);
  let[15]=getletter (94+DELTA*1,148);
  let[16]=getletter (94+DELTA*2,148);
  let[17]=getletter (94+DELTA*3,148);
  let[18]=getletter (94+DELTA*4,148);
  let[19]=getletter (94+DELTA*5,148);
  let[20]=getletter (94+DELTA*6,148);
  let[21]=getletter (94+DELTA*7,148);
  let[22]=getletter (94+DELTA*11,148);
  let[23]=getletter (94+DELTA*8,148);
  let[24]=getletter (94+DELTA*12,148);
  let[25]=getletter (94+DELTA*9,148);
  for (i=0; i<26; i++)
    putletter (let[i],i*7,0);
  getch ();
  
  /* palette generator */
  /*  
  printf ("gui_palette:\n");
  for (i=0; i<212; i++)
    printf ("\tdb\t0%03d,0%03d,0%03d\t\t; %02x \n",0,0,0,i);
  for (i=212; i<256; i++)
    printf ("\tdb\t0%03d,0%03d,0%03d\t\t; %02x \n",
            rgb[(i-212)%256].r,rgb[(i-212)%256].g,rgb[(i-212)%256].b,i);
  */

  /* logo generator */
  
  /*
  printf ("logo_bitmap:\n");
  for (j=132; j<=189; j++)
    for (i=4; i<=92; i++)
      printf ("\tdb\t%d\n",(b=getpixel (screen,i,j)+212)==221?0:b);
  */  

  /* cursor generator */

  printf ("cursor_bitmap:\n");
  for (j=171; j<=171+16; j++)
    for (i=109; i<=109+50; i++) {
      printf ("\tdb\t%d\n",(b=getpixel (screen,i,j)+212)==221?0:b);
      putpixel (screen,i,j,212);
    }

  getch ();
  
  set_gfx_mode (GFX_TEXT,80,24,80,24);
  allegro_exit ();

}

