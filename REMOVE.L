%{

#include <stdio.h>

%}

%%

"inport"[0-9,A-F][0-9,A-F]":" {
  printf ("; %c%c\n",yytext[6],yytext[7]);
}

%%
