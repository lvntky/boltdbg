#include <boltdbg/core/process_control.h>
#include <boltdbg/util/logger.h>
#include <sys/types.h>
#include <sys/wait.h>

#include <iomanip>
#include <list>
#include <sstream>

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

        // stepProcess();
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

void ProcessControl::stepProcess() {
    if (pid <= 0) {
        LOG_ERROR("stepProcess: invalid pid ({})", pid);
        return;
    }

    LOG_INFO("stepProcess START. Status: {}", status);


    _ptrace(PTRACE_SINGLESTEP, pid, nullptr, nullptr);

    waitpid(pid, &status, 0);

    if (WIFSTOPPED(status)) {
        LOG_INFO("Child stopped after single step. Signal: {}", WSTOPSIG(status));

        // Step sonrası registerleri oku
        if (!regs) {
            regs = new user_regs_struct();
        }
        errno = 0;
        if (ptrace(PTRACE_GETREGS, pid, nullptr, regs) == -1) {
            LOG_ERROR("PTRACE_GETREGS failed: {}", strerror(errno));
        } else {
            LOG_INFO("Registers after step:\n{}", regsToString());
        }

    } else {
        LOG_WARN("Child did not stop after single step! Status: {}", status);
    }

    LOG_INFO("stepProcess END. Status: {}", status);
}

/**
 * Soo, regs are actually a pointer to the struct in class
 * so if readRegs is not called, it never gonna created.
 * after this method created, i allocated space on heap with new
 * and the pointer in the class is pointing after _ptrace
 */
void ProcessControl::readRegs() {
    if (!pid) {
        LOG_ERROR("Invalid pid: {}", pid);
        return;
    }
    _ptrace(PTRACE_GETREGS, pid, nullptr, regs);
}

std::string ProcessControl::regsToString() {
    if (!regs) {
        return std::string("No register state available.\n");
    }

    std::ostringstream oss;
    oss << std::hex << std::setfill('0');

    oss << "Register state (pid: " << pid << ")\n";

    // Typical x86_64 user_regs_struct layout — print relevant registers:
    oss << " r15: 0x" << std::setw(16) << regs->r15 << "  r14: 0x" << std::setw(16) << regs->r14
        << "\n";
    oss << " r13: 0x" << std::setw(16) << regs->r13 << "  r12: 0x" << std::setw(16) << regs->r12
        << "\n";
    oss << " rbp: 0x" << std::setw(16) << regs->rbp << "  rbx: 0x" << std::setw(16) << regs->rbx
        << "\n";
    oss << " r11: 0x" << std::setw(16) << regs->r11 << "  r10: 0x" << std::setw(16) << regs->r10
        << "\n";
    oss << "  r9: 0x" << std::setw(16) << regs->r9 << "   r8: 0x" << std::setw(16) << regs->r8
        << "\n";
    oss << " rax: 0x" << std::setw(16) << regs->rax << "  rcx: 0x" << std::setw(16) << regs->rcx
        << "\n";
    oss << " rdx: 0x" << std::setw(16) << regs->rdx << "  rsi: 0x" << std::setw(16) << regs->rsi
        << "\n";
    oss << " rdi: 0x" << std::setw(16) << regs->rdi << " orig_rax:0x" << std::setw(16)
        << regs->orig_rax << "\n";
    oss << " rip: 0x" << std::setw(16) << regs->rip << "  cs: 0x" << std::setw(8) << regs->cs
        << "\n";
    oss << " eflags:0x" << std::setw(16) << regs->eflags << "  rsp: 0x" << std::setw(16)
        << regs->rsp << "\n";
    oss << "  ss: 0x" << std::setw(8) << regs->ss << " fs_base:0x" << std::setw(16) << regs->fs_base
        << "\n";
    oss << " gs_base:0x" << std::setw(16) << regs->gs_base << "  ds: 0x" << std::setw(8) << regs->ds
        << "\n";
    oss << "  es: 0x" << std::setw(8) << regs->es << "\n";

    oss << std::dec;

    return oss.str();
}

void ProcessControl::_ptrace(enum __ptrace_request request, pid_t pid, void* addr, void* data) {
    if (ptrace(request, pid, addr, data) == -1) {
        LOG_ERROR("ptrace failed: {}", std::string(strerror(errno)));
    }
}
}  // namespace core
