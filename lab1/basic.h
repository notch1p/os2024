#ifndef basic_h
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define basic_h
char* errormsg[256];
// process control block
struct pcb {
    int pid; // process id
    int ppid; // parent process id
    int prio; // priority
    int state; // state
    int lasttime; // last execute time
    int tottime; // totle execute time
};
// process node tree
struct pnode {
    pcb* node;
    pnode* sub;
    pnode* brother;
    pnode* next;
};
// 信号量
struct semphore {
    char name[5]; // 名称
    int count; // 计数值
    int curpid; // 当前进程id
    pnode* wlist; // 等待链表
};
#define geterror(eno) printf("%s\n", errormsg[eno])

void initerror()
{
    // errormsg[0] = (char*)malloc(20);
    errormsg[0] = "error command!";
    // errormsg[1] = (char*)malloc(20);
    errormsg[1] = "error parameter!";
}
// get a substring in string s
char* substr(char* s, int start, int end)
{
    char* s1;
    int len = strlen(s);
    if (start < 0 || end >= len || start > end)
        return NULL;
    s1 = (char*)malloc(end - start + 2);
    int i;
    for (i = 0; i <= end - start; i++)
        s1[i] = s[i + start];
    s1[i] = '\0';
    return s1;
}
// find the location of c in string s
int instr(char* s, char c)
{
    size_t i;
    for (i = 0; i < strlen(s); i++)
        if (s[i] == c)
            return i;
    return -1;
}
// parse comma delimited string to array
int* strtoarray(char* s)
{
    int *a, count, x1;
    unsigned int i;
    char c, *s1, *s2;
    if (!s) {
        printf("string can't be null!\n");
        return NULL;
    }
    count = 0;
    s1 = s;
    assert(s1);
    for (i = 0; i < strlen(s1); i++)
        if (s1[i] == ',')
            count++;
    count++;
    a = (int*)malloc(count);
    c = ',';
    for (i = 0; i < count; i++) {
        x1 = instr(s1, c);
        if (x1 >= 0)
            s2 = substr(s1, 0, x1 - 1);
        else
            s2 = s1;
        a[i] = atoi(s2);
        if (c == ',')
            s1 = substr(s1, x1 + 1, strlen(s1) - 1);
    }
    return a;
}
#endif
