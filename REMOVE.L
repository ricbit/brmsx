%{

#include <stdio.h>

%}

%%

"back"[0-9,A-F][0-9,A-F]":" {
  printf ("; %c%c\n",yytext[4],yytext[5]);
}

%%
