%{
#include "compiler.tab.h"
#include "stdio.h"
#include "string.h"
#include "stdlib.h"
int line_count=0;
char err_msg[70];

int yywrap();
void yyerror(char*);
%}

ID [a-zA-Z_]([a-zA-Z_]|[0-9])*
NUM ([0-9])+
REAL_NUM ([0-9])+[.][0-9]+

%%
[ \t]   {;}
\n  {line_count++;}
\r\n    {line_count++;}

"/*"([^\*]|(\*)*[^\*/])*(\*)*"*/"   {
                                        char *ch = yytext;
                                        while (*ch != '\0') {
                                            if (*ch == '\n'){
                                                line_count++;
                                            }
                                            ch++;
                                        }
                                    }
"+" {return PLUS;}
"-" {return MINUS;}
"*" {return TIMES;}
"/" {return SLASH;}
"and"   {return AND;}
"or"    {return OR;}
"not"   {return NOT;}

"%" {return MOD;}
"^" {return XOR;}

"++"    {return SPLUS;}
"--"    {return SMINUS;}

"=="    {return EQ;}
"!="    {return NEQ;}
"<" {return LESS;}
"<="    {return LEQ;}
">" {return GREATER;}
">="    {return GEQ;}
"(" {return LPAREN;}
")" {return RPAREN;}
"[" {return LBRACKETS;}
"]" {return RBRACKETS;}
"{" {return LBRACE;}
"}" {return RBRACE;}
"," {return COMMA;}
";" {return SEMICOLON;}
":" {return COLON;}
"." {return PERIOD;}
"=" {return BECOMES;}

"odd"|"ODD"	{return ODD;}
"switch"	{return SWITCH;}
"case"		{return CASE;}
"default"	{return DEFAULT;}
"break"		{return BREAK;}
"continue"	{return CONTINUE;}
"main"  {return MAIN;}
"const" {return CONST;}
"if"    {return IF;}
"else"  {return ELSE;}
"while" {return WHILE;}
"for"   {return FOR;}
"do"    {return DO;}
"repeat"    {return REPEAT;}
"until" {return UNTIL;}
"write" {return WRITE;}
"read"  {return READ;}
"exit"  {return EXIT;}

"int"   {
            yylval.type = (char*)malloc(strlen(yytext)+1);
            strcpy(yylval.type, yytext);
            return INT;
        }
"real"  {
            yylval.type = (char*)malloc(strlen(yytext)+1);
            strcpy(yylval.type, yytext);
            return REAL;
        }
"char"  {
            yylval.type = (char*)malloc(strlen(yytext)+1);
            strcpy(yylval.type, yytext);
            return CHAR;
        }
"bool"  {
            yylval.type = (char*)malloc(strlen(yytext)+1);
            strcpy(yylval.type, yytext);
            return BOOL;
        }

'[^'\n]'    {
                yylval.number = (int)yytext[1];
                return NUM;
            }
"'\\n'" {
            yylval.number = '\n';
            return NUM;
        }
"'\\t'"	{
            yylval.number = '\t';
            return NUM;
        }
"true"  {
            yylval.number = 1;
            return NUM;
        }
"false" {
            yylval.number = 0;
            return NUM;
        }
{ID}    {
            yylval.id = (char*)malloc(strlen(yytext)+1);
            strcpy(yylval.id, yytext);
            return ID;
        }
{NUM}   {
            yylval.number = atoi(yytext);
            return NUM;
        }
{REAL_NUM}  {
                yylval.real_number = atof(yytext);
                return REAL_NUM;
            }

.   {
        sprintf(err_msg, "error: unexpected character %s at line %d", yytext, line_count);
        yyerror(err_msg);
    }

%%
int yywrap(void)
{
    return 1;
}