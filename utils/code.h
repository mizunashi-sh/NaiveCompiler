#ifndef CODE_H_
#define CODE_H_
#include "symtable.h"
#include <gtk/gtk.h>

#define CXMAX 1000
#define MAX_LOOP 50
#define STACKSIZE 10000

int cx;
int err;

enum fct
{
	lit,
	opr,
	lod,
	sto,
	cal,
	ini,
	jmp,
	jpc,
	ext
};
enum inloop
{
	brks,
	ctn
};
const char *mnemonic[9] = {"lit", "opr", "lod", "sto", "cal", "ini", "jmp", "jpc", "ext"};

int array_id = 0;

typedef struct instruction
{
	enum fct f;
	int l;
	int a;
	int isd;
	double d;
} Instruction;
struct instruction code[CXMAX + 1];

typedef struct stack
{
	int vi;
	double vd;
	enum type ele_type;
} Stack;

struct loop
{
	int cx;
	enum inloop type;
	int level;
};
struct loop loopRegister[MAX_LOOP];
int loop_position = 0;
int loop_level = 0;

void init_code()
{
	loop_position = 0;
	loop_level = 0;
	array_id = 0;
	cx=0;
	err=0;
}

void clear_code()
{
	memset(code,0,sizeof(Instruction)*(CXMAX+1));
	memset(loopRegister,0,sizeof(struct loop)*MAX_LOOP);
}

void code_error(char *s)
{
	char text[500];
	sprintf(text, "%s", s);
	GtkWidget *dialog;
    dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_DESTROY_WITH_PARENT, GTK_MESSAGE_ERROR,
                GTK_BUTTONS_OK, text);
    gtk_window_set_title(GTK_WINDOW(dialog), "Code Error");
    gtk_dialog_run(GTK_DIALOG(dialog));
    gtk_widget_destroy(dialog);
	exit(1);
}

void _gen(enum fct x, int y, int z, int isd, double d)
{
	if (cx > CXMAX)
		printf("program too long!");
	code[cx].f = x;
	code[cx].l = y;
	code[cx].a = z;
	code[cx].isd = isd;
	code[cx].d = d;
	cx++;
}

void gen(enum fct x, int y, int z)
{
	_gen(x, y, z, 0, 0.0);
}

void print_code(GtkWidget* frame)
{
	for (int i = 0; i <= cx - 1; i++)
	{
		char id_s[15], f_s[20], l_s[20], a_s[20],isd_s[20],d_s[20];
		sprintf(id_s,"%d",i);
		sprintf(f_s,"%s",mnemonic[(int)code[i].f]);
		sprintf(l_s,"%d",code[i].l);
		sprintf(a_s,"%d",code[i].a);
		sprintf(isd_s,"%d",code[i].isd);
		sprintf(d_s,"%lf",code[i].d);

		char* text[]={id_s,f_s,l_s,a_s,isd_s,d_s};
		gtk_clist_append(frame,text);
	}
}

int base(int l, int b, Stack s[STACKSIZE])
{
	int b1;
	b1 = b;
	while (l > 0)
	{
		b1 = s[b1].vi;
		l = l - 1;
	}
	return b1;
}

