
#ifndef CORE_PROCESS_CONTROL_H_
#define CORE_PROCESS_CONTROL_H_

#include <sys/ptrace.h>

#include <list>
#include <string>

namespace core {

class ProcessControl {
  private:
    pid_t pid;
    int status;

  public:
    ProcessControl() : pid(-1), status(-1) {}

    ~ProcessControl() {
        // If attached to a process, detach before destruction
        if (pid > 0) {
            ptrace(PTRACE_DETACH, pid, nullptr, nullptr);
        }
    }

    void launchProcess(const std::list<std::string>& targetProcess);
    void attachProcess();  // only needed for debuggin already running processes. sice we are
                           // debugging from star, doesnt required much.
    long readMemory(void* addr);
    void writeMemory(void* addr, void* data);
    void getPid();
    void continueProcess();

  protected:
    void _ptrace(enum __ptrace_request request, pid_t pid, void* addr, void* data);
};

}  // namespace core

#endif  // CORE_PROCESS_CONTROL_H_
