
#ifndef CORE_PROCESS_CONTROL_H_
#define CORE_PROCESS_CONTROL_H_

#include <sys/ptrace.h>

#include <list>
#include <string>

namespace core {

class ProcessControl {
  public:
    void launchTarget(const std::list<std::string>& targetProcess);

  protected:
    void _ptrace(enum __ptrace_request request, pid_t pid, void* addr, void* data);
};

}  // namespace core

#endif  // CORE_PROCESS_CONTROL_H_
