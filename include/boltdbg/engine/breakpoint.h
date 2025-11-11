#ifndef ENGINE_BREAKPOINT_H_
#define ENGINE_BREAKPOINT_H_

/* breakpoint.h - breakpoint type */

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct breakpoint {
    uint64_t address;
    uint8_t original_byte;
    bool enabled;

} breakpoint_t;

#ifdef __cplusplus
}
#endif

#endif /* ENGINE_BREAKPOINT_H_ */
