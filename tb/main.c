int main() {
    int n = 40; // Change this value to test
    int a = 0, b = 1, temp;
    for (int i = 0; i < n; i++) {
        temp = a + b;
        a = b;
        b = temp;
    }
    while(1);
    
    return a; // nth Fibonacci number
}
/* Assembly code:
main:
        addi    sp,sp,-48
        sw      ra,44(sp)
        sw      s0,40(sp)
        addi    s0,sp,48
        li      a5,40
        sw      a5,-32(s0)
        sw      zero,-20(s0)
        li      a5,1
        sw      a5,-24(s0)
        sw      zero,-28(s0)
        j       .L2
.L3:
        lw      a4,-20(s0)
        lw      a5,-24(s0)
        add     a5,a4,a5
        sw      a5,-36(s0)
        lw      a5,-24(s0)
        sw      a5,-20(s0)
        lw      a5,-36(s0)
        sw      a5,-24(s0)
        lw      a5,-28(s0)
        addi    a5,a5,1
        sw      a5,-28(s0)
.L2:
        lw      a4,-28(s0)
        lw      a5,-32(s0)
        blt     a4,a5,.L3
.L4:
        j       .L4
*/