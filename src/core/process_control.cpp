#include <boltdbg/core/process_control.h>
#include <boltdbg/util/logger.h>
#include <sys/types.h>
#include <sys/wait.h>

#include <list>

#include <unistd.h>

namespace core {
void ProcessControl::launchTarget(const std::list<std::string>& targetProcess) {
    if (targetProcess.empty()) {
        throw std::invalid_argument("launchTarget: targetProcess is empty.");
    }

    pid_t pid = fork();
    if (pid < 0) {
        throw std::runtime_error("fork() failed.");
    } else if (pid == 0) {
        LOG_INFO("child process started");
        _ptrace(PTRACE_TRACEME, 0, NULL, NULL);
        LOG_INFO("PTRACE_TRACEME called by child");

        std::vector<char*> argv;
        for (auto& arg : targetProcess) {
            argv.push_back(const_cast<char*>(arg.c_str()));
        }
        argv.push_back(nullptr);

        if (execvp(argv[0], argv.data()) == -1) {
            throw std::runtime_error("execvp() failed.");
        }
        raise(SIGSTOP);

    } else {

    }
}

void ProcessControl::_ptrace(enum __ptrace_request request, pid_t pid, void* addr, void* data) {
    if (ptrace(request, pid, addr, data) == -1) {
        throw std::runtime_error("ptrace failed.");
    }
}
}  // namespace core
