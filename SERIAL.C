#include <stdio.h>
#include <stdlib.h>
#include <pc.h>
#include <conio.h>

int detect_UART(unsigned baseaddr)
{
   // this function returns 0 if no UART is installed.
   // 1: 8250, 2: 16450 or 8250 with scratch reg., 3: 16550, 4: 16550A
   int x,olddata;

   // check if a UART is present anyway
   olddata=inportb(baseaddr+4);
   outportb(baseaddr+4,0x10);
   if ((inportb(baseaddr+6)&0xf0)) return 0;
   outportb(baseaddr+4,0x1f);
   if ((inportb(baseaddr+6)&0xf0)!=0xf0) return 0;
   outportb(baseaddr+4,olddata);
   // next thing to do is look for the scratch register
   olddata=inportb(baseaddr+7);
   outportb(baseaddr+7,0x55);
   if (inportb(baseaddr+7)!=0x55) return 1;
   outportb(baseaddr+7,0xAA);
   if (inportb(baseaddr+7)!=0xAA) return 1;
   outportb(baseaddr+7,olddata); // we don't need to restore it if it's not there
   // then check if there's a FIFO
   outportb(baseaddr+2,1);
   x=inportb(baseaddr+2);
   // some old-fashioned software relies on this!
   outportb(baseaddr+2,0x0);
   if ((x&0x80)==0) return 2;
   if ((x&0x40)==0) return 3;
   return 4;
}

int detect_IRQ(unsigned base)
{
  // returns: -1 if no intlevel found, or intlevel 0-15
  char ier,mcr,imrm,imrs,maskm,masks,irqm,irqs;

  asm ("cli");            // disable all CPU interrupts
  ier = inportb(base+1);   // read IER
  outportb(base+1,0);      // disable all UART ints
  while (!(inportb(base+5)&0x20));  // wait for the THR to be empty
  mcr = inportb(base+4);   // read MCR
  outportb(base+4,0x0F);   // connect UART to irq line
  imrm = inportb(0x21);    // read contents of master ICU mask register
  imrs = inportb(0xA1);    // read contents of slave ICU mask register
  outportb(0xA0,0x0A);     // next read access to 0xA0 reads out IRR
  outportb(0x20,0x0A);     // next read access to 0x20 reads out IRR
  outportb(base+1,2);      // let's generate interrupts...
  maskm = inportb(0x20);   // this clears all bits except for the one
  masks = inportb(0xA0);   // that corresponds to the int
  outportb(base+1,0);      // drop the int line
  maskm &= ~inportb(0x20); // this clears all bits except for the one
  masks &= ~inportb(0xA0); // that corresponds to the int
  outportb(base+1,2);      // and raise it again just to be sure...
  maskm &= inportb(0x20);  // this clears all bits except for the one
  masks &= inportb(0xA0);  // that corresponds to the int
  outportb(0xA1,~masks);   // now let us unmask this interrupt only
  outportb(0x21,~maskm);
  outportb(0xA0,0x0C);     // enter polled mode; Mike Surikov reported
  outportb(0x20,0x0C);     // that order is important with Pentium/PCI systems
  irqs = inportb(0xA0);    // and accept the interrupt
  irqm = inportb(0x20);
  inportb(base+2);         // reset transmitter interrupt in UART
  outportb(base+4,mcr);    // restore old value of MCR
  outportb(base+1,ier);    // restore old value of IER
  if (masks) outportb(0xA0,0x20);  // send an EOI to slave
  if (maskm) outportb(0x20,0x20);  // send an EOI to master
  outportb(0x21,imrm);     // restore old mask register contents
  outportb(0xA1,imrs);
  asm ("sti");
  if (irqs&0x80)       // slave interrupt occured
    return (irqs&0x07)+8;
  if (irqm&0x80)       // master interrupt occured
    return irqm&0x07;
  return -1;
}
  
#define UART_BAUDRATE 12
#define UART_LCRVAL 0x1b

/*
  UART_BAUDRATE   the divisor value (eg. 12 for 9600 bps)
  UART_LCRVAL     the value to be written to the LCR (eg. 0x1b for 8e1)
  UART_FCRVAL     the value to be written to the FCR. Bit 0, 1 and 2 set,
                  bits 6 & 7 according to trigger level wished (see above).
                  0x87 is a good value, 0x7 establishes compatibility
                  (except that there are some bits to be masked in the IIR).
*/

void UART_init(int addr)
{
   outportb(addr+3,0x80);
   outportw(addr,UART_BAUDRATE);
   outportb(addr+3,UART_LCRVAL);
   outportb(addr+4,0);
}


void UART_send(int addr, char character)
{
   while ((inportb(addr+5)&0x20)==0);
   outportb(addr,(int)character);
}

unsigned UART_get_char(int addr)
{
   unsigned x;
   x = (inportb(addr+5) & 0x9f) << 8;
   if (x&0x100) x|=((unsigned)inportb(addr))&0xff;
   return x;
}


void UART_watch_rxd(int addr)
{
   union {
      unsigned val;
      char character;
      } x;
   while (!kbhit()) {
      x.val=UART_get_char(addr);
      if (!x.val) continue;  // nothing? Continue
      if (x.val&0x100) {
        printf ("%c",x.character);  // character? Print it
        fflush (stdout);
      }
      if (!(x.val&0xe00)) continue;  // any error condidion? No, continue
      if (x.val&0x200) printf("*** Overrun Error ***");
      if (x.val&0x400) printf("*** Parity Error ***");
      if (x.val&0x800) printf("*** Framing Error ***");
      }
}

void terminal(int addr)
{
   int key;
   while (1)
      {
      UART_watch_rxd(addr);
      key=getch();
      if (key==27) break;
      UART_send(addr,(char)key);
      }
}

void main (int argc, char **argv) {
  int addr;
  
  switch (atoi (argv[1])) {  
    case 1: 
      addr=0x3F8;
      break;
    case 2: 
      addr=0x2F8;
      break;
    case 3: 
      addr=0x3E8;
      break;
    case 4: 
      addr=0x2E8;
      break;
  }
  printf ("UART-type of COM%d: %d\n",atoi(argv[1]),detect_UART(addr));
  printf ("int used by COM%d: %d\n",atoi(argv[1]),detect_IRQ(addr));
  UART_init (addr);
  terminal (addr);
}
