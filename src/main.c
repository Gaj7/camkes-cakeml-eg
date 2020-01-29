#include <stdio.h>

// Defined in the CakeML binary
void cml_entry(void);

// CAmkES-defined entry point
int run(void) {
    printf("Hello C World!\n");
    cml_entry();

    // The call into the CakeML binary does not return
    // (it calls cml_exit in libcamkescakeml instead).
    // Program execution should never reach this point.
    return 1;
}
