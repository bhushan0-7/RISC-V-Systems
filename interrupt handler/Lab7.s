.section .text.init
.global _start


_start:
# 1. Initialize Stack Pointer (sp)
la t0,_stack_top
add sp,t0,x0

# 2. Setup Trap Vectors (mtvec)
la t0,mtrap_handler
csrrw x0,mtvec,t0

# 3. Prepare transition to User Mode (mstatus and mepc)
#set mepc
la t0,ucode
csrrw x0,mepc,t0

#set mstatus
csrr t0,mstatus
li t1,3
slli t1,t1,11
not t1,t1
and t0,t0,t1
csrrw x0,mstatus,t0

# 4. Execute mret to jump to ucode
    mret

.section .text
.align 4
mtrap_handler:
# --- Context Saving ---
# Save registers used in ucode. In the ideal case should save all registers.
addi sp,sp,-16
sd t0,0(sp)
sd t1,8(sp)

# --- Decode mcause ---
# Implement logic to handle causes 2, 3, 4, 5, 8
csrr t0,mcause
li t1,2
beq t0,t1,illegal_instr

li t1,3
beq t0,t1,breakpoint

li t1,4
beq t0,t1,load_addr_misalign

li t1,5
beq t0,t1,load_access_fault

li t1,8
beq t0,t1,ecall_instr
j exit

illegal_instr:
csrr t0,mepc
addi t0,t0,4
csrrw x0,mepc,t0
csrr s9,mtval
li t0,0
addi t0,t0,0x7f
and s9,s9,t0
j exit

breakpoint:
csrr t0,mepc
addi t0,t0,2
csrrw x0,mepc,t0
li a0,0xBEEF
j exit

load_addr_misalign:
csrr t0,mepc
addi t0,t0,4
csrrw x0,mepc,t0
csrr s10,mtval
j exit

load_access_fault:
csrr t0,mepc
addi t0,t0,4
csrrw x0,mepc,t0
csrr s11,mtval
j exit

ecall_instr:
csrr t0,mepc
addi t0,t0,4
csrrw x0,mepc,t0
li a0,0xFEED
j exit

# --- Context Restoration ---
exit:
ld t0,0(sp)
ld t1,8(sp)
addi sp,sp,16
mret

ucode:
# --- Sequence of Exception Tests ---
# Trigger exceptions one after another to test your handler logic
.word 0x00000000
ebreak
la t0,ucode
ld t0,0(t0)
li t0,0x0
ld t1, 0(t0)
ecall
j .

.section .bss
.align 16
_stack_low:
.space 4096
_stack_top:
