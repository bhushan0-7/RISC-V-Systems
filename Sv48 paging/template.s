.section .text
.global main

main:
	# Write code here to jump to supervisor mode 
	#configure mepc
	la t0,supervisor
	csrrw x0,mepc,t0

	#configure mstatus
	csrr t0,mstatus
	li t1,3
	slli t1,t1,11
	csrrc x0,mstatus,t1
	li t1,1
	slli t1,t1,11
	csrrs x0,mstatus,t1

	#go to supervisor mode
	mret


supervisor: 
################ Initialize your page tables here ################
	la t0,L3
	la t1,L2
	srli t1,t1,12
	slli t1,t1,10
	li t2,1
	or t1,t1,t2
	sd t1,0(t0)

	la t0,L2
	la t1,L1
	srli t1,t1,12
	slli t1,t1,10
	li t2,1
	or t1,t1,t2
	sd t1,0(t0)

	la t0,L2
	addi t0,t0,0x10
	la t1,L1_p
	srli t1,t1,12
	slli t1,t1,10
	addi t1,t1,1
	sd t1,0(t0)

	la t0,L1
	la t1,L0
	srli t1,t1,12
	slli t1,t1,10
	li t2,1
	or t1,t1,t2
	sd t1,0(t0)

	la t0,L1_p
	addi t1,x0,0x1b0
	slli t1,t1,3
	add t0,t0,t1
	la t1,L0_p
	srli t1,t1,12
	slli t1,t1,10
	addi t1,t1,1
	sd t1,0(t0)

	la t0,L0
	la t1,user_code
	srli t1,t1,12
	slli t1,t1,10
	addi t1,t1,0x1b
	addi t1,t1,0xC0
	sd t1,0(t0)

	la t0,L0
	la t1,var1
	srli t1,t1,12
	slli t1,t1,10
	addi t1,t1,0x17
	addi t1,t1,0xC0
	sd t1,8(t0)

	la t0,L0_p
	li t1,0xb6000
	slli t1,t1,10
	addi t1,t1,0xb
	addi t1,t1,0xC0
	sd t1,0(t0)

	la t0,L3
	la t1,satp_config
	srli t0,t0,12
	li t2,9
	slli t2,t2,60
	or t0,t0,t2
	sd t0,0(t1)

####################################################################

	# Prepare a jump to user mode
	#configure mstatus
	csrr t0,sstatus
	li t1,1
	slli t1,t1,11
	csrrc x0,sstatus,t1


################ DO NOT MODIFY THESE INSTRUCTIONS ################
	la t1, satp_config # load satp val
	ld t2, 0(t1)
	sfence.vma zero, zero
	csrrw zero, satp, t2
	sfence.vma zero, zero

	li t4, 0
	csrrw zero, sepc, t4

	sret
#################################################################### 

.align 12
user_code:
# Write user code here that does the following:
    # 1. Initialize four variables var1 , var2 , var3 , var4 in the data section with values 1 , 2 , 3 , 4.
    # 2. The user_code must load these variables into t1 , t2 , t3 , t4 registers (for reading during debug mode) and then loop back to itself.
	la t0,var1
	ld t1,0(t0)

	la t0,var2
	ld t2,0(t0)

	la t0,var3
	ld t3,0(t0)

	la t0,var4
	ld t4,0(t0)

	j user_code

# Don't forget to align the data section and user_code propely. For assembly directive usage, use the last reference given.

.section .data 
.align 12
var1: .dword 1
var2: .dword 2
var3: .dword 3
var4: .dword 4

satp_config: .dword 0
# Set appropriate value for satp here.

.align 12
L3: .space 4096
L2: .space 4096 
L1: .space 4096 
L0: .space 4096 
L0_p: .space 4096
L1_p: .space 4096

