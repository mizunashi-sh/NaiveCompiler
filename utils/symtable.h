#ifndef SYMTABLE_H_
#define SYMTABLE_H_

#include "stdio.h"
#include "string.h"
#include "stdlib.h"
#include "list.h"
#include <gtk/gtk.h>

#define MAX_ID_LENGTH 20
#define MAX_ADDRESS 4096
#define MAX_LEVEL 4
#define MAX_CX 400
#define MAX_TX 200
#define AMAX 65535

enum object{
    constant,
    variable,
    procedure,
};

enum type{
    int_t,
    char_t,
    real_t,
    bool_t,
    none,
};

typedef struct tablestruct
{
    char name[MAX_ID_LENGTH];
    enum type var_type;
    enum object var_category;
    int val;
    int level;
    int address;
    int size;
    int is_array;
    int array_dim;
    double real_val;
    List* array_size;
}tableStruct;
tableStruct table[MAX_TX];

int level=0;
int tx=0;
int dx=0;
int num;
double real_num;
int size;
int is_array_rec;
int array_dim;
char id[MAX_ID_LENGTH];
int err_count;
extern int line_count;
List* array_size=NULL;
enum type instance_type;

void initialize_table()
{
    level=0;
    tx=0;
    dx=0;
    err_count=0;
    line_count=0;
    list_clear(array_size);
}

void clear_table()
{
    memset(table,0,sizeof(tableStruct)*MAX_TX);
}

void error(int n)
{
    char text[100];
    sprintf(text, "error %d", n);

    GtkWidget *dialog;
    dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_DESTROY_WITH_PARENT, GTK_MESSAGE_ERROR,
                GTK_BUTTONS_OK, text);
    gtk_window_set_title(GTK_WINDOW(dialog), "Compiler Error");
    gtk_dialog_run(GTK_DIALOG(dialog));
    gtk_widget_destroy(dialog);
    exit(1);
}

void syntax_error(const char* s)
{
    char text[500];
    err_count++;
    sprintf(text, "syntax error in line %d: %s\n", line_count+1, s);
    GtkWidget *dialog;
    dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_DESTROY_WITH_PARENT, GTK_MESSAGE_ERROR,
                GTK_BUTTONS_OK, text);
    gtk_window_set_title(GTK_WINDOW(dialog), "Syntax Error");
    gtk_dialog_run(GTK_DIALOG(dialog));
    gtk_widget_destroy(dialog);
    exit(1);
}

void enter(enum object obj)
{
    tx=tx+1;
    strcpy(table[tx].name,id);
    table[tx].var_category=obj;
    
    switch(obj){
        case constant:
            if(instance_type==real_t){
                table[tx].val=0;
                table[tx].real_val=real_num;
            }
            else{
                if(num>AMAX){
					error(31);
					num=0;
				}
                table[tx].val=num;
                table[tx].real_val=0;
            }
            table[tx].var_type=instance_type;
            break;
        case variable:
            table[tx].address=dx;
            table[tx].var_type=instance_type;
            if(is_array_rec){
                table[tx].is_array=1;
                table[tx].array_dim=array_dim;
                table[tx].array_size=array_size;
                dx=dx+list_len(table[tx].array_size);
            }
            else{
                table[tx].is_array=0;
                dx++;
            }
            break;
        case procedure:
            break;
    }
}

int get_position(char id[MAX_ID_LENGTH])
{
    int i=tx;
    while(strcmp(table[i].name,id)!=0){
        i--;
        if(i==0) break;
    }
    return i;
}

void print_table(GtkWidget* frame)
{
	char kind[15];
	char type[15];
    char val_s[20];
    char real_val_s[20];
    char address_s[20];
    char size_s[20];
    char is_array_s[20];
    char array_dim_s[20];

    for(int i=0;i<=tx;i++)
	{
        switch(table[i].var_category)
		{
			case constant:
				strcpy(kind, "constant");
				break;
			case variable:
				strcpy(kind, "variable");
				break;
			case procedure:
				strcpy(kind, "procedure");
				break;
		}
        switch(table[i].var_type)
		{
			case int_t:
				strcpy(type, "int");
				break;
			case char_t:
				strcpy(type, "char");
				break;
			case real_t:
				strcpy(type, "real");
				break;
			case bool_t:
				strcpy(type, "bool");
				break;
			case none:
				strcpy(type, "none");
				break;
		}
        sprintf(val_s,"%d",table[i].val);
        sprintf(real_val_s,"%lf",table[i].real_val);
        sprintf(address_s,"%d",table[i].address);
        sprintf(size_s,"%d",table[i].size);
        sprintf(is_array_s,"%d",table[i].is_array);
        sprintf(array_dim_s,"%d",table[i].array_dim);
        char* text[]={table[i].name, kind, val_s, real_val_s, type, address_s,size_s,is_array_s,array_dim_s};
        gtk_clist_append(frame,text);
    }
}
#endif