#include <iostream>
//#include "../src/util/logger.h"

void run_logger_tests(int &passed, int &failed) {
    std::cout << "Running logger tests...\n";

    try {
	    //log(LogLevel::Info, "Test info message");
	    //log(LogLevel::Warn, "Test warning message");
	    //log(LogLevel::Error, "Test error message");
	    //passed++;
    } catch (...) {
        failed++;
    }
}
