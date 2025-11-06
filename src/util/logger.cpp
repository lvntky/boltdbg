#include <spdlog/sinks/basic_file_sink.h>
#include <spdlog/sinks/msvc_sink.h>
#include <spdlog/sinks/ostream_sink.h>
#include <spdlog/sinks/stdout_color_sinks.h>

#include <boltdbg/util/logger.h>

#include <vector>

namespace Log {

std::shared_ptr<spdlog::logger>& get() {
    static std::shared_ptr<spdlog::logger> logger = [] {
        std::vector<spdlog::sink_ptr> sinks;
        sinks.push_back(std::make_shared<spdlog::sinks::stdout_color_sink_mt>());
        sinks.push_back(std::make_shared<spdlog::sinks::basic_file_sink_mt>("app.log", true));

        auto logger = std::make_shared<spdlog::logger>("global", sinks.begin(), sinks.end());
        logger->set_level(spdlog::level::trace);
        logger->set_pattern("[%Y-%m-%d %H:%M:%S.%e] [%^%l%$] [thread %t] [%s:%#] %v");

        spdlog::register_logger(logger);
        spdlog::set_default_logger(logger);

        return logger;
    }();
    return logger;
}

}  // namespace Log
