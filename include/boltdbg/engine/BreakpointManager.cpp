/* BreakpointManager.cpp -  */

#include <boltdbg/engine/breakpoint.h>

#include <unordered_map>

namespace engine {
class Breakpoint {
  private:
    std::unordered_map<uint64_t, breakpoint_t> bps;
}
}  // namespace engine
