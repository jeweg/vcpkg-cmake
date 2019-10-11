#include "fmt/format.h"
#include <iostream>

int main()
{
    int foo = 1;
    double bar = 3.1415;
    std::cout << fmt::format("just {} some {} formatting.\n", foo, bar);
    return 0;
}