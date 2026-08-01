#include <gmp.h>

/* mirage-crypto-pk needs constant-time modular exponentiation for RSA. GMP has
   shipped mpz_powm_sec since 6.0, but a target GMP could be older or built
   without it, so take the symbol rather than assume. Link, do not run. */
int main(void)
{
    mpz_t r, b, e, m;
    mpz_init(r); mpz_init(b); mpz_init(e); mpz_init(m);
    mpz_powm_sec(r, b, e, m);
    return 0;
}
