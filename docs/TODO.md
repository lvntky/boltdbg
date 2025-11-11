
# Core Platform Layer (Linux)

## BOLT-006 · Linux Process Launch

* [ ] Create `core/ProcessControl` class skeleton with `pid_t pid`, process state, and methods.
* [ ] Implement `ProcessControl::launchProcess(const std::list<std::string>& args)`:

  * [ ] Perform `fork()`.
  * [ ] In child:

    * [ ] Call `ptrace(PTRACE_TRACEME, 0, NULL, NULL)`.
    * [ ] Execute target binary with `execvp()`.
    * [ ] Handle `execvp` failure with `_exit(errno)`.
  * [ ] In parent:

    * [ ] Wait for child to reach `SIGTRAP` (via `waitpid` + `WIFSTOPPED`).
    * [ ] Verify correct startup state before continuing.
  * [ ] Store `pid` and mark process state as `LAUNCHED`.
  * [ ] Implement proper cleanup on error (kill child if setup fails).
  * [ ] Add error reporting via `errno` and convert to structured error type.

## BOLT-007 · Linux Process Attach/Detach

* [ ] Add `attachProcess(pid_t targetPid)`:

  * [ ] Call `ptrace(PTRACE_ATTACH, targetPid, NULL, NULL)`.
  * [ ] Wait until `waitpid(targetPid, …)` returns with `WIFSTOPPED`.
  * [ ] Store target PID and mark as `ATTACHED`.
* [ ] Add `detachProcess()`:

  * [ ] Call `ptrace(PTRACE_DETACH, pid, NULL, NULL)`.
  * [ ] Verify `errno == 0`, update state to `DETACHED`.
* [ ] Implement permission and error handling (`EPERM`, `ESRCH`, `EIO`).
* [ ] Add log output for attach/detach lifecycle events.

## BOLT-008 · Linux Memory Operations

* [ ] Add `readMemory(uint64_t addr, void* buffer, size_t size)`:

  * [ ] Implement word-aligned reads via `ptrace(PTRACE_PEEKDATA)`.
  * [ ] Handle partial reads (non-multiple of `sizeof(long)`).
  * [ ] Validate target address readability.
  * [ ] Throw/return error if `ptrace` returns `-1` and `errno != 0`.
* [ ] Add `writeMemory(uint64_t addr, const void* data, size_t size)`:

  * [ ] Read current word, patch changed bytes, write with `PTRACE_POKEDATA`.
  * [ ] Handle boundaries across words.
  * [ ] Optionally lock memory writes via mutex if multithreaded.
* [ ] Write helper `alignToWordBoundary()` for efficient read/write alignment.
* [ ] Unit test reading/writing known addresses on test process.

## BOLT-009 · Linux Register Access

* [ ] Add `readRegisters()` using `ptrace(PTRACE_GETREGS, pid, 0, &user_regs_struct)`.

  * [ ] Store in local `regs` buffer.
  * [ ] Convert to internal struct (e.g. `RegisterSet` abstraction).
* [ ] Add `writeRegisters(const RegisterSet& regs)` using `PTRACE_SETREGS`.

  * [ ] Support all x86_64 GPRs: RAX, RBX, RCX, RDX, RSI, RDI, RBP, RSP, R8-R15, RIP, EFLAGS.
* [ ] Implement getter/setter utilities:

  * [ ] `getRegister(const std::string&)`
  * [ ] `setRegister(const std::string&, uint64_t)`
* [ ] Verify register read/write correctness via integration test (compare before/after).

## BOLT-010 · Linux Continue / Step Operations

* [ ] Add `continueExecution(int signal = 0)`:

  * [ ] Call `ptrace(PTRACE_CONT, pid, NULL, signal)`.
  * [ ] Block in `waitpid()` for next event.
  * [ ] Return event type (`SIGTRAP`, `SIGSEGV`, etc.).
* [ ] Add `singleStep()`:

  * [ ] Call `ptrace(PTRACE_SINGLESTEP, pid, 0, 0)`.
  * [ ] Wait for `SIGTRAP`.
* [ ] Create internal event-handling layer:

  * [ ] Parse `waitpid` status via macros: `WIFSTOPPED`, `WSTOPSIG`.
  * [ ] Normalize signals into internal enum (`STOPPED_AT_BREAKPOINT`, `EXITED`, etc.).
* [ ] Handle `SIGTRAP` after breakpoint removal vs. single-step.
* [ ] Ensure step/continue correctly resume from modified RIP.
* [ ] Integrate debug logging for signal transitions.

---

# SPRINT 2 — Breakpoint Engine

## BOLT-011 · Breakpoint Manager

* [ ] Define `Breakpoint` struct → `{uint64_t address; uint8_t original_byte; bool enabled;}`
* [ ] Implement `BreakpointManager`:

  * [ ] Internal `std::unordered_map<uint64_t, Breakpoint> bps;`
  * [ ] Methods: `add(address)`, `remove(address)`, `enable(address)`, `disable(address)`, `get(address)`.
  * [ ] Synchronize access (mutex) if multi-threaded later.
  * [ ] Persist breakpoints in memory per-process.

## BOLT-012 · Software Breakpoint Setting

* [ ] Implement `setBreakpoint(address)`:

  * [ ] Use `readMemory` to fetch original byte.
  * [ ] Write `0xCC` at target.
  * [ ] Save original in `BreakpointManager`.
* [ ] Implement `removeBreakpoint(address)`:

  * [ ] Restore saved byte via `writeMemory`.
  * [ ] Update manager state.
