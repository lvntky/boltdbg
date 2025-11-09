#include <boltdbg/core/process_control.h>
#include <boltdbg/util/logger.h>
#include <sys/types.h>
#include <sys/wait.h>

#include <list>

#include <string.h>
#include <unistd.h>

namespace core {
void ProcessControl::launchProcess(const std::list<std::string>& targetProcess) {
    if (targetProcess.empty()) {
        throw std::invalid_argument("launchTarget: targetProcess is empty.");
    }
    LOG_INFO("Process initialized with (pid: {}\t status: {})", pid, status);

    pid = fork();
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

    } else {
        LOG_INFO("Parent tracing child with pid: {}", pid);
        waitpid(pid, &status, 0);
        LOG_INFO("Current child pid({}) status: {}", pid, status);

        if (!WIFSTOPPED(status)) {
            LOG_INFO("Process does not stopped.");
        }

        continueProcess();
    }
}

long ProcessControl::readMemory(void* addr) {
    // long data = _ptrace(PTRACE_PEEKDATA, pid, addr, nullptr);
    long data = 0;
    return data;
}

void ProcessControl::writeMemory(void* addr, void* data) {
    _ptrace(PTRACE_POKEDATA, pid, addr, data);
}

void ProcessControl::continueProcess() {
    LOG_INFO("continueProcess START. Status: {}", status, 0);
    _ptrace(PTRACE_CONT, pid, nullptr, nullptr);
    LOG_INFO("continueProcess END. Status: {}", waitpid(pid, &status, 0));
}

void ProcessControl::_ptrace(enum __ptrace_request request, pid_t pid, void* addr, void* data) {
    if (ptrace(request, pid, addr, data) == -1) {
        LOG_ERROR("ptrace failed: {}", std::string(strerror(errno)));
    }
}
}  // namespace core
