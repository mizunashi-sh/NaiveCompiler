#ifndef LIST_H_
#define LIST_H_
#include <stdlib.h>
#include <stdio.h>

typedef struct list{
    int val;
    struct list *next;
}List;

int list_len(List* head)
{
	List* each = head;
	int len=1;
	if(head==NULL){
		len=0;
	}else{
		do{
			len*=each->val;
			each = each->next;
		}while(each!=NULL);
	}
	return len;
}

int list_get_last_item(List* head)
{
	if(head==NULL){
		fprintf(stderr,"array is empty!");
		return -1;
	}
	List* each = head;
	while(each->next!=NULL)
		each = each->next;
	return each->val;
}

int list_remove_last_item(List* head)
{
	if(head==NULL){
		return 0;
	}
	List* each = head;
	List* before=head;
	while(each->next!=NULL){
		before=each;
		each = each->next;
	}
	before->next=NULL;
	free(each);
	each=NULL;
	return 0;
}

int list_get_item_after_id(List* head, int id)
{
	int p=1,i=0;
	List* each = head;
	if(head==NULL){
		return 0;
	}
	while(each!=NULL){
		if(i++>id)
			p*=each->val;
		each = each->next;
	}
	return p;
}

int list_get_item_by_id(List* head, int id)
{
	int i;
	List* each = head;
	for(i=0;i<id;i++)
	{
		if(each==NULL){
			fprintf(stderr, "array index out of range!");
			return -1;
		}
		each = each->next;
	}
	if(each==NULL){
		fprintf(stderr, "array index out of range!");
		return -1;
	}
	return each->val;
}

List* list_add_item(List* head, int v)
{
	List* each = head;
	if(head==NULL){
		head = (struct list*)malloc(sizeof(struct list));
		head->val=v;
		head->next=NULL;
	}else{
		while(each->next!=NULL)
			each = each->next;
		List* tmp = (struct list*)malloc(sizeof(struct list));
		tmp->val=v;
		tmp->next=NULL;
		each->next=tmp;
	}
	return head;
}

void list_clear(List* head)
{
	List *node;
    while (NULL != head){
        node = head;
        head = head -> next;
        free(node);
    }
}
#endif