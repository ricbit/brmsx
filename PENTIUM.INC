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
