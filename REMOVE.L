%{

#include <stdio.h>

%}

%%

"outport"[0-9,A-F][0-9,A-F]":" {
  printf ("; %c%c\n",yytext[7],yytext[8]);
}

%%
