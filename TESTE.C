#include <stdio.h>

void main (int argc, char **argv, char **envp) {
  printf ("teste %d %d\n",(int)argv,(int)envp);
  printf ("<%s>\n",envp[0]);
}
