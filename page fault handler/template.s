
.section .text
.global main



main:
    # Prepare jump to super mode
    li t1, 1
    slli t1, t1, 11   #mpp_mask
    csrs mstatus, t1
    
    la t4, supervisor       #load address of user-space code
    csrrw zero, mepc, t4    #set mepc to user code
    
    la t5, page_fault_handler
    csrw mtvec, t5
   
    mret

supervisor:
################## Setting up page tables ##############
    # Set value in PTE2 (Initial Mapping)
    li a0,0x81000000
    li a1, 0x82000
    slli a1, a1, 0xa
    ori a1, a1, 0x01 # | - | - | - |V
    sd a1, 16(a0)

    # To set V.A 0x0 -> P.A 0x0
    li a1, 0x82001
    slli a1, a1, 0xa
    ori a1, a1, 0x01 # | - | - | - |V
    sd a1, 0(a0)

    # Set value in PTE1 (Initial Mapping)
    li a0,0x82000000
    li a1, 0x83000
    slli a1, a1, 0xa
    ori a1, a1, 0x01 # | - | - | - |V
    sd a1, 0(a0)

    # Set Frame number in PTE0 (Initial Mapping)
    li a0,0x83000000
    li a1, 0x80000
    slli a1, a1, 0xa
    ori a1, a1, 0xef # D | A | G | - | X | W | R |V
    sd a1, 0(a0)

    li a1, 0x80001
    slli a1, a1, 0xa
    ori a1, a1, 0xef # D | A | G | - | X | W | R |V
    sd a1, 8(a0)

    # Set value in PTE1 (Code Mapping)
    li a0,0x82001000
    li a1, 0x83001
    slli a1, a1, 0xa
    ori a1, a1, 0x01 # | - | - | - |V
    sd a1, 0(a0)

    # Set value in PTE0 (Code Mapping)
    li a0,0x83001000
    li a1, 0x80001
    slli a1, a1, 0xa
    ori a1, a1, 0xfb # D | A | G | U | X | - | R |V
    sd a1, 0(a0)

    # Data Mapping
    li a1, 0x80002
    slli a1, a1, 0xa
    ori a1, a1, 0xf7 # D | A | G | U | - | W | R |V
    sd a1, 8(a0)
    

####################################################################

    # Prepare jump to user mode
    li t1, 0
    slli t1, t1, 8   #spp_mask
    csrs sstatus, t1

    # Configure satp
    la t1, satp_config 
    ld t2, 0(t1)
    sfence.vma zero, zero
    csrrw zero, satp, t2
    sfence.vma zero, zero

    li t4, 0       # load VA address of user-space code
    csrrw zero, sepc, t4    # set sepc to user code
    
    sret



###################################################################
##################### ADD CODE ONLY HERE  #########################
###################################################################
.align 4
page_fault_handler:
csrr t3,mtval

#get vp[0]
srli t3,t3,12
andi t4,t3,0x1ff

#get vp[1]
srli t3,t3,9
andi t5,t3,0x1ff

#check whether its valid page 
li t0,0x82001000    
slli t5,t5,3
add t0,t0,t5
ld t6,0(t0)
andi t6,t6,1
beq t6,x0,new_page

check_mcause:
#check mcause
csrr t0,mcause
addi t0,t0,-12
beq t0,x0,instr_pagefault  #if t0 is 0, it means instr_pagefault
bne t0,x0,data_pagefault  #else data page fault

#if not a valid page,allocate by modifying L1,L0 table
new_page:
#assign new page in PTE1
li a0,0x82001000
li a1, 0x83002
slli a1, a1, 0xa
ori a1, a1, 0x01 # | - | - | - |V
add a0,a0,t5
sd a1, 0(a0)
j check_mcause

data_pagefault:

#extracting physical page of data
li a0,0x83001000
addi s0,a0,8
ld s0,0(s0)

#mapping current va to physical page of data
li a0,0x82001000
add a0,a0,t5
ld a0,0(a0)
srli a0,a0,10
slli a0,a0,12

slli t4,t4,3
add a0,a0,t4
sd s0,0(a0)

j exit

#get free page table entry
instr_pagefault:
li a0,0x82001000
add a0,a0,t5
ld a0,0(a0)
srli a0,a0,10
slli a0,a0,12
slli t4,t4,3
add a0,a0,t4

#assigning a free page and copy from user_code
la a1,free_page
ld a1,0(a1)
srli a1,a1,12
slli a1, a1, 0xa
ori a1, a1, 0xfb # D | A | G | U | X | - | R |V
sd a1, 0(a0)

li s0,4096
li a0,0x80001000
la a1,free_page
ld a1,0(a1)

#free_page should be incremented to next free page
la a3,free_page
ld a4,0(a3)
addi a4,a4,2047
addi a4,a4,2047
addi a4,a4,2
sd a4,0(a3)

#copy from user_code to assigned page
copy:
beq s0,x0,exit
ld t6,0(a0)
sd t6,0(a1)
addi a0,a0,8
addi a1,a1,8
addi s0,s0,-8
j copy

exit:
mret

###################################################################
###################################################################



.align 12
user_code:
la t1,var_count
lw t2, 0(t1)
addi t2, t2, 1
sw t2, 0(t1)
la t5, code_jump_position
lw t3, 0(t5)
li t4, 0x2000
add t3, t3, t4
sw t3, 0(t5)

jalr x0, t3


.data
.align 12
var_count:  .word  0
code_jump_position: .word 0x0000


.align 8
# Value to set in satp
satp_config: .dword 0x8000000000081000
free_page: .dword 0x80003000
