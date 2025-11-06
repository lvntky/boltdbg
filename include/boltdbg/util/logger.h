#ifndef BOLTDBG_UTIL_LOGGER_H_
#define BOLTDBG_UTIL_LOGGER_H_

/*
 * Global spdlog accessor for boltdbg.
 *
 * Use Log::get() anywhere to obtain the shared logger.
 */

#include <memory>
#include <spdlog/spdlog.h>

namespace Log { // NOTE: capital 'L' to avoid collision with C math 'log'
    // Return a reference to a shared_ptr logger initialized on first use.
    std::shared_ptr<spdlog::logger>& get();
}

// Handy logger macros (use Log with capital L)
#define LOG_TRACE(...)    ::Log::get()->trace(__VA_ARGS__)
#define LOG_DEBUG(...)    ::Log::get()->debug(__VA_ARGS__)
#define LOG_INFO(...)     ::Log::get()->info(__VA_ARGS__)
#define LOG_WARN(...)     ::Log::get()->warn(__VA_ARGS__)
#define LOG_ERROR(...)    ::Log::get()->error(__VA_ARGS__)
#define LOG_CRITICAL(...) ::Log::get()->critical(__VA_ARGS__)

#endif // BOLTDBG_UTIL_LOGGER_H_
