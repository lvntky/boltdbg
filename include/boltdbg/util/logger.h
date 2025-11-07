#ifndef BOLTDBG_UTIL_LOGGER_H_
#define BOLTDBG_UTIL_LOGGER_H_

/*
 * Global spdlog accessor for boltdbg.
 *
 * Use Log::get() anywhere to obtain the shared logger.
 * Use LOG_INFO(), LOG_ERROR(), etc. macros for automatic source location tracking.
 */

#include <spdlog/spdlog.h>
#include <memory>

namespace Log {  // NOTE: capital 'L' to avoid collision with C math 'log'

// Return a reference to a shared_ptr logger initialized on first use.
std::shared_ptr<spdlog::logger>& get();

}  // namespace Log

// ============================================================================
// Logging Macros - Capture file/line/function automatically
// ============================================================================
// 
// IMPORTANT: These use SPDLOG_LOGGER_* macros which capture source location
// for %s (source file), %# (line number), and %! (function name) patterns.
//
// DO NOT use Log::get()->info() directly - it won't capture location info!

#define LOG_TRACE(...)    SPDLOG_LOGGER_TRACE(::Log::get(), __VA_ARGS__)
#define LOG_DEBUG(...)    SPDLOG_LOGGER_DEBUG(::Log::get(), __VA_ARGS__)
#define LOG_INFO(...)     SPDLOG_LOGGER_INFO(::Log::get(), __VA_ARGS__)
#define LOG_WARN(...)     SPDLOG_LOGGER_WARN(::Log::get(), __VA_ARGS__)
#define LOG_ERROR(...)    SPDLOG_LOGGER_ERROR(::Log::get(), __VA_ARGS__)
#define LOG_CRITICAL(...) SPDLOG_LOGGER_CRITICAL(::Log::get(), __VA_ARGS__)

#endif  // BOLTDBG_UTIL_LOGGER_H_