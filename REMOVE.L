%{

#include <stdio.h>

%}

%%

"forecolor"[0-9,A-F][0-9,A-F]":" {
  printf ("; %c%c\n",yytext[9],yytext[10]);
}

%%
