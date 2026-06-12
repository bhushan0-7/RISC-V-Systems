.section .data
.align 2
a:.word 2
b:.word 3
.section .text
.global main

main:
# Configure CSR registers (medeleg, mstatus, mepc, mtvec, stvec etc.)
# Execute mret to initiate downward transition to User code

#set mepc
la t0,ucode
csrrw x0,mepc,t0

#set strap_handler
la t0,strap_handler
csrrw x0,stvec,t0

#set medeleg
li t0,1
slli t0,t0,8
csrrw x0,medeleg,t0

#set mstatus
csrr t0,mstatus
li t1,3
slli t1,t1,11
not t1,t1
and t0,t0,t1
csrrw x0,mstatus,t0

#set mtrap_handler
la t0,mtrap_handler
csrrw x0,mtvec,t0

#switch to user mode
mret

.align 4
mtrap_handler:
# Process traps originating from the strap_handler
# Perform the multiplication operation
# Flip a0 to 0
# Set mepc back to strap_handler and execute mret

#checks previlege mode

#set mstatus
csrr t6,mstatus

#a1*a2
mul a1,a1,a2
li a0,0

#set mepc
la t0,strap_handler
csrrw x0,mepc,t0

#set mstatus
csrr t0,mstatus
li t1,3
slli t1,t1,11
not t1,t1
and t0,t0,t1
li t1,1
slli t1,t1,11
or t0,t0,t1
csrrw x0,mstatus,t0

#switch to strap_handler
mret

scode:
# Execute sret to initiate transition to User mode after setting the CSRs
la t0,ucode1
csrrw x0,sepc,t0

#change sstatus
csrr t0,sstatus
li t1,2
slli t1,t1,11
not t1,t1
and t0,t0,t1
csrrw x0,sstatus,t0

#go to ucode1
sret

.align 4
strap_handler:
# The Dispatcher
# Check if a0 == 0 or a0 == 1
# If a0 == 0: jump to scode (to setup S to U transition)
# If a0 == 1: execute ecall to jump up to mtrap_handler
csrr t6,sstatus

#check condition
beq a0,x0,scode
ecall

ucode:
# Note: Handle initial variable loading here if using a single User block

#load values
la t0,a
lw a1,0(t0)
la t0,b
lw a2,0(t0)
li a0,0
ecall

ucode1:
# Perform the addition operation
# Flip a0 to 1
# The ecall should invoke the supervisor’s trap handler
#a1+a2
add a1,a1,a2
li a0,1
#return to strap_handler
ecall

