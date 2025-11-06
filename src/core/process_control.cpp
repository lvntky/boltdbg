#include <boltdbg/core/process_control.h>
#include <boltdbg/util/logger.h>
#include <sys/types.h>
#include <sys/wait.h>

#include <unistd.h>

namespace core {
void ProcessControl::launchTarget(const std::string& targetPath) {
    if (targetPath.empty()) {
        throw std::invalid_argument("launchTarget: targetPath is empty.");
    }

    pid_t pid = fork();
    if (pid < 0) {
        throw std::runtime_error("fork() failed.");
    } else if (pid == 0) {
        LOG_INFO("child process started");
    } else {
        LOG_INFO("child terminated.");
    }
}
}  // namespace core
