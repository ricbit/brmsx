rdtsc           macro

                db 0fh,031h

                endm

cpuid           macro

                db 0fh,0a2h

                endm

rdmsr           macro

                db 0fh,032h

                endm

wrmsr           macro

                db 0fh,030h

                endm

emms            macro

                db 0fh,077h

                endm

movq            macro

                db 0fh,06fh

                endm

movq_st         macro

                db 0fh,07fh

                endm

pand            macro

                db 0fh,0dbh

                endm

por             macro

                db 0fh,0ebh     
                
                endm

