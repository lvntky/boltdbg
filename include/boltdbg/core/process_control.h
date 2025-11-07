
#ifndef CORE_PROCESS_CONTROL_H_
#define CORE_PROCESS_CONTROL_H_

#include <list>
#include <string>

namespace core {

class ProcessControl {
  public:
    void launchTarget(const std::list<std::string>& targetProcess);
};

}  // namespace core

#endif  // CORE_PROCESS_CONTROL_H_
