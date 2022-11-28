#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
//#include "user/echo.c"
#include "file.c"
#include "stat.h"
#include "fs.h"
#include "sleeplock.h"
#include "file.h"
#include "fcntl.h"
//Red-Black Tree data structure
struct redblackTree {
  int count;
  int rbTreeWeight;
  struct proc *root;
  struct proc *min_vRuntime;
  struct spinlock lock;
  int period;
}rbTree;
struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

 

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;
static struct redblackTree *runnableTasks = &rbTree;

//Set target scheduler latency and minimum granularity constants
//Latency must be multiples of min_granularity
static int latency = NPROC / 2;
static int min_granularity = 2;

////////Red Black Tree functions for operations of Insertion and retrieving, while maintaining Red Black Tree properties

/*
  rbinit(struct redblackTree*, char)
  parameters: pointer that contains the address of the red-black tree and a string containing the name of the lock
  returns: none
  This function will initialize the red black tree data structure.
*/
void
rbinit(struct redblackTree *tree, char *lockName)
{
  initlock(&tree->lock, lockName);
  tree->count = 0;
  tree->root = 0;
  tree->rbTreeWeight = 0;
  tree->min_vRuntime = 0;

  //Initially set time slice factor for all processes
  tree->period = latency;
}

/*
  calculateWeight(int)
  parameters: the process's niceValue
  returns: an integer that signifies the weight of the process the address points to.
  This function will calculate each individual process's weight in respect to it's nice value.
  //-Nice value can be in between -20 to 19 in the linux kernel, but for our xv6 implementation we will use the range 0 to 30
  The default nice value for a process is set to 0
  The formula to determine weight of process is:
  1024/(1.25 ^ nice value of process)
*/
int
calculateWeight(int nice){

  double denominator = 1.25;

  //In order to ensure correct utilization of process priority during the time slice calculation
  //If a process has a higher nice value given, then for the formula to accurately utlize the priority level without losing precision
  //due to fraction casted to an int, it will give it a default value that will represent the same priority level in the system.
  if(nice > 30){
	nice = 30;
  }
  
  //While loop to calculate (1.25 ^ nice value) for denominator of formula to find weight. 
  int iterator = 0;
  while (iterator < nice && nice > 0){
  	denominator = denominator * 1.25;
    iterator++;
  }

  return (int) (1024/denominator);
}

/*
  emptyTree(struct redblackTree*)
  parameters: pointer that contains the address of the red-black tree structure
  returns: none
  This function will determine if the tree is empty or not, i.e the tree has no processes in it.
*/
int
emptyTree(struct redblackTree *tree)
{
  return tree->count == 0;
}

/*
  fullTree(struct redblackTree*)
  parameters: pointer that contains the address of the red-black tree structure
  returns: none
  This function will determine if the tree is full, i.e the maximum alloted number of processes in the system
*/
int
fullTree(struct redblackTree *tree)
{
  return tree->count == NPROC;
}

//This two process retrieval functions will retrive the grandparent or uncle process of the process passed into the functions. This is done to preserve red black tree properties by altering states and positions of the tree.
struct proc*
retrieveGrandparentproc(struct proc* process){
  if(process != 0 && process->parentP != 0){
	return process->parentP->parentP;
  } 
	
  return 0;
}

struct proc*
retrieveUncleproc(struct proc* process){
  struct proc* grandParent = retrieveGrandparentproc(process);
  if(grandParent != 0){
	if(process->parentP == grandParent->left){
		return grandParent->right;
	} else {
		return grandParent->left;
	}
  }
	
  return 0;
}


/*
  rotateLeft(struct redblackTree*, struct proc*)
  parameters:The red black tree pointer to access and modify the root, and the current process in the tree that will be rotated to the left
  returns:none
  This function will perform a rotation on the process structure in the tree that is passed into the function. 
  It will perform a left rotation, where it will move down leftward in the tree and its right process will be moved up to its place.
*/
void 
rotateLeft(struct redblackTree* tree, struct proc* positionProc){
  struct proc* save_right_Proc = positionProc->right;
	
  positionProc->right = save_right_Proc->left;
  if(save_right_Proc->left != 0)
	save_right_Proc->left->parentP = positionProc;
  save_right_Proc->parentP = positionProc->parentP;
	
  if(positionProc->parentP == 0){
	tree->root = save_right_Proc;
  } else if(positionProc == positionProc->parentP->left){
	positionProc->parentP->left = save_right_Proc;
  } else {
	positionProc->parentP->right = save_right_Proc;
  }
  save_right_Proc->left = positionProc;
  positionProc->parentP = save_right_Proc;
}

/*
  rotateRight(struct redblackTree*, struct proc*)
  parameters:The red black tree pointer to access and modify the root, and the current process in the tree that will be rotated to the right
  returns:none
  This function will perform a rotation on the process structure in the tree that is passed into the function. 
  It will perform a right rotation, where it will move down rightward in the tree and its left process will be moved up to its place.
*/
void 
rotateRight(struct redblackTree* tree, struct proc* positionProc){
	
  struct proc* save_left_Proc = positionProc->left;
	
  positionProc->left = save_left_Proc->right;
	
  //Determine parents for the process being rotated
  if(save_left_Proc->right != 0)
	save_left_Proc->right->parentP = positionProc;
  save_left_Proc->parentP = positionProc->parentP;
  if(positionProc->parentP == 0){
	tree->root = save_left_Proc;
  } else if(positionProc == positionProc->parentP->right){
	positionProc->parentP->right = save_left_Proc;
  } else {
	positionProc->parentP->left = save_left_Proc;
  }
  save_left_Proc->right = positionProc;
  positionProc->parentP = save_left_Proc;
	
}

/*
  setMinimumVRuntimeproc(struct proc*)
  parameters: the address of a process in the tree to be utilized to traverse the tree
  returns:A pointer that contains the address to the process with the smallest Virtual Runtime
  This function will return a pointer to the address of the process with the smallest Virtual Runtime. 
  It will do this by traversing through the left branch of the tree until it reaches the process.
*/
struct proc*
setMinimumVRuntimeproc(struct proc* traversingProcess){
	
  if(traversingProcess != 0){
	if(traversingProcess->left != 0){
	    return setMinimumVRuntimeproc(traversingProcess->left);
	} else {
	    return traversingProcess;
	}
  }
	return 0;
}

struct proc*
insertproc(struct proc* traversingProcess, struct proc* insertingProcess){
	
  insertingProcess->coloring = RED;
	
  //i.e it is root or at leaf of tree
  if(traversingProcess == 0){
	return insertingProcess;
  }		
  //i.e everything after root
  //move process to the right of the current subtree
  if(traversingProcess->virtualRuntime <= insertingProcess->virtualRuntime){
	insertingProcess->parentP = traversingProcess;
	traversingProcess->right = insertproc(traversingProcess->right, insertingProcess);
  } else {
	insertingProcess->parentP = traversingProcess;		
	traversingProcess->left = insertproc(traversingProcess->left, insertingProcess);
  }
	
  return traversingProcess;
}

/*
  insertionCases(struct redblackTree*, struct proc*, int)
  parameters: the pointer of the tree, process in the red black tree and an integer value
  returns: none
  This function will contain different cases that will incorporate the properties for a red black tree. It will utilize the integer value to determine which case need to be handled.
  cases:
  -1: if the current inserted process is the root
  -2: if the current inserted process's parent is black
  -3: if both parent and uncle processes are red, then repaint them black
  -4: if parent is red and uncle is black, but current process is red and the current process is right child of parent that is left of grandparent or vice versa
  -5: same as case four but the current process is left child of parent that is left of grandparent or vice versa
*/
void
insertionCases(struct redblackTree* tree, struct proc* rbProcess, int cases){
	
  struct proc* uncle;
  struct proc* grandparent;
	
  switch(cases){
  case 1:
	if(rbProcess->parentP == 0)
		rbProcess->coloring = BLACK;
	else
		insertionCases(tree, rbProcess, 2);
	break;
	
  case 2:
	if(rbProcess->parentP->coloring == RED)
		insertionCases(tree, rbProcess, 3);
	break;
	
  case 3:
	uncle = retrieveUncleproc(rbProcess);
	
	if(uncle != 0 && uncle->coloring == RED){
		rbProcess->parentP->coloring = BLACK;
		uncle->coloring = BLACK;
		grandparent = retrieveGrandparentproc(rbProcess);
		grandparent->coloring = RED;
		insertionCases(tree, grandparent, 1);
		grandparent = 0;
	} else {
		insertionCases(tree, rbProcess,4);
	}
	
	uncle = 0;
	break;
  
  case 4:
	grandparent = retrieveGrandparentproc(rbProcess);
	
	if(rbProcess == rbProcess->parentP->right && rbProcess->parentP == grandparent->left){
		rotateLeft(tree, rbProcess->parentP);
		rbProcess = rbProcess->left;
	} else if(rbProcess == rbProcess->parentP->left && rbProcess->parentP == grandparent->right){
		rotateRight(tree, rbProcess->parentP);
		rbProcess = rbProcess->right;
	}
	insertionCases(tree, rbProcess, 5);
	grandparent = 0;
	break;
	
  case 5:
    grandparent = retrieveGrandparentproc(rbProcess);
	
	if(grandparent != 0){
		grandparent->coloring = RED;
		rbProcess->parentP->coloring = BLACK;
		if(rbProcess == rbProcess->parentP->left && rbProcess->parentP == grandparent->left){
			rotateRight(tree, grandparent);
		} else if(rbProcess == rbProcess->parentP->right && rbProcess->parentP == grandparent->right){
			rotateLeft(tree, grandparent);
		}
	}
	
	grandparent = 0;
	break;
	
  default:
	break;
  }
  return;
}

void
insertProcess(struct redblackTree* tree, struct proc* p){

  acquire(&tree->lock);
  if(!fullTree(tree)){	
	//actually insert process into tree
	tree->root = insertproc(tree->root, p);
	if(tree->count == 0)
		tree->root->parentP = 0;
    	tree->count += 1;
	
	//Calculate process weight
	p->weightValue = calculateWeight(p->niceValue);

	//perform total weight calculation 
	tree->rbTreeWeight += p->weightValue;
	
    	//Check for possible cases for Red Black tree property violations
	insertionCases(tree, p, 1);
		
	//This function call will find the process with the smallest vRuntime, unless 
	//there was no insertion of a process that has a smaller minimum virtual runtime then the process that is being pointed by min_vRuntime
	if(tree->min_vRuntime == 0 || tree->min_vRuntime->left != 0)
		tree->min_vRuntime = setMinimumVRuntimeproc(tree->root);
	 
  }	
  release(&tree->lock);
}

/*
  retrievingCases(struct redblackTree*, struct proc*, struct proc*, int)
  paramters: The red black tree pointer to access and modify the root, the parent of the process, the pointer to the process with the smallest virtual Runtime and the case number
  returns: none
  This function will check for violations of the red black tree to ensure the trees properties are not broken when we remove the process out of the tree. 
  cases:
  -1:We remove the process that needs to be retrieved and ensure that either the process or the process's child is red, but not both of them.
  -2:if both the process we want to remove is black and it has child that is black, then we would have to perform recoloring and rotations to ensure red black tree property is met.
  
*/
void
retrievingCases(struct redblackTree* tree, struct proc* parentProc, struct proc* process, int cases){
  struct proc* parentProcess;
  struct proc* childProcess;
  struct proc* siblingProcess;
  
  switch(cases){
	case 1:
		//Replace smallest virtual Runtime process with its right child 
		parentProcess = parentProc;
		childProcess = process->right;
		
		//if the process being removed is on the root
		if(process == tree->root){
			
			tree->root = childProcess;
			if(childProcess != 0){
				childProcess->parentP = 0;
				childProcess->coloring = BLACK;
			}
			
		} else if(childProcess != 0 && !(process->coloring == childProcess->coloring)){
			//Replace current process by it's right child
			childProcess->parentP = parentProcess;
			parentProcess->left = childProcess;
			childProcess->coloring = BLACK;		
		} else if(process->coloring == RED){		
			parentProcess->left = childProcess;
		} else {	
			if(childProcess != 0)
				childProcess->parentP = parentProcess;
			
			
			parentProcess->left = childProcess;
			retrievingCases(tree, parentProcess, childProcess, 2);
		}
		
		process->parentP = 0;
		process->left = 0;
		process->right = 0;
		parentProcess = 0;
		childProcess = 0;
		break;
		
	case 2:
		
		//Check if process is not root,i.e parentProc != 0, and process is black
		while(process != tree->root && (process == 0 || process->coloring == BLACK)){
			
			////Obtain sibling process
			if(process == parentProc->left){
				siblingProcess = parentProc->right;
				
				if(siblingProcess != 0 && siblingProcess->coloring == RED){
					siblingProcess->coloring = BLACK;
					parentProc->coloring = RED;
					rotateLeft(tree, parentProc);
					siblingProcess = parentProc->right;
				}
				if((siblingProcess->left == 0 || siblingProcess->left->coloring == BLACK) && (siblingProcess->right == 0 || siblingProcess->right->coloring == BLACK)){
					siblingProcess->coloring = RED;
					//Change process pointer and parentProc pointer
					process = parentProc;
					parentProc = parentProc->parentP;
				} else {
					if(siblingProcess->right == 0 || siblingProcess->right->coloring == BLACK){
						//Color left child
						if(siblingProcess->left != 0){
							siblingProcess->left->coloring = BLACK;
						} 
						siblingProcess->coloring = RED;
						rotateRight(tree, siblingProcess);
						siblingProcess = parentProc->right;
					}
					
					siblingProcess->coloring = parentProc->coloring;
					parentProc->coloring = BLACK;
					siblingProcess->right->coloring = BLACK;
					rotateLeft(tree, parentProc);
					process = tree->root;
				}
			} 
		}
		if(process != 0)
			process->coloring = BLACK;
		
		break;
	
	default:
		break;
  }
  return;
	
}

struct proc*
retrieveProcess(struct redblackTree* tree){
  struct proc* foundProcess;	//Process pointer utilized to hold the address of the process with smallest VRuntime 

  acquire(&tree->lock);
  if(!emptyTree(tree)){

	//If the number of processes are greater than the division between latency and minimum granularity
	//then recalculate the period for the processes
	//This condition is performed when the scheduler selects the next process to run
        //The formula can be found in CFS tuning article by Jacek Kobus and Refal Szklarski
	//In the CFS schduler tuning section:
	if(tree->count > (latency / min_granularity)){
		tree->period = tree->count * min_granularity;
	} 

	//retrive the process with the smallest virtual runtime by removing it from the red black tree and returning it
	foundProcess = tree->min_vRuntime;	

	//Determine if the process that is being chosen is runnable at the time of the selection, if it is not, then don't return it.
	if(foundProcess->state != RUNNABLE){
  		release(&tree->lock);
		return 0;
	}

	retrievingCases(tree, tree->min_vRuntime->parentP, tree->min_vRuntime, 1);
	tree->count -= 1;

	//Determine new process with the smallest virtual runtime
	tree->min_vRuntime = setMinimumVRuntimeproc(tree->root);

	//Calculate retrieved process's time slice based on formula: period*(process's weight/ red black tree weight)
	//Where period is the length of the epoch
	//The formula can be found in CFS tuning article by Jacek Kobus and Refal Szklarski
	//In the scheduling section:
	foundProcess->maximumExecutiontime = (tree->period * foundProcess->weightValue / tree->rbTreeWeight);
	
	//Recalculate total weight of red-black tree
	tree->rbTreeWeight -= foundProcess->weightValue;
  } else {
	foundProcess = 0;
  }
  release(&tree->lock);
  return foundProcess;
}

////////

/*
  
  checkPreemption(struct proc*, struct proc*)
  parameters:the currently running/selected process and the process with the smallest vruntime in the red black tree
  return: an iteger value that dictates whether preemption should occur
  This function will determine if the process should be preempted.
  Preemption Cases:
  1-if the current running process virtual runtime is greater than the smallest virtual runtime
  2-if current running process currentRuntime has exceeded the maximum execution time
  3-Allow the current running process to continue running until preemption should occur
*/
int
checkPreemption(struct proc* current, struct proc* min_vruntime){

  //Utilize integer variable to compare current runtime with the minimum granularity
  int procRuntime = current->currentRuntime;
  
  //Determine if the currently running process has exceed its time slice.
  if((procRuntime >= current->maximumExecutiontime) && (procRuntime >= min_granularity)){
  	return 1;
  }

  //If the virtual runtime of the currently running process is greater than the smallest process, 
  //then context switching should occur
  if(min_vruntime != 0 && min_vruntime->state == RUNNABLE && current->virtualRuntime > min_vruntime->virtualRuntime){
	
	//Allow preemption if the process has ran for at least the min_granularity.
        //Due to the calls of checking for preemption, there needs to be made a distinction between when the preemption function
	//is called after a process has just be selected by the cfs scheduler and when a process has been currently running.
	if((procRuntime != 0) && (procRuntime >= min_granularity)){
		return 1;
  	} else if(procRuntime == 0){
		return 1;
        }
  }

  //No preemption should occur
  return 0;
}

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table.
void
procinit(void)
{
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for(p = proc; p < &proc[NPROC]; p++) {
      initlock(&p->lock, "proc");
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
      
  }
  rbinit(runnableTasks, "runnableTasks");
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int
allocpid()
{
  int pid;
  
  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc*
allocproc(void)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if(p->state == UNUSED) {
      goto found;
    } else {
      release(&p->lock);
    }
  }
  return 0;

found:
  p->pid = allocpid();
  p->state = USED;
  p->priority = 10;
  
  p->virtualRuntime = 0;
  p->currentRuntime = 0;
  p->maximumExecutiontime = 0;
  p->niceValue = 0;
  p->left = 0;
  p->right = 0;
  p->parentP = 0;

  // Allocate a trapframe page.
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if(p->pagetable == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;
  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if(p->trapframe)
    kfree((void*)p->trapframe);
  p->trapframe = 0;
  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
}

// Create a user page table for a given process, with no user memory,
// but with trampoline and trapframe pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if(pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)trampoline, PTE_R | PTE_X) < 0){
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe page just below the trampoline page, for
  // trampoline.S.
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
              (uint64)(p->trapframe), PTE_R | PTE_W) < 0){
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// assembled from ../user/initcode.S
// od -t xC ../user/initcode
uchar initcode[] = {
  0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
  0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
  0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
  0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
  0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
  0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00
};

// Set up first user process.
void
userinit(void)
{
  struct proc *p;

  p = allocproc();
  initproc = p;
  
  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;      // user program counter
  p->trapframe->sp = PGSIZE;  // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;
  insertProcess(runnableTasks, p);
 
  release(&p->lock);
  
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint64 sz;
  struct proc *p = myproc();

  sz = p->sz;
  if(n > 0){
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
      return -1;
    }
  } else if(n < 0){
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if((np = allocproc()) == 0){
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  release(&np->lock);
  
   insertProcess(runnableTasks, np);
   
  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    if(pp->parent == p){
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{
  struct proc *p = myproc();

  if(p == initproc)
    panic("init exiting");

  // Close all open files.
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);
  
  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
  struct proc *pp;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(pp = proc; pp < &proc[NPROC]; pp++){
      if(pp->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&pp->lock);

        havekids = 1;
        if(pp->state == ZOMBIE){
          // Found one.
          pid = pp->pid;
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
                                  sizeof(pp->xstate)) < 0) {
            release(&pp->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(pp);
          release(&pp->lock);
          release(&wait_lock);
          return pid;
        }
        release(&pp->lock);
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || killed(p)){
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();
  // char *args[] = { "echo","hello", 0 };
  // echo("echo", args);
  c->proc = 0;
  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();
    p = retrieveProcess(runnableTasks);

    
    if (p != 0){
        acquire(&p->lock);
        if (p->state == RUNNABLE){
         
        struct file *f =filealloc();
          p->state = RUNNING;
          c->proc = p;
        swtch(&c->context, &p->context);
        
        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc= 0;
      }
       release(&p->lock);
    
    }
    
  }
  
}

// Switch to scheduler.  Must hold only p->lock
// and changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    panic("sched locks");
  if(p->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
   
   //If preemption should occur, function returns 1
  //If it true then process's state will be set to runnable and its virtual time will be calculated
  if(checkPreemption(p, runnableTasks->min_vRuntime) == 1){
  p->state = RUNNABLE;
	p->virtualRuntime = p->virtualRuntime + p->currentRuntime;
  p->currentRuntime = 0;
	insertProcess(runnableTasks, p);
 
  sched(); 
  }
  // p->state = RUNNABLE;
  // sched();
  
  release(&p->lock); 
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first) {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();
  
  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk); 
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
        p->state = RUNNABLE;
        //Update runtime stats of process being woken up
      p->virtualRuntime = p->virtualRuntime + p->currentRuntime;
      p->currentRuntime = 0;

      //Insert process after it has finished Sleeping
     insertProcess(runnableTasks, p);
     
      }
      release(&p->lock);
    }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid){
      p->killed = 1;
      if(p->state == SLEEPING){
        // Wake process from sleep().
        p->state = RUNNABLE;
             //Update runtime stats of process being killed
        p->virtualRuntime = p->virtualRuntime + p->currentRuntime;
        p->currentRuntime = 0;

        //insert process into runnableTask tree
        insertProcess(runnableTasks, p);
      
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

void
setkilled(struct proc *p)
{
  acquire(&p->lock);
  p->killed = 1;
  release(&p->lock);
}

int
killed(struct proc *p)
{
  int k;
  
  acquire(&p->lock);
  k = p->killed;
  release(&p->lock);
  return k;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if(user_dst){
    return copyout(p->pagetable, dst, src, len);
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if(user_src){
    return copyin(p->pagetable, dst, src, len);
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
  [USED]      "used",
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}
int chprio(int pid, int priority)
{
	
	struct proc *p;
	for(p = proc; p < &proc[NPROC]; p++){
    
    printf("\n%d", p->pid);
	  if(p->pid == pid){
      printf("\n%d", p->pid);
      printf("\n priority: %d",priority);
			p->niceValue= priority;
      printf("\nnice value %d",p->niceValue);
      p->weightValue = calculateWeight(p->niceValue);
      printf("\nnice value %d",p->niceValue);
			break;
		}
  }
  procs();
	return pid;

}

int procs(void)
{
  struct proc *p;
  intr_on();
  
  printf("name \t pid \t state \t vruntime \t cruntime \t maxexectime \t nicevalue \t weightvalue \n");
  for(p = proc; p < &proc[NPROC]; p++){
   acquire(&p->lock);
    if(p->state == SLEEPING)
      printf("%s \t %d \t SLEEPING \t %d \t \t%d \t \t%d \t \t%d \t \t%d \n ", p->name,p->pid,p->virtualRuntime,p->currentRuntime, p->maximumExecutiontime, p->niceValue, p->weightValue);
    else if(p->state == RUNNING)
      printf("%s \t %d \t RUNNING \t %d \t \t%d \t \t%d \t \t%d \t \t%d \n ", p->name,p->pid,p->virtualRuntime,p->currentRuntime, p->maximumExecutiontime, p->niceValue, p->weightValue);
    else if(p->state == RUNNABLE)
      printf("%s \t %d \t RUNNABLE \t %d \t \t%d \t \t%d \t \t%d \t \t%d \n ", p->name,p->pid,p->virtualRuntime,p->currentRuntime, p->maximumExecutiontime, p->niceValue, p->weightValue);
   release(&p->lock);
  // int virtualRuntime;    	//Elapsed time since it was scheduled      
  // int currentRuntime;		//Time the process has run			
  // int maximumExecutiontime;	//The target scheduling latency of each process per scheduling round
  // int niceValue;		//It is the variable that will be used to determine initial priority for process
  // int weightValue;		//Variable used to determine the process's maximumExecutiontime 
    
}

  return 23;
}
 