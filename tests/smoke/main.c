#include <stdio.h>
#include <orbis/libkernel.h>

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    printf("VitaPS4 smoke test: native PS4 process started.\n");
    sceKernelUsleep(5 * 1000000);
    printf("VitaPS4 smoke test: exiting now.\n");
    return 0;
}
