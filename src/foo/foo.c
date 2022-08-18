#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <zlib.h>

#include "foo.h"

#define FOO_PI (3.14)

char buf[1024];

int foo(void)
{
    // Print hello world
    printf("Hello world\n");

    printf("This is pi: %f\n", FOO_PI);

    // Seed a random number generator with the current time
    time_t t = time(NULL);
    if (t == -1) {
        return 1;
    }
    srand((unsigned int)t);

    for (int i = 0; i < 3; i++)
    {
        // Generate a random number
        int random = rand();
        // Calculate it's square root
        double square_root = sqrt((double)random);
        if (square_root < 0.0) {
            return 1;
        }
        // Print the result
        printf("The square root of %d is %f\n", random, square_root);
    }

    // Print hello world again in a different way
    int n = sprintf(buf, "Hello world");
    if (n < 0) {
        return 1;
    }
    printf("%s\n", buf);

    const char* version = zlibVersion();
    printf("Version of zlib: %s\n", version);

    return 0;
}