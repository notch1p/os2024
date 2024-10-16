#include "basic.h"
#include <cstdarg>


semphore sem[5]; // deinfe 5 semphores
pnode* pr[20]; // define 0-19 total 20 process

// down operation -- P
void down(char* sname, int pid)
{
    int fflag, pflag;
    pnode *p, *p1;
    semphore* s;
    fflag = 0;
    pflag = 0;
    for (int i = 0; i < 5; i++)
        if (!strcmp(sem[i].name, sname)) // find semaphore by name
        {
            s = &sem[i];
            fflag = 1;
            break;
        }
    for (int i = 0; i < 20; i++) // find pcb by pid
        if (pr[i]->node->pid == pid) {
            p1 = pr[i];
            pflag = 1;
            break;
        }
    if (!fflag) // semaphore is not exist
    {
        printf("the semphore '%s' is not exist!\n", sname);
        return;
    }
    if (!pflag) // pid is not exist
    {
        printf("the process '%d' is not exist!\n", pid);
        return;
    }
    s->count--; // semaphore! s value -1
    if (s->count >= 0) // this pcb get the semaphore
        s->curpid = p1->node->pid;
    else {
        if (s->wlist) // the link is not NULL, add the pcb to the last
        {
            for (p = s->wlist; p->next; p = p->next)
                ;
            p->next = p1;
        } else // this pcb is the first pcb be added to the down list
            s->wlist = p1;
    }
}

void downs(int pid, int varargs_length, char* s_name, ...)
{
    va_list args;
    va_start(args, s_name);
    for (int i = 0; i < varargs_length; i++) {
        down(va_arg(args, char*), pid);
    }
    va_end(args);
}

// up operation -- V
void up(char* sname)
{
    int fflag = 0, i;
    for (i = 0; i < 5; i++)
        if (!strcmp(sem[i].name, sname)) // find the semaphore by name
        {
            fflag = 1;
            break;
        }
    if (fflag) // find it
    {
        sem[i].count++;
        if (sem[i].wlist) // there are processes in the down list
        {
            sem[i].curpid = sem[i].wlist->node->pid;
            sem[i].wlist = sem[i].wlist->next;
        }
    } else
        printf("the semphore '%s' is not exist!\n", sname);
}

// show semphore infomation
void showdetail()
{
    int i;
    pnode* p;
    printf("\n");
    for (i = 0; i < 5; i++) {
        if (sem[i].count <= 0) {
            printf("%s, count = %d (current_process%d):", sem[i].name, sem[i].count, sem[i].curpid);
            p = sem[i].wlist;
            while (p) {
                printf("%5d", p->node->pid);
                p = p->next;
            }
        } else
            printf("%s, count = %d :", sem[i].name, sem[i].count);
        printf("\n");
    }
}

/***************************************************************/
void init()
{
    // init semaphore
    strcat(sem[0].name, "s0");
    strcat(sem[1].name, "s1");
    strcat(sem[2].name, "s2");
    strcat(sem[3].name, "s3");
    strcat(sem[4].name, "s4");
    for (int i = 0; i < 5; i++) {
        sem[i].wlist = NULL;
        sem[i].count = 1;
    }
    // init process
    for (int i = 0; i < 20; i++) {
        pr[i] = new pnode;
        pr[i]->node = new pcb;
        pr[i]->node->pid = i;
        pr[i]->brother = NULL;
        pr[i]->next = NULL;
        pr[i]->sub = NULL;
    }
    // for (int i = 0; i < 12; i++) {
    //     down("s0", i);
    // }
}

int main()
{
    short cflag, pflag;
    char cmdstr[32];
    char *s, *s1, *s2;

    initerror();
    init();

    for (;;) {
        cflag = 0;
        pflag = 0;
        printf("cmd:");
        scanf("%s", cmdstr);
        if (!strcmp(cmdstr, "exit")) // exit the program
            break;
        if (!strcmp(cmdstr, "showdetail")) {
            cflag = 1;
            pflag = 1;
            showdetail();
        } else {
            s = strstr(cmdstr, "down"); // create process
            if (s) {
                cflag = 1;
                // getparameter
                s1 = substr(s, instr(s, '(') + 1, instr(s, ',') - 1);
                s2 = substr(s, instr(s, ',') + 1, instr(s, ')') - 1);
                if (s1 && s2) {
                    down(s1, atoi(s2));
                    pflag = 1;
                }
            } else {
                s = strstr(cmdstr, "up"); // delete process
                if (s) {
                    cflag = 1;
                    s1 = substr(s, instr(s, '(') + 1, instr(s, ')') - 1);
                    if (s1) {
                        up(s1);
                        pflag = 1;
                    }
                }
            }
        }
        if (!cflag)
            geterror(0);
        else if (!pflag)
            geterror(1);
    }
}
