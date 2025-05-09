#ifndef _LLVM_BPF_JIT_CONTEXT_H
#define _LLVM_BPF_JIT_CONTEXT_H

#include <llvm/Support/TargetSelect.h>
#include <memory>
#include <llvm/ExecutionEngine/Orc/Core.h>
#include <llvm/Support/InitLLVM.h>
#include <llvm/IR/Module.h>
#include <llvm/ExecutionEngine/Orc/ThreadSafeModule.h>
#include <llvm/ExecutionEngine/Orc/LLJIT.h>
#include <llvm/ExecutionEngine/MCJIT.h>
#include <optional>
#include <string>
#include <pthread.h>
#include <tuple>
#include <llvmbpf.hpp>

namespace bpftime
{

class llvmbpf_vm;

const static char *LDDW_HELPER_MAP_BY_FD = "__lddw_helper_map_by_fd";
const static char *LDDW_HELPER_MAP_BY_IDX = "__lddw_helper_map_by_idx";
const static char *LDDW_HELPER_MAP_VAL = "__lddw_helper_map_val";
const static char *LDDW_HELPER_VAR_ADDR = "__lddw_helper_var_addr";
const static char *LDDW_HELPER_CODE_ADDR = "__lddw_helper_code_addr";

#define IS_ALIGNED(x, a) (((uintptr_t)(x) & ((a)-1)) == 0)

#ifndef EBPF_STACK_SIZE
// Compatible to C headers
#define EBPF_STACK_SIZE 512
#endif

class llvm_bpf_jit_context {
	llvmbpf_vm &vm;

	std::unique_ptr<pthread_spinlock_t> compiling;
	llvm::Expected<llvm::orc::ThreadSafeModule>

	generateModule(const std::vector<std::string> &extFuncNames,
		       const std::vector<std::string> &lddwHelpers,
		       bool patch_map_val_at_compile_time,
		       bool is_cuda = false);
	std::vector<uint8_t>
	do_aot_compile(const std::vector<std::string> &extFuncNames,
		       const std::vector<std::string> &lddwHelpers,
		       bool print_ir);
	// (JIT, extFuncs, definedLddwSymbols)
	std::tuple<std::unique_ptr<llvm::orc::LLJIT>, std::vector<std::string>,
		   std::vector<std::string> >
	create_and_initialize_lljit_instance();

    public:
	std::optional<std::unique_ptr<llvm::orc::LLJIT> > jit;
	llvm::Error do_jit_compile();
	llvm_bpf_jit_context(llvmbpf_vm &vm);
	virtual ~llvm_bpf_jit_context();
	precompiled_ebpf_function get_entry_address();
	std::vector<uint8_t> do_aot_compile(bool print_ir = false);
	llvm::Error load_aot_object(const std::vector<uint8_t> &buf);
	std::optional<std::string>
	generate_ptx(const char *target_cpu = "sm_60");
};

std::string get_trampoline_ptx();
std::string patch_helper_names_and_header(std::string ptx_to_wrap);
std::string patch_main_from_func_to_entry(std::string);
std::string wrap_ptx_with_trampoline(std::string input);
} // namespace bpftime

#endif
