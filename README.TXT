                BRMSX 1.74 - The Brazilian MSX Emulator
                ---------------------------------------
               Copryright (C) 1997 by Ricardo Bittencourt


---------------------------------------------------------------------------

1. What is BRMSX ?

        BRMSX is a new MSX emulator being developed in Brazil. It aims to
be the fastest and most accurate MSX emulator ever created. The current 
version of BRMSX emulates an MSX-1 with following hardware:

        CPU: Zilog Z80 at 3.57 MHz
        VDP: Texas TMS9918
        PSG: G.I. AY-3-8910
        PPI: Intel 8255
        support for external ROM cartridges (including Konami MegaROM)

2. Requirements

        A 32-bit 80x86 processor is required.
        BRMSX runs at full framerate in a 486sx25.

        You will need 48kb of free RAM below 640kb, 
        and 327kb of any other memory (may be raw memory, XMS or EMS).

        A Pentium processor is required to enable the performance bars.
        A MMX processor is not required, 
        but BRMSX may use the special MMX opcodes to run faster.

        A VGA board with 256kb of video memory is required.
        SVGA with a VESA 2.0 driver is required to enable the TV emulation.
        The special 256x200 may not work in older monitors.

        Sound emulation requires a Sound Blaster compatible card,
        capable of auto-init DMA at 45455 Hz.

        Multiplayer game requires in both sides an 
        UART capable of 57600 bauds.
        The client computer can be as slow as a 386.


---------------------------------------------------------------------------

        Sorry but this readme.txt is under construction.

        Any trouble, bug report, comment and suggestion must be
        sent to Ricardo Bittencourt (ricardo@lsi.usp.br).
