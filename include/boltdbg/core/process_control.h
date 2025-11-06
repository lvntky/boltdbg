
#ifndef CORE_PROCESS_CONTROL_H_
#define CORE_PROCESS_CONTROL_H_

#include <string>

namespace core {

class ProcessControl {
  public:
    void launchTarget(const std::string& targetPath);
};

}  // namespace core

#endif  // CORE_PROCESS_CONTROL_H_