void interpret(GtkWidget* frame)
{
	int p = 0;
	int b = 0;
	int t = 0;
	Instruction i;
	char out[50];

	GtkTextBuffer* buffer=gtk_text_view_get_buffer(GTK_TEXT_VIEW(frame));
	GtkTextIter start,end;

	struct stack s[STACKSIZE];

	s[0].vi = 0;
	s[0].vd = 0.0;
	s[0].ele_type = int_t;
	s[1].vi = 0;
	s[1].vd = 0.0;
	s[1].ele_type = int_t;
	s[2].vi = 0;
	s[2].vd = 0.0;
	s[2].ele_type = int_t;
	s[3].vi = 0;
	s[3].vd = 0.0;
	s[3].ele_type = int_t;

	int ti = tx;
	while (ti >= 0)
	{
		if (table[ti].var_category == variable)
		{
			if (table[ti].is_array)
			{
				int len = list_len(table[tx].array_size);
				int tj;
				if (table[ti].var_type == real_t)
				{
					for (tj = table[ti].address; tj < (table[ti].address + len); tj++)
					{
						s[tj].ele_type = real_t;
					}
				}
				else
				{
					for (tj = table[ti].address; tj < (table[ti].address + len); tj++)
					{
						s[tj].ele_type = int_t;
					}
				}
			}
			else
			{
				if (table[ti].var_type == real_t)
				{
					s[table[ti].address].ele_type = real_t;
				}
				else
				{
					s[table[ti].address].ele_type = int_t;
				}
			}
		}
		ti--;
	}

	do
	{
		i = code[p];
		p = p + 1;
		switch (i.f)
		{
		case lit:
			t = t + 1;
			if (i.isd)
			{
				s[t].ele_type = real_t;
				s[t].vd = i.d;
			}
			else
			{
				s[t].ele_type = int_t;
				s[t].vi = i.a;
			}
			break;
		case opr:
			switch (i.a)
			{
			case 0:
				p = 0;
				break;
			case 1:
				if (i.isd)
				{
					s[t].ele_type = real_t;
					s[t].vd = -s[t].vd;
				}
				else
				{
					s[t].ele_type = int_t;
					s[t].vi = -s[t].vi;
				}
				break;
			case 2:
				t = t - 1;
				if (s[t].ele_type == real_t && s[t + 1].ele_type == real_t)
				{
					s[t].ele_type = real_t;
					s[t].vd = s[t].vd + s[t + 1].vd;
				}
				else if (s[t].ele_type == real_t && s[t + 1].ele_type == int_t)
				{
					s[t].ele_type = real_t;
					s[t].vd = s[t].vd + s[t + 1].vi;
				}
				else if (s[t].ele_type == int_t && s[t + 1].ele_type == real_t)
				{
					s[t].ele_type = real_t;
					s[t].vd = s[t].vi + s[t + 1].vd;
				}
				else if (s[t].ele_type == int_t && s[t + 1].ele_type == int_t)
				{
					s[t].ele_type = int_t;
					s[t].vi = s[t].vi + s[t + 1].vi;
				}
				break;
			case 3:
				t = t - 1;
				if (s[t].ele_type == real_t && s[t + 1].ele_type == real_t)
				{
					s[t].ele_type = real_t;
					s[t].vd = s[t].vd - s[t + 1].vd;
				}
				else if (s[t].ele_type == real_t && s[t + 1].ele_type == int_t)
				{
					s[t].ele_type = real_t;
					s[t].vd = s[t].vd - s[t + 1].vi;
				}
				else if (s[t].ele_type == int_t && s[t + 1].ele_type == real_t)
				{
					s[t].ele_type = real_t;
					s[t].vd = s[t].vi - s[t + 1].vd;
				}
				else if (s[t].ele_type == int_t && s[t + 1].ele_type == int_t)
				{
					s[t].ele_type = int_t;
					s[t].vi = s[t].vi - s[t + 1].vi;
				}
				break;
			case 4:
				t = t - 1;
				if (s[t].ele_type == real_t && s[t + 1].ele_type == real_t)
				{
					s[t].ele_type = real_t;
					s[t].vd = s[t].vd * s[t + 1].vd;
				}
				else if (s[t].ele_type == real_t && s[t + 1].ele_type == int_t)
				{
					s[t].ele_type = real_t;
					s[t].vd = s[t].vd * s[t + 1].vi;
				}
				else if (s[t].ele_type == int_t && s[t + 1].ele_type == real_t)
				{
					s[t].ele_type = real_t;
					s[t].vd = s[t].vi * s[t + 1].vd;
				}
				else if (s[t].ele_type == int_t && s[t + 1].ele_type == int_t)
				{
					s[t].ele_type = int_t;
					s[t].vi = s[t].vi * s[t + 1].vi;
				}
				break;
			case 5:
				t = t - 1;
				if (s[t].ele_type == real_t && s[t + 1].ele_type == real_t)
				{
					s[t].ele_type = real_t;
					s[t].vd = s[t].vd / s[t + 1].vd;
				}
				else if (s[t].ele_type == real_t && s[t + 1].ele_type == int_t)
				{
					s[t].ele_type = real_t;
					s[t].vd = s[t].vd / s[t + 1].vi;
				}
				else if (s[t].ele_type == int_t && s[t + 1].ele_type == real_t)
				{
					s[t].ele_type = real_t;
					s[t].vd = s[t].vi / s[t + 1].vd;
				}
				else if (s[t].ele_type == int_t && s[t + 1].ele_type == int_t)
				{
					s[t].ele_type = int_t;
					s[t].vi = s[t].vi / s[t + 1].vi;
				}
				break;
			case 6:
				if (s[t].ele_type == real_t)
				{
					code_error("top of the stack is a double so that we do not know if it is odd.");
				}
				if ((s[t].vi) % 2 == 0)
					s[t].vi = 0;
				else
					s[t].vi = 1;
				break;
			case 8:
				t = t - 1;
				if (s[t].ele_type == real_t || s[t + 1].ele_type == real_t)
				{
					code_error("tops of the stack are doubles so that we do not know if one is equals to another.");
				}
				if (s[t].vi == s[t + 1].vi)
					s[t].vi = 1;
				else
					s[t].vi = 0;
				break;
			case 9:
				t = t - 1;
				if (s[t].ele_type == real_t || s[t + 1].ele_type == real_t)
				{
					code_error("tops of the stack are doubles so that we do not know if one is equals to another.");
				}
				if (s[t].vi != s[t + 1].vi)
					s[t].vi = 1;
				else
					s[t].vi = 0;
				break;
			case 10:
				t--;
				if (s[t].ele_type == real_t && s[t + 1].ele_type == real_t)
				{
					s[t].vi = s[t].vd < s[t + 1].vd;
				}
				else if (s[t].ele_type == real_t && s[t + 1].ele_type == int_t)
				{
					s[t].vi = s[t].vd < s[t + 1].vi;
				}
				else if (s[t].ele_type == int_t && s[t + 1].ele_type == real_t)
				{
					s[t].vi = s[t].vi < s[t + 1].vd;
				}
				else if (s[t].ele_type == int_t && s[t + 1].ele_type == int_t)
				{
					s[t].vi = s[t].vi < s[t + 1].vi;
				}
				s[t].ele_type = int_t;
				break;
			case 11:
				t--;
				if (s[t].ele_type == real_t && s[t + 1].ele_type == real_t)
				{
					s[t].vi = s[t].vd >= s[t + 1].vd;
				}
				else if (s[t].ele_type == real_t && s[t + 1].ele_type == int_t)
				{
					s[t].vi = s[t].vd >= s[t + 1].vi;
				}
				else if (s[t].ele_type == int_t && s[t + 1].ele_type == real_t)
				{
					s[t].vi = s[t].vi >= s[t + 1].vd;
				}
				else if (s[t].ele_type == int_t && s[t + 1].ele_type == int_t)
				{
					s[t].vi = s[t].vi >= s[t + 1].vi;
				}
				s[t].ele_type = int_t;
				break;
			case 12:
				t = t - 1;
				if (s[t].ele_type == real_t && s[t + 1].ele_type == real_t)
				{
					s[t].vi = s[t].vd > s[t + 1].vd;
				}
				else if (s[t].ele_type == real_t && s[t + 1].ele_type == int_t)
				{
					s[t].vi = s[t].vd > s[t + 1].vi;
				}
				else if (s[t].ele_type == int_t && s[t + 1].ele_type == real_t)
				{
					s[t].vi = s[t].vi > s[t + 1].vd;
				}
				else if (s[t].ele_type == int_t && s[t + 1].ele_type == int_t)
				{
					s[t].vi = s[t].vi > s[t + 1].vi;
				}
				s[t].ele_type = int_t;
				break;
			case 13:
				t = t - 1;
				if (s[t].ele_type == real_t && s[t + 1].ele_type == real_t)
				{
					s[t].vi = s[t].vd <= s[t + 1].vd;
				}
				else if (s[t].ele_type == real_t && s[t + 1].ele_type == int_t)
				{
					s[t].vi = s[t].vd <= s[t + 1].vi;
				}
				else if (s[t].ele_type == int_t && s[t + 1].ele_type == real_t)
				{
					s[t].vi = s[t].vi <= s[t + 1].vd;
				}
				else if (s[t].ele_type == int_t && s[t + 1].ele_type == int_t)
				{
					s[t].vi = s[t].vi <= s[t + 1].vi;
				}
				s[t].ele_type = int_t;
				break;
			case 14:
				if (s[t].ele_type == real_t)
				{
					sprintf(out, "%lf", s[t].vd);
				}
				else
				{
					sprintf(out, "%d", s[t].vi);
				}
				gtk_text_buffer_get_bounds(GTK_TEXT_BUFFER(buffer),&start,&end);
				gtk_text_buffer_insert(GTK_TEXT_BUFFER(buffer),&end,out,strlen(out));
				t = t - 1;
				break;
			case 15:
				sprintf(out, "\n");
				gtk_text_buffer_get_bounds(GTK_TEXT_BUFFER(buffer),&start,&end);
				gtk_text_buffer_insert(GTK_TEXT_BUFFER(buffer),&end,out,strlen(out));
				break;
			case 16:
				t = t + 1;
				s[t].ele_type = int_t;
				GtkWidget *dialog;
    			GtkWidget *title;
    			GtkWidget *input;
    			GtkWidget *table;
				dialog=gtk_dialog_new_with_buttons("Input",NULL,GTK_DIALOG_MODAL,GTK_STOCK_OK,GTK_RESPONSE_OK,NULL);
    			gtk_dialog_set_default_response(GTK_DIALOG(dialog),GTK_RESPONSE_OK);  

    			title=gtk_label_new("It's time to input");
    			input=gtk_entry_new();
    			table=gtk_table_new(2,2,FALSE);
    			gtk_table_attach_defaults(GTK_TABLE(table),title,0,1,0,1); 
    			gtk_table_attach_defaults(GTK_TABLE(table),input,0,2,1,2);

    			gtk_table_set_row_spacings(GTK_TABLE(table),5);  
    			gtk_table_set_col_spacings(GTK_TABLE(table),5);  
    			gtk_container_set_border_width(GTK_CONTAINER(table),5);
    			gtk_box_pack_start_defaults(GTK_BOX(GTK_DIALOG(dialog)->vbox),table); 
    			gtk_widget_show_all(dialog);

    			gint result=gtk_dialog_run(GTK_DIALOG(dialog));
				if(result==-5)
				{
					if (i.isd)
					{
						s[t].vd=atof(gtk_entry_get_text(GTK_ENTRY(input)));
					}
				else
					{
						s[t].vi=atoi(gtk_entry_get_text(GTK_ENTRY(input)));
					}
				}
				else
				{
					if (i.isd)
					{
						s[t].vd=0;
					}
					else
					{
						s[t].vi=0;
					}
				}
				gtk_widget_destroy(dialog);
				break;
			case 17: 
				if (s[t].ele_type == real_t)
				{
					code_error("top of the stack is a double so that we cannot write a charater.");
				}
				sprintf(out, "%c", s[t].vi);
				gtk_text_buffer_get_bounds(GTK_TEXT_BUFFER(buffer),&start,&end);
				gtk_text_buffer_insert(GTK_TEXT_BUFFER(buffer),&end,out,strlen(out));
				t = t - 1;
				break;
			case 18: 
				if (s[t].ele_type == real_t)
				{
					code_error("top of the stack is a double so that we cannot write from a double address.");
				}
				if (s[s[t].vi].ele_type == real_t)
				{
					sprintf(out, "%lf", s[s[t].vi].vd);
					gtk_text_buffer_get_bounds(GTK_TEXT_BUFFER(buffer),&start,&end);
					gtk_text_buffer_insert(GTK_TEXT_BUFFER(buffer),&end,out,strlen(out));
				}
				else
				{
					sprintf(out, "%d", s[s[t].vi].vi);
					gtk_text_buffer_get_bounds(GTK_TEXT_BUFFER(buffer),&start,&end);
					gtk_text_buffer_insert(GTK_TEXT_BUFFER(buffer),&end,out,strlen(out));
				}
				t = t - 1;
				break;
			case 19: 
				if (s[t].ele_type == real_t)
				{
					code_error("top of the stack is a double so that we cannot write a charater to an address.");
				}
				if (s[s[t].vi].ele_type == real_t)
				{
					code_error("adr of the stack is a double so that we cannot write a charater.");
				}
				sprintf(out, "%c", s[s[t].vi].vi);
				gtk_text_buffer_get_bounds(GTK_TEXT_BUFFER(buffer),&start,&end);
				gtk_text_buffer_insert(GTK_TEXT_BUFFER(buffer),&end,out,strlen(out));
				t = t - 1;
				break;
			case 20: 
				t = t - 1;
				if (s[t].ele_type == real_t || s[t + 1].ele_type == real_t)
				{
					code_error("tops of the stack are doubles so that one cannot mod another.");
				}
				s[t].vi = s[t].vi % s[t + 1].vi;
				break;
			case 21: 
				t = t - 1;
				if (s[t].ele_type == real_t || s[t + 1].ele_type == real_t)
				{
					code_error("tops of the stack are doubles so that one cannot xor another.");
				}
				s[t].vi = s[t].vi ^ s[t + 1].vi;
				break;
			case 22: 
				t = t - 1;
				if (s[t].ele_type == real_t || s[t + 1].ele_type == real_t)
				{
					code_error("tops of the stack are doubles so that one cannot and another.");
				}
				s[t].vi = s[t].vi && s[t + 1].vi;
				break;
			case 23: 
				t = t - 1;
				if (s[t].ele_type == real_t || s[t + 1].ele_type == real_t)
				{
					code_error("tops of the stack are doubles so that one cannot or another.");
				}
				s[t].vi = s[t].vi || s[t + 1].vi;
				break;
			case 24: 
				if (s[t].ele_type == real_t)
				{
					code_error("top of the stack is double so that one cannot do |not|.");
				}
				s[t].vi = !s[t].vi;
				break;
			case 25: 
				if (s[t].ele_type == real_t)
				{
					code_error("tops of the stack are doubles so that one cannot be writen.");
				}
				sprintf(out, "%s", s[t].vi == 0 ? "false" : "true");
				gtk_text_buffer_get_bounds(GTK_TEXT_BUFFER(buffer),&start,&end);
				gtk_text_buffer_insert(GTK_TEXT_BUFFER(buffer),&end,out,strlen(out));
				t = t - 1;
				break;
			case 26: 
				t = t - 1;
				break;
			}
			break;
		case lod:
			if (i.a == 0) 
			{
				if (s[t].ele_type == real_t)
				{
					code_error("top of the stack is a double so that we cannot lod from a double address.");
				}
				if (s[t].vi >= table[array_id].address + list_len(table[array_id].array_size))
				{
					code_error("\narray index out of range.");
				}
				if (s[base(i.l, b, s) + s[t].vi].ele_type == real_t)
				{
					s[t].ele_type = real_t;
					s[t].vd = s[base(i.l, b, s) + s[t].vi].vd;
				}
				else
				{
					s[t].ele_type = int_t;
					s[t].vi = s[base(i.l, b, s) + s[t].vi].vi;
				}
			}
			else
			{
				t = t + 1;
				if (s[base(i.l, b, s) + i.a].ele_type == real_t)
				{
					s[t].ele_type = real_t;
					s[t].vd = s[base(i.l, b, s) + i.a].vd;
				}
				else
				{
					s[t].ele_type = int_t;
					s[t].vi = s[base(i.l, b, s) + i.a].vi;
				}
			}
			break;
		case sto:
			if (i.a == 0) 
			{
				if (s[t - 1].ele_type == real_t)
				{
					code_error("top of the stack is a double so that we cannot lod from a double address.");
				}
				if (s[t - 1].vi >= table[array_id].address + list_len(table[array_id].array_size))
				{
					code_error("\narray index out of range.");
				}
				if (s[base(i.l, b, s) + s[t - 1].vi].ele_type == real_t)
				{
					if (s[t].ele_type == real_t)
					{
						s[base(i.l, b, s) + s[t - 1].vi].vd = s[t].vd;
						s[t - 1].ele_type = s[base(i.l, b, s) + s[t - 1].vi].ele_type;
						s[t - 1].vd = s[t].vd;
					}
					else
					{
						s[base(i.l, b, s) + s[t - 1].vi].vd = s[t].vi;
						s[t - 1].ele_type = s[base(i.l, b, s) + s[t - 1].vi].ele_type;
						s[t - 1].vd = s[t].vi;
					}
				}
				else
				{
					if (s[t].ele_type == real_t)
					{
						s[base(i.l, b, s) + s[t - 1].vi].vi = (int)s[t].vd;
						s[t - 1].ele_type = s[base(i.l, b, s) + s[t - 1].vi].ele_type;
						s[t - 1].vi = (int)s[t].vd;
					}
					else
					{
						s[base(i.l, b, s) + s[t - 1].vi].vi = s[t].vi;
						s[t - 1].ele_type = s[base(i.l, b, s) + s[t - 1].vi].ele_type;
						s[t - 1].vi = s[t].vi;
					}
				}
				t = t - 1;
			}
			else
			{
				if (s[base(i.l, b, s) + i.a].ele_type == real_t)
				{
					if (s[t].ele_type == real_t)
					{
						s[base(i.l, b, s) + i.a].vd = s[t].vd;
					}
					else
					{
						s[base(i.l, b, s) + i.a].vd = s[t].vi;
					}
				}
				else
				{
					if (s[t].ele_type == real_t)
					{
						s[base(i.l, b, s) + i.a].vi = (int)s[t].vd;
					}
					else
					{
						s[base(i.l, b, s) + i.a].vi = s[t].vi;
					}
				}
				t = t - 1;
			}
			break;
		case cal:
			break;
		case ini:
			t = t + i.a;
			break;
		case jmp:
			p = i.a;
			break;
		case jpc:
			if (s[t].ele_type == real_t)
			{
				code_error("top of the stack is a double so that we do not know if it is equals to zero.");
			}
			if (s[t].vi == 0)
				p = i.a;
			t = t - 1;
			break;
		case ext: 
			p = 0;
			break;
		}
	} while (p != 0);
}
#endif