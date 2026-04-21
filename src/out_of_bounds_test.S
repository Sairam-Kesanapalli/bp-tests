.section .text
.global main

main:
    # 1. Set up the trap handler vector
    la t0, trap_handler
    csrw mtvec, t0
    
    # 2. Set up the test addresses
    li t1, 0x4000000000000000  # Address that triggers OOB (exceeds physical width)
    la t3, valid_data          # Valid memory address in the .data section

    # 3. BACK-TO-BACK memory operations to test cycle alignment!
    lw x0, 0(t3)               # Valid load (Should NOT fault)
    lw t2, 0(t1)               # OOB load (SHOULD fault and jump to trap_handler)
    
    # 4. If we reach this line, the OOB load failed to trigger a trap!
    j fail                     

.align 2
trap_handler:
    # 5. Verify the trap was actually caused by our OOB load
    csrr t3, mcause
    li t4, 5                   # Expecting Exception 5: Load Access Fault
    bne t3, t4, fail
    # If it is exactly 5, the test worked perfectly! Fall through to pass.

pass:
    # Signal success (0) to the Verilator/BlackParrot testbench
    li t0, 0x00102000          # Perch finish register
    li t1, 0x0
    sw t1, 0(t0)

test_done:
    wfi                        # Halt processor
    j test_done

fail:
    # Signal failure (2) to the Verilator/BlackParrot testbench
    li t0, 0x00102000          # Perch finish register
    li t1, 0x2
    sw t1, 0(t0)
    
fail_loop:
    wfi                        # Halt processor
    j fail_loop

.section .data
.align 3
valid_data:
    .dword 0xDEADBEEF          # Safe dummy data to read for the valid load
