%token  <id>    ID
%token  <number>    NUM
%token  <real_number>   REAL_NUM
%token  <type>  INT CHAR REAL BOOL CONST
%token  PLUS MINUS TIMES SLASH AND OR NOT MOD XOR
%token  SPLUS SMINUS
%token  EQ NEQ LESS LEQ GREATER GEQ
%token  LPAREN RPAREN LBRACKETS RBRACKETS LBRACE RBRACE 
%token  COMMA SEMICOLON COLON PERIOD BECOMES
%token  ODD
%token  SWITCH CASE DEFAULT BREAK CONTINUE MAIN IF ELSE WHILE FOR DO
%token  REPEAT UNTIL WRITE READ EXIT

%type <number> var
%type <number> get_code_addr
%type <number> else_stat
%type <number> array_size
%type <number> array_loc
%type <type> type
%type <number> statement
%type <number> loop_stat_list

%right  ODD
%left   OR
%left   AND
%left   XOR
%left   PLUS MINUS
%left   TIMES SLASH MOD
%left   SPLUS SMINUS UMINUS 
%right  NOT
%nonassoc   ELSE

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <gtk/gtk.h>
#include "utils/symtable.h"
#include "utils/code.h"
#include "utils/list.h"

FILE *yout;
FILE *yyin;
List* array_ids=NULL;
int main_tx;

GtkWidget *window;
GtkWidget *x0code;
GtkWidget *pcode;
GtkWidget *output;
GtkWidget *symt;

void yyerror(char*);
int yylex(void);

void import_onclick(GtkWidget *widget, gpointer data);
void import_openfile(GtkWidget* trigger, gint response_id, gpointer data);
void save_onclick(GtkWidget *widget, gpointer data);
void save_openfile(GtkWidget* trigger, gint response_id, gpointer data);
void run_onclick(GtkWidget *widget, gpointer data);
void about_onclick(GtkWidget *widget, gpointer data);
%}

%union{
    char *id;
    int number;
    double real_number;
    char *type;
}

%%
program:
    MAIN LBRACE {
                    dx=3;
                    main_tx=tx;
                    table[tx].address=cx;
                    gen(jmp,0,1);
                }
    const_list  {}
    declaration_list    {
                            code[table[main_tx].address].a=cx;
                            strcpy(table[main_tx].name,"main");
                            table[main_tx].var_category=procedure;
                            table[main_tx].var_type=none;
                            table[main_tx].address=cx;
                            table[main_tx].size=dx;
                            table[main_tx].is_array=0;
                            gen(ini,0,dx);
                        }
    statement_list  {
                        gen(opr,0,0);
                    }
    RBRACE  {}
    ;

const_list: 
    const_list const_dec    {}
    |
    ;

const_dec:
    CONST INT ID BECOMES NUM SEMICOLON  {
                                            instance_type=int_t;
                                            strcpy(id,$3);
                                            num=$5;
                                            enter(constant);
                                        }
    |CONST REAL ID BECOMES REAL_NUM SEMICOLON   {
                                                    instance_type=real_t;
                                                    strcpy(id,$3);
                                                    real_num=$5;
                                                    enter(constant);
                                                }
    |CONST CHAR ID BECOMES NUM SEMICOLON    {
                                                instance_type=char_t;
                                                strcpy(id,$3);
                                                num=$5;
                                                enter(constant);
                                            }
    |CONST BOOL ID BECOMES NUM SEMICOLON    {
                                                instance_type=bool_t;
                                                strcpy(id,$3);
                                                num=$5;
                                                enter(constant);
                                            }
    ;

declaration_list:
    declaration_list declaration_stat {} | {}
;

declaration_stat:
    type ID array_size SEMICOLON    {
                                        if(strcmp($1,"int")==0){
                                            instance_type=int_t;
                                        }else if(strcmp($1,"char")==0){
                                            instance_type=char_t;
                                        }else if(strcmp($1,"bool")==0){
                                            instance_type=bool_t;
                                        }else if(strcmp($1,"real")==0){
                                            instance_type=real_t;
                                        }else{
                                            instance_type=none;
                                        }

                                        if(is_array_rec==1){
                                            strcpy(id,$2);
                                            enter(variable);
                                        }else
                                        {
                                            strcpy(id,$2);
                                            enter(variable);
                                        }
                                        instance_type=none;
                                    }
    ;

array_size:
    array_size LBRACKETS NUM RBRACKETS  {
                                            is_array_rec=1;
                                            array_dim++;
                                            array_size=list_add_item(array_size,$3);
                                        }
    |   {
            is_array_rec=0;
            array_dim=0;
            array_size=NULL;
        }
    ;

type:
    INT {$$=$1;}
    |REAL {$$=$1;}
    |CHAR {$$=$1;}
    |BOOL {$$=$1;}
    ;

var:
    ID  {
            int i=get_position($1);
            if(i<=0)
            {
                char s[MAX_ID_LENGTH];
                sprintf(s,"error: variable %s undefined.", $1);
                syntax_error(s);
            }
            $$ = i;
            if(table[i].is_array)
            {
                array_ids=list_add_item(array_ids, i);
                array_id=i;
            }
        }
    ;

statement_list:
    statement_list statement {}
    |statement {}
    ;

statement:
    if_stat {}
    |while_stat {}
    |read_stat {}
    |write_stat {}
    |compound_stat {}
    |expression_stat {}
    |for_stat {}
    |do_while_stat {}
    |repeat_until_stat {}
    |exit_stat {}
    |break_stat {}
    |continue_stat {}
    ;

exit_stat:
    EXIT SEMICOLON {gen(ext,0,0);}
    ;

break_stat:
    BREAK SEMICOLON {
                        loop_position++;
                        if(loop_position>=MAX_LOOP){
                            syntax_error("too many breaks or continues.");
                        }
                        loopRegister[loop_position].cx=cx;
                        loopRegister[loop_position].type=brks;
                        loopRegister[loop_position].level=loop_level;
                        gen(jmp,0,0);
                    }
    ;

continue_stat:
    CONTINUE SEMICOLON      {
                                loop_position++;
                                if(loop_position>=MAX_LOOP){
                                    syntax_error("too many breaks or continues.");
                                }
                                loopRegister[loop_position].cx=cx;
                                loopRegister[loop_position].type=ctn;
                                loopRegister[loop_position].level=loop_level;
                                gen(jmp,0,0);
                            }
    ;

for_stat:
    FOR LPAREN for_exp1 SEMICOLON get_code_addr for_exp2 SEMICOLON get_code_addr    {
                                                                                            if(loop_level==0){
                                                                                                loop_position=-1;
                                                                                            }
                                                                                            loop_level++;
                                                                                            gen(jpc,0,0);
                                                                                            gen(jmp,0,0);
                                                                                    }
    for_exp3    {
                    gen(jmp,0,$5);
                }
    RPAREN get_code_addr loop_stat_list {
                                            gen(jmp,0,$8+2);
                                            code[$8].a=cx;
                                            code[$8+1].a=$13;
                                            for(int i=0;i<=loop_position;i++)
                                            {
                                                if(loopRegister[i].level==loop_level){
                                                    switch(loopRegister[i].type){
                                                        case brks:
                                                            code[loopRegister[i].cx].a=cx;
                                                            break;
                                                        case ctn:
                                                            code[loopRegister[i].cx].a=$8+2;
                                                            break;
                                                    }
                                                }
                                            }
                                            loop_level--;

                                        }
    ;

for_exp1:
    expression  {}
    |   {}
    ;

for_exp2:
    simple_expr  {}
    |   {}
    ;

for_exp3:
    expression  {}
    |   {}
    ;

loop_stat_list:
    statement  {}
    ;

do_while_stat:
    DO  get_code_addr   {
                            if(loop_level==0)
                            {
                                loop_position=-1;
                            }
                            loop_level++;
                        } 
    do_while_stat_list WHILE get_code_addr LPAREN simple_expr RPAREN SEMICOLON get_code_addr   {
                                                                                                                    gen(jpc,0,$11+2);
                                                                                                                    gen(jmp,0,$2);

                                                                                                                    for(int i=0;i<=loop_position;i++)
                                                                                                                    {
                                                                                                                        if(loopRegister[i].level==loop_level){
                                                                                                                            switch(loopRegister[i].type){
                                                                                                                                case brks:
                                                                                                                                    code[loopRegister[i].cx].a=cx;
                                                                                                                                    break;
                                                                                                                                case ctn:
                                                                                                                                    code[loopRegister[i].cx].a=$6;
                                                                                                                                    break;
                                                                                                                            }
                                                                                                                        }
                                                                                                                    }
                                                                                                                    loop_level--;
                                                                                                                }
    ;

do_while_stat_list:
    statement  {}
    ;

repeat_until_stat:
    REPEAT  get_code_addr   {
                                if(loop_level==0)
                                {
                                    loop_position=-1;
                                }
                                loop_level++;
                            }
    repeat_until_stat_list UNTIL get_code_addr LPAREN simple_expr RPAREN SEMICOLON     {
                                                                                                                gen(jpc,0,$2);

                                                                                                                for(int i=0;i<=loop_position;i++)
                                                                                                                {
                                                                                                                    if(loopRegister[i].level==loop_level){
                                                                                                                        switch(loopRegister[i].type){
                                                                                                                            case brks:
                                                                                                                                code[loopRegister[i].cx].a=cx;
                                                                                                                                break;
                                                                                                                            case ctn:
                                                                                                                                code[loopRegister[i].cx].a=$6;
                                                                                                                                break;
                                                                                                                        }
                                                                                                                    }
                                                                                                                }
                                                                                                                loop_level--;

                                                                                                            }
    ;

repeat_until_stat_list:
    statement  {}
    ;

if_stat:
    IF LPAREN expression RPAREN get_code_addr   {
                                                    gen(jpc, 0, 0);
                                                } 
    statement else_stat   {
                    code[$5].a = $8;
                }
    ;

else_stat:
    ELSE get_code_addr  {
                            gen(jmp,0,0);
                        } 
    statement   {
                    $$=$2+1;
                    code[$2].a=cx;
                }
    |   {
            $$ = cx;
        }
    ;

while_stat:
    WHILE   get_code_addr   {
                                if(loop_level==0)
                                {
                                    loop_position=-1;
                                }
                                loop_level++;
                            } 
    LPAREN expression RPAREN get_code_addr  {
                                                gen(jpc, 0 , 0);
                                            }
    statement   {
                    gen(jmp, 0, $2);
                    code[$7].a = cx;

                    for(int i=0;i<=loop_position;i++)
                    {
                        if(loopRegister[i].level==loop_level){
                            switch(loopRegister[i].type){
                                case brks:
                                    code[loopRegister[i].cx].a=cx;
                                    break;
                                case ctn:
                                    code[loopRegister[i].cx].a=$2;
                                    break;
                            }
                        }
                    }
                    loop_level--;
                }
    ;

write_stat:
    WRITE expression SEMICOLON  {
                                    gen(opr,0,14);
                                }
    |WRITE var SEMICOLON        {
                                    if(table[$2].var_category==constant){
                                        if(table[$2].var_type==real_t){
                                            _gen(lit,0,0,1,table[$2].real_val);
                                        }else{
                                            gen(lit,0,table[$2].val);
                                        }
                                    }else if(table[$2].var_category==variable){
                                        gen(lod,0,table[$2].address);
                                    }
                                    if(table[$2].var_type==char_t)
                                        gen(opr,0,17);
                                    else if(table[$2].var_type==int_t)
                                        gen(opr,0,14);
                                    else if(table[$2].var_type==bool_t)
                                        gen(opr,0,25);
                                    else if(table[$2].var_type==real_t)
                                        gen(opr,0,14);
                                    else
                                        error(0); 
                                }   
    ;

array_loc:
    array_loc LBRACKETS expression RBRACKETS        {
                                                        int id=list_get_last_item(array_ids);
                                                        int dim_id=$1;
                                                        $$=dim_id+1;  
                                                        if(dim_id+1>table[id].array_dim){
                                                            char s[50];
                                                            sprintf(s,"dimension of array %s is %d, gived %d.", table[id].name, table[id].array_dim, dim_id);
                                                            syntax_error(s);
                                                        }
                                                        int p=list_get_item_after_id(table[id].array_size, dim_id);
                                                        gen(lit,0,p);
                                                        gen(opr,0,4);
                                                        if(dim_id>=1){
                                                            gen(opr,0,2);
                                                        }

                                                    }
    |   {$$=0;}
    ;

read_stat:
    READ var array_loc SEMICOLON    {
                                        if(table[$2].var_category==constant){
                                            syntax_error("cannot write to constant");
                                        }else{
                                            if($3>=1){
                                                gen(lit,0,table[$2].address);
                                                gen(opr,0,2);
                                                if(table[$2].var_type==real_t){
                                                    _gen(opr,0,16,1,0.0);
                                                }else{
                                                    gen(opr,0,16);
                                                }
                                                gen(sto,0,0);
                                            }else{
                                                if(table[$2].var_type==real_t){
                                                    _gen(opr,0,16,1,0.0);
                                                }else{
                                                    gen(opr,0,16);
                                                }
                                                gen(sto,0,table[$2].address);
                                            }
                                        }
                                    }
    ;

compound_stat:
    LBRACE statement_list RBRACE {}
    ;

expression_stat: 
    expression SEMICOLON {}
    | SEMICOLON {}
    ;

expression:
    var array_loc   {
                        if(table[$1].var_category==constant){
                            syntax_error("constant cannot be writen.");
                        }else{
                            if($2>=1){
                                gen(lit,0,table[$1].address);
                                gen(opr,0,2);
                            }
                        }
                    }
    BECOMES expression    {
                            if($2>=1){
                                gen(sto,0,0);
                            }else{
                                gen(sto,0,table[$1].address);
                                gen(lod,0,table[$1].address);
                            }
                        }
    | simple_expr {}
    ;

simple_expr:
    additive_expr {}
    | additive_expr GREATER additive_expr   {
                                            gen(opr,0,12);
                                        }
    | additive_expr LESS additive_expr   {
                                            gen(opr,0,10);
                                        }
    | additive_expr GEQ additive_expr   {
                                            gen(opr,0,11);
                                        }
    | additive_expr LEQ additive_expr   {
                                            gen(opr,0,13);
                                        }
    | additive_expr EQ additive_expr   {
                                            gen(opr,0,8);
                                        }
    | additive_expr NEQ additive_expr   {
                                            gen(opr,0,9);
                                        }
    | additive_expr AND additive_expr   {
                                            gen(opr,0,22);
                                        }
    | additive_expr OR additive_expr    {
                                            gen(opr,0,23);
                                        }
    |NOT additive_expr                  {
                                            gen(opr,0,24);
                                        }                                    
    ;

additive_expr:
    term  {}
    |additive_expr PLUS term    {
                                    gen(opr,0,2);
                                }
    |additive_expr MINUS term   {
                                    gen(opr,0,3);
                                }
    ;

term:
    factor      {   

                }
    |term TIMES factor  {
                            gen(opr,0,4);
                        }
    |term SLASH factor  {
                            gen(opr,0,5);
                        }
    |term MOD factor    {
                            gen(opr,0,20);
                        }
    |term XOR factor    {
                            gen(opr,0,21);
                        }
    |ODD factor         {
                            gen(opr,0,6);
                        }
    ;

factor:
    LPAREN expression RPAREN {}
    |var  array_loc {
                        switch(table[$1].var_category){
                            case constant:
                                if($2>=1){
                                    syntax_error("Constant array not supported.");
                                }
                                if(table[$1].var_type==real_t){
                                    _gen(lit,0,0,1,table[$1].real_val);
                                }else{
                                    gen(lit,0,table[$1].val);
                                }
                                break;
                            case variable:
                                if($2>=1){
                                    if(!table[$1].is_array){
                                        char s[50];
                                        sprintf(s,"variable %s is not an array.", table[$1].name);
                                        syntax_error(s);
                                    }
                                    gen(lit,0,table[$1].address);
                                    gen(opr,0,2);
                                    gen(lod,0,0);
                                    list_remove_last_item(array_ids);
                                }else{
                                    gen(lod,0,table[$1].address);
                                }
                                break;
                            case procedure:
                                syntax_error("procedure not supported.");
                                break;
                            }
                    }
    |var SPLUS  {
                    if(!table[$1].is_array){
                        gen(lod,0,table[$1].address);
                        gen(lod,0,table[$1].address);
                        gen(lit,0,1);
                        gen(opr,0,2);
                        gen(sto,0,table[$1].address);
                    }else{
                        char s[50];
                        sprintf(s,"%s is an array", table[$1].name);
                        syntax_error(s);
                    }
                }
    |var SMINUS {
                    if(!table[$1].is_array){
                        gen(lod,0,table[$1].address);
                        gen(lod,0,table[$1].address);
                        gen(lit,0,1);
                        gen(opr,0,3);
                        gen(sto,0,table[$1].address);
                    }else{
                        char s[50];
                        sprintf(s,"%s is an array", table[$1].name);
                        syntax_error(s);
                    }
                }
    |SPLUS var  {
                    if(!table[$2].is_array){
                        gen(lod,0,table[$2].address);
                        gen(lit,0,1);
                        gen(opr,0,2);
                        gen(sto,0,table[$2].address);
                        gen(lod,0,table[$2].address);
                    }else{
                        char s[50];
                        sprintf(s,"%s is an array", table[$2].name);
                        syntax_error(s);
                    }
                }
    |SMINUS var {
                    if(!table[$2].is_array){
                        gen(lod,0,table[$2].address);
                        gen(lit,0,1);
                        gen(opr,0,3);
                        gen(sto,0,table[$2].address);
                        gen(lod,0,table[$2].address);
                    }else{
                        char s[50];
                        sprintf(s,"%s is an array", table[$2].name);
                        syntax_error(s);
                    }
                }
    |NUM    {
                int num;
                num=$1;
                if(num>AMAX){
                    char s[100];
                    sprintf(s,"integer(%d) should not greater than %d, now 0 instead. ", $1, AMAX);
                    syntax_error(s);
                    num=0;
                }
                gen(lit,0,num);
            }
    |REAL_NUM  {
                real_num=$1;
                _gen(lit,0,0,1,$1);
            }
    ;

get_code_addr:
               {
                $$ = cx;
               }
          ;
%%

void yyerror(char *s)
{
    err++;
    GtkWidget *dialog;
    dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_DESTROY_WITH_PARENT, GTK_MESSAGE_ERROR,
                GTK_BUTTONS_OK, s);
    gtk_window_set_title(GTK_WINDOW(dialog), "Compiler Error");
    gtk_dialog_run(GTK_DIALOG(dialog));
    gtk_widget_destroy(dialog);
}

int main(int argc,char* argv[])
{
    const gchar* pcode_items[6]={"id", "f", "l", "a", "isd", "d"};
    const gchar* symt_items[9]={"name", "kind", "val", "val_d", "type", "adr", "size", "array", "array_dim"};
    GtkWidget *table;

    GtkWidget *x0code_title;
    GtkWidget *pcode_title;
    GtkWidget *output_title;
    GtkWidget *symt_title;

    GtkWidget *import;
    GtkWidget *save;
    GtkWidget *run;
    GtkWidget *about;

    GtkWidget *halign;
    GtkWidget *halign2;
    GtkWidget *halign3;
    GtkWidget *halign4;

    GtkWidget *scrolled_window;
    GtkWidget *scrolled_window1;

    gtk_init(&argc, &argv);

    window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_position(GTK_WINDOW(window), GTK_WIN_POS_CENTER);
    gtk_widget_set_size_request (window, 900, 600);
    gtk_window_set_resizable(GTK_WINDOW(window), TRUE);

    gtk_window_set_title(GTK_WINDOW(window), "Naive Compiler for X0");

    gtk_container_set_border_width(GTK_CONTAINER(window), 15);

    table = gtk_table_new(16, 16, TRUE);
    gtk_table_set_row_spacings(GTK_TABLE(table), 5);
    gtk_table_set_col_spacings(GTK_TABLE(table), 5);

    scrolled_window = gtk_scrolled_window_new (NULL, NULL);
    scrolled_window1 = gtk_scrolled_window_new (NULL, NULL);

    x0code_title = gtk_label_new("X0 Code");
    halign = gtk_alignment_new(0, 0, 0, 0);
    gtk_container_add(GTK_CONTAINER(halign), x0code_title);
    gtk_table_attach(GTK_TABLE(table), halign, 0, 1, 0, 1, 
      GTK_FILL, GTK_FILL, 0, 0);

    x0code = gtk_text_view_new();
    gtk_text_view_set_editable(GTK_TEXT_VIEW(x0code), TRUE);
    gtk_text_view_set_cursor_visible(GTK_TEXT_VIEW(x0code), TRUE);
    gtk_table_attach(GTK_TABLE(table), x0code, 0, 9, 1, 9,
      GTK_FILL|GTK_EXPAND, GTK_FILL|GTK_EXPAND, 1, 1);
    

    pcode_title = gtk_label_new("P-code");
    halign2 = gtk_alignment_new(0, 0, 0, 0);
    gtk_container_add(GTK_CONTAINER(halign2), pcode_title);
    gtk_table_attach(GTK_TABLE(table), halign2, 9, 10, 0, 1, 
      GTK_FILL, GTK_FILL, 0, 0);

    pcode = gtk_clist_new_with_titles(6, pcode_items);
    gtk_scrolled_window_set_policy (GTK_SCROLLED_WINDOW(scrolled_window), GTK_POLICY_ALWAYS, GTK_POLICY_NEVER);
    gtk_container_add(GTK_CONTAINER(scrolled_window), pcode);
    gtk_table_attach(GTK_TABLE(table), scrolled_window, 9, 15, 1, 9,
      GTK_FILL|GTK_EXPAND, GTK_FILL|GTK_EXPAND, 1, 1);
    
    import = gtk_button_new_with_label("Import");
    gtk_widget_set_size_request(import, 50, 30);
    gtk_table_attach(GTK_TABLE(table), import, 15, 16, 1, 2, 
      GTK_FILL, GTK_SHRINK, 1, 1);
    g_signal_connect(G_OBJECT(import), "clicked", G_CALLBACK(import_onclick),NULL);

    save = gtk_button_new_with_label("Save");
    gtk_widget_set_size_request(save, 50, 30);
    gtk_table_attach(GTK_TABLE(table), save, 15, 16, 2, 3, 
      GTK_FILL, GTK_SHRINK, 1, 1);
    g_signal_connect(G_OBJECT(save), "clicked", G_CALLBACK(save_onclick),NULL);
    
    output_title = gtk_label_new("Output");
    halign3 = gtk_alignment_new(0, 0, 0, 0);
    gtk_container_add(GTK_CONTAINER(halign3), output_title);
    gtk_table_attach(GTK_TABLE(table), halign3, 0, 1, 9, 10, 
      GTK_FILL, GTK_FILL, 0, 0);

    output = gtk_text_view_new();
    gtk_text_view_set_editable(GTK_TEXT_VIEW(output), FALSE);
    gtk_text_view_set_cursor_visible(GTK_TEXT_VIEW(output), FALSE);
    gtk_table_attach(GTK_TABLE(table), output, 0, 9, 10, 15,
      GTK_FILL|GTK_EXPAND, GTK_FILL|GTK_EXPAND, 1, 1);

    symt_title = gtk_label_new("Symbol Table");
    halign4 = gtk_alignment_new(0, 0, 0, 0);
    gtk_container_add(GTK_CONTAINER(halign4), symt_title);
    gtk_table_attach(GTK_TABLE(table), halign4, 9, 10, 9, 10, 
      GTK_FILL, GTK_FILL, 0, 0);

    symt = gtk_clist_new_with_titles(9, symt_items);
    gtk_scrolled_window_set_policy (GTK_SCROLLED_WINDOW(scrolled_window1), GTK_POLICY_ALWAYS, GTK_POLICY_NEVER);
    gtk_container_add(GTK_CONTAINER(scrolled_window1), symt);
    gtk_table_attach(GTK_TABLE(table), scrolled_window1, 9, 15, 10, 15,
      GTK_FILL|GTK_EXPAND, GTK_FILL|GTK_EXPAND, 1, 1);

    about = gtk_button_new_with_label("About");
    gtk_widget_set_size_request(about, 50, 30);
    gtk_table_attach(GTK_TABLE(table), about, 0, 1, 15, 16, 
      GTK_FILL, GTK_SHRINK, 1, 1);
    g_signal_connect(G_OBJECT(about), "clicked", G_CALLBACK(about_onclick),NULL);
    
    run = gtk_button_new_with_label("Run");
    gtk_widget_set_size_request(run, 50, 30);
    gtk_table_attach(GTK_TABLE(table), run, 1, 2, 15, 16, 
      GTK_FILL, GTK_SHRINK, 1, 1);
    g_signal_connect(G_OBJECT(run), "clicked", G_CALLBACK(run_onclick),NULL);

    gtk_container_add(GTK_CONTAINER(window), table);

    g_signal_connect_swapped(G_OBJECT(window), "destroy",
        G_CALLBACK(gtk_main_quit), G_OBJECT(window));

    gtk_widget_show_all(window);
    gtk_main();

    return 0;
}

void import_onclick(GtkWidget *widget, gpointer data)
{
    GtkWidget *FileSelection;
    FileSelection = gtk_file_selection_new ("Choose Source Code");
    gtk_file_selection_set_filename (GTK_FILE_SELECTION (FileSelection),"*.x0");
    g_signal_connect(G_OBJECT(FileSelection), "response", G_CALLBACK(import_openfile), data);
    gtk_widget_show (FileSelection);
}


void import_openfile(GtkWidget* trigger, gint response_id, gpointer data)
{
    if(response_id == -5){
        FILE* fp=fopen(gtk_file_selection_get_filename(trigger),"r");

        if(fp!=NULL)
        {
            const char* blank="";

            GtkTextBuffer* buffer=gtk_text_view_get_buffer(GTK_TEXT_VIEW(x0code));
            gtk_text_buffer_set_text(buffer,blank,strlen(blank));

            char ch;
            char text[2];
            while((ch=fgetc(fp))!=EOF)
            {
                text[0]=ch;
                text[1]='\0';

                GtkTextIter start,end;
                gtk_text_buffer_get_bounds(GTK_TEXT_BUFFER(buffer),&start,&end);
                gtk_text_buffer_insert(GTK_TEXT_BUFFER(buffer),&end,text,strlen(text));
            }
        }
        else
        {
            GtkWidget *dialog;
            dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_DESTROY_WITH_PARENT, GTK_MESSAGE_ERROR,
                GTK_BUTTONS_OK, "Error: cannot open file");
            gtk_window_set_title(GTK_WINDOW(dialog), "Error");
            gtk_dialog_run(GTK_DIALOG(dialog));
            gtk_widget_destroy(dialog);
        }
        fclose(fp);
    }
    gtk_widget_destroy(trigger);  
}

void save_onclick(GtkWidget *widget, gpointer data)
{
    GtkWidget *FileSelection;
    FileSelection = gtk_file_selection_new ("Save File");
    gtk_file_selection_set_filename (GTK_FILE_SELECTION (FileSelection),"*.x0");
    g_signal_connect(G_OBJECT(FileSelection), "response", G_CALLBACK(save_openfile), data);
    gtk_widget_show (FileSelection);
}

void save_openfile(GtkWidget* trigger, gint response_id, gpointer data)
{
    if(response_id == -5)
    {
        FILE* fp=fopen(gtk_file_selection_get_filename(trigger),"w");

        if(fp!=NULL)
        {
            char* text;
            GtkTextIter start,end;
            GtkTextBuffer* buffer=gtk_text_view_get_buffer(GTK_TEXT_VIEW(x0code));

            gtk_text_buffer_get_bounds(GTK_TEXT_BUFFER(buffer),&start,&end);
            text=gtk_text_buffer_get_text(GTK_TEXT_BUFFER(buffer),&start,&end,FALSE);
            fprintf(fp,"%s",text);

            GtkWidget *dialog;
            dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_DESTROY_WITH_PARENT, GTK_MESSAGE_INFO,
                GTK_BUTTONS_OK, "Succeed to Save File.");
            gtk_window_set_title(GTK_WINDOW(dialog), "OK");
            gtk_dialog_run(GTK_DIALOG(dialog));
            gtk_widget_destroy(dialog);
        }
        else
        {
            GtkWidget *dialog;
            dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_DESTROY_WITH_PARENT, GTK_MESSAGE_ERROR,
                GTK_BUTTONS_OK, "Error: cannot save file");
            gtk_window_set_title(GTK_WINDOW(dialog), "Error");
            gtk_dialog_run(GTK_DIALOG(dialog));
            gtk_widget_destroy(dialog);
        }
        fclose(fp);
    }
    gtk_widget_destroy(trigger); 
}

void run_onclick(GtkWidget *widget, gpointer data)
{
    clear_table();
    initialize_table();
    clear_code();
    init_code();
    list_clear(array_ids);

    const char* blank="";
    GtkTextBuffer* output_buffer=gtk_text_view_get_buffer(GTK_TEXT_VIEW(output));
    gtk_text_buffer_set_text(output_buffer,blank,strlen(blank));
    gtk_clist_clear(pcode);
    gtk_clist_clear(symt);

    FILE* fp=fopen("naivecompiler.temp.syntax(busy)","w");
    if(fp!=NULL)
    {
        char* text;
        GtkTextIter start,end;
        GtkTextBuffer* buffer=gtk_text_view_get_buffer(GTK_TEXT_VIEW(x0code));

        gtk_text_buffer_get_bounds(GTK_TEXT_BUFFER(buffer),&start,&end);
        text=gtk_text_buffer_get_text(GTK_TEXT_BUFFER(buffer),&start,&end,FALSE);
        fprintf(fp,"%s",text);
        fclose(fp);

        FILE* temp_fp=fopen("naivecompiler.temp.syntax(busy)","r");
        if(temp_fp!=NULL)
        {
            yyin=temp_fp;
            yyparse();

            if(err==0)
            {
                print_code(pcode);
                interpret(output);
            }
            else
                printf("%d errors in Naive Compiler\n",err);
            print_table(symt);
        }
        fclose(temp_fp);

        remove("naivecompiler.temp.syntax(busy)");
    }
    else
    {
        GtkWidget *dialog;
        dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_DESTROY_WITH_PARENT, GTK_MESSAGE_ERROR,
                GTK_BUTTONS_OK, "Error: fatal error while processing input");
        gtk_window_set_title(GTK_WINDOW(dialog), "Error");
        gtk_dialog_run(GTK_DIALOG(dialog));
        gtk_widget_destroy(dialog);

        fclose(fp);
    }
}

void about_onclick(GtkWidget *widget, gpointer data)
{
    GtkWidget *dialog = gtk_message_dialog_new(GTK_WINDOW(data), 
        GTK_DIALOG_MODAL, GTK_MESSAGE_INFO, 
        GTK_BUTTONS_OK, "Naive Compiler for X0 v1.0");
    gtk_window_set_title(GTK_WINDOW(dialog), "About");
    gtk_message_dialog_format_secondary_text(GTK_MESSAGE_DIALOG(dialog), "https://mizunashi.me");
    gtk_dialog_run(GTK_DIALOG(dialog));
    gtk_widget_destroy(dialog);
}