#include <iostream>

int main() {
    std::cout << "[BoltDBG] Running tests...\n";
    int passed = 0, failed = 0;

    extern void run_logger_tests(int&, int&);
    run_logger_tests(passed, failed);

    std::cout << "Tests passed: " << passed << "\n";
    std::cout << "Tests failed: " << failed << "\n";

    return failed > 0 ? 1 : 0;
}
