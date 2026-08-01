#include <ev.h>

/* lwt uses libev as an event loop backend. Link, do not run. */
int main(void)
{
    struct ev_loop *loop = ev_default_loop(0);
    return loop == 0;
}
