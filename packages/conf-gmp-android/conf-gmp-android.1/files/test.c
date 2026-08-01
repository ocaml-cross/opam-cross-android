#include <gmp.h>

/* Link, do not run: the result is an aarch64 object the build machine cannot
   execute. Referencing a symbol forces the linker to actually resolve -lgmp. */
int main(void)
{
    mpz_t n;
    mpz_init(n);
    mpz_clear(n);
    return 0;
}