* [ ] Add protection check: ensure writable via `mprotect` or `/proc/[pid]/maps` analysis if needed.
* [ ] Unit test by inserting breakpoint at known function entry.

## BOLT-013 · Breakpoint Hit Detection

* [ ] Extend wait/event loop to detect `SIGTRAP`.
* [ ] On trap:

  * [ ] Read `RIP` and decrement by 1 (to point to INT3).
  * [ ] Lookup address in `BreakpointManager`.
  * [ ] If valid, mark event as “breakpoint hit”.
  * [ ] Store `hit_address` in debugger state.
* [ ] Provide event callback API: `onBreakpointHit(uint64_t address)`.

## BOLT-014 · Breakpoint Continue Logic

* [ ] Implement temporary restoration logic:

  * [ ] Restore original byte at `hit_address`.
  * [ ] Adjust RIP to point to instruction again.
  * [ ] Perform `singleStep()`.
  * [ ] Re-insert INT3 after step completes.
* [ ] Handle breakpoint removal while stepping.
* [ ] Ensure consistent state if `SIGTRAP` occurs mid-step.

## BOLT-015 · Multiple Breakpoint Support

* [ ] Validate multiple simultaneous breakpoints:

  * [ ] Insert N breakpoints across different functions.
  * [ ] Verify independent enable/disable operations.
  * [ ] Test nested hits and re-insertion logic.
  * [ ] Validate that INT3 at address does not affect adjacent breakpoints.

---

# SPRINT 3 — Symbol Parsing Foundation

## BOLT-016 · ELF Binary Parser

* [ ] Implement `ELFParser` class:

  * [ ] Parse ELF header (`Elf64_Ehdr`).
  * [ ] Load section headers (`Elf64_Shdr` array).
  * [ ] Map section names via `.shstrtab`.
  * [ ] Identify `.debug_info`, `.debug_line`, `.debug_abbrev`, `.symtab`.
* [ ] Load sections into memory buffers via `mmap` or `ifstream`.
* [ ] Validate endianness and machine type (x86_64 only initially).
* [ ] Provide accessors: `getSection(name)`, `getSectionData(index)`.

## BOLT-017 · DWARF Abbrev Parser

* [ ] Create `DwarfAbbrevTable` module:

  * [ ] Parse `.debug_abbrev` entries → (abbrev_code, tag, children, attribute list).
  * [ ] Implement attribute form mapping (DW_FORM_addr, DW_FORM_strp, etc.).
  * [ ] Store as `std::unordered_map<uint32_t, AbbrevEntry>`.
  * [ ] Provide `getAttributesForAbbrev(code)`.

## BOLT-018 · DWARF Info Entry Parser

* [ ] Create `DwarfInfoParser`:

  * [ ] Iterate over `.debug_info` using `.debug_abbrev`.
  * [ ] Parse Compilation Units (CU headers + DIE trees).
  * [ ] Build DIE hierarchy (nodes: type, attributes, children).
  * [ ] Support DW_TAG_subprogram, DW_TAG_variable, DW_TAG_compile_unit.
  * [ ] Store address ranges per function.

## BOLT-019 · DWARF Line Program Parser

* [ ] Implement `DwarfLineProgram`:

  * [ ] Parse header (version, opcode_base, line_base, line_range).
  * [ ] Execute line state machine per DWARF spec.
  * [ ] Build address → (line, file) mapping.
  * [ ] Expose `getLineForAddress(uint64_t)` and `getFileForAddress(uint64_t)`.

## BOLT-020 · Symbol Table

* [ ] Implement `SymbolTable` class:

  * [ ] Store `Symbol {name, address, type, file, line}`.
  * [ ] Build from DWARF and/or ELF `.symtab`.
  * [ ] Create address-sorted vector for binary search.
  * [ ] Implement `findSymbolByAddress(addr)` and `findSymbolByName(name)`.
* [ ] Cache results for fast lookup during debug session.

---

# SPRINT 4 — Basic UI Panels

## BOLT-021 · Source File Manager

* [ ] Create `SourceManager`:

  * [ ] Load source text from absolute paths in DWARF data.
  * [ ] Cache in `std::unordered_map<std::string, std::vector<std::string>>`.
  * [ ] Handle missing files gracefully.
  * [ ] Provide `getLine(file, lineNumber)` and `getFileLines(file)`.

## BOLT-022 · Source Code Display Panel

* [ ] Build ImGui panel (`ui/SourcePanel.cpp`):

  * [ ] Render line numbers + source text.
  * [ ] Highlight current execution line.
  * [ ] Add scrollbar and monospace font.
  * [ ] Connect execution line to `RIP → source mapping`.

## BOLT-023 · Breakpoint Indicators

* [ ] Add left gutter column for breakpoint icons.

  * [ ] Detect clicks on line numbers → toggle breakpoint.
  * [ ] Red filled circle = enabled; hollow = disabled.
  * [ ] Sync with `BreakpointManager`.
  * [ ] Redraw on enable/disable.

## BOLT-024 · Source Navigation

* [ ] Implement “Go to Line” dialog (Ctrl+G shortcut).
* [ ] Maintain cursor position state per file.
* [ ] Auto-scroll to current execution line on break.
* [ ] Keep line centered when paused.

## BOLT-025 · Control Toolbar

* [ ] Create ImGui toolbar (`ui/Toolbar.cpp`):

  * [ ] Buttons: Run/Continue, Pause, Stop, Step Over, Step Into, Step Out.
  * [ ] Icons via FontAwesome or custom texture.
  * [ ] Wire callbacks to `ProcessControl` methods.
  * [ ] Display execution state (label: Running/Paused/Exited).
  * [ ] Add FPS counter to status bar.

---
