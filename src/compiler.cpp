/* SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2022, eunomia-bpf org
 * All rights reserved.
 */
#include "llvm/IR/Argument.h"
#include "llvm_jit_context.hpp"
#include "ebpf_inst.h"
#include "spdlog/spdlog.h"
#include <cassert>
#include <cstdint>
#include <llvm/Support/Alignment.h>
#include <llvm/Support/AtomicOrdering.h>
#include <llvm/Support/Error.h>
#include <llvm/ExecutionEngine/Orc/ThreadSafeModule.h>
#include <llvm/IR/BasicBlock.h>
#include <llvm/IR/Instruction.h>
#include <llvm/IR/Value.h>
#include <llvm/Support/raw_ostream.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/Intrinsics.h>
#include <llvm/IR/Verifier.h>
#include <llvm/Support/Debug.h>
#include <map>
#include <vector>
#include <endian.h>
#include "compiler_utils.hpp"
#include <spdlog/spdlog.h>

using namespace llvm;
using namespace llvm::orc;
using namespace bpftime;

const int STACK_SIZE = (EBPF_STACK_SIZE + 7) / 8;
const int CALL_STACK_SIZE = 64;

const size_t MAX_LOCAL_FUNC_DEPTH = 32;

/*
    How should we compile bpf instructions into a LLVM module?
    - Split basic blocks
    - Iterate over the instructions, for each basic block, emit a LLVM
   BasicBlock for that

    Supported instructions:
	ALU:
	EBPF_OP_ADD_IMM, EBPF_OP_ADD_REG, EBPF_OP_SUB_IMM, EBPF_OP_SUB_REG,
   EBPF_OP_MUL_IMM, EBPF_OP_MUL_REG, EBPF_OP_DIV_IMM, EBPF_OP_DIV_REG,
   EBPF_OP_OR_IMM, EBPF_OP_OR_REG, EBPF_OP_AND_IMM, EBPF_OP_AND_REG,
   EBPF_OP_LSH_IMM, EBPF_OP_LSH_REG, EBPF_OP_RSH_IMM, EBPF_OP_RSH_REG,
   EBPF_OP_NEG, EBPF_OP_MOD_IMM, EBPF_OP_MOD_REG, EBPF_OP_XOR_IMM,
   EBPF_OP_XOR_REG, EBPF_OP_MOV_IMM, EBPF_OP_MOV_REG, EBPF_OP_ARSH_IMM,
   EBPF_OP_ARSH_REG, EBPF_OP_LE, EBPF_OP_BE

	EBPF_OP_ADD64_IMM, EBPF_OP_ADD64_REG, EBPF_OP_SUB64_IMM,
   EBPF_OP_SUB64_REG, EBPF_OP_MUL64_IMM, EBPF_OP_MUL64_REG, EBPF_OP_DIV64_IMM,
   EBPF_OP_DIV64_REG, EBPF_OP_OR64_IMM, EBPF_OP_OR64_REG, EBPF_OP_AND64_IMM,
   EBPF_OP_AND64_REG, EBPF_OP_LSH64_IMM, EBPF_OP_LSH64_REG, EBPF_OP_RSH64_IMM,
   EBPF_OP_RSH64_REG, EBPF_OP_NEG64, EBPF_OP_MOD64_IMM, EBPF_OP_MOD64_REG,
   EBPF_OP_XOR64_IMM, EBPF_OP_XOR64_REG, EBPF_OP_MOV64_IMM, EBPF_OP_MOV64_REG,
   EBPF_OP_ARSH64_IMM, EBPF_OP_ARSH64_REG

	Load & store:
	EBPF_OP_LDXW, EBPF_OP_LDXH, EBPF_OP_LDXB, EBPF_OP_LDXDW,
    EBPF_OP_STW, EBPF_OP_STH, EBPF_OP_STB, EBPF_OP_STDW,
    EBPF_OP_STXW, EBPF_OP_STXH, EBPF_OP_STXB, EBPF_OP_STXDW,
    EBPF_OP_LDDW,

	Jump:
	EBPF_OP_JA, EBPF_OP_JEQ_IMM, EBPF_OP_JEQ_REG, EBPF_OP_JEQ32_IMM,
   EBPF_OP_JEQ32_REG, EBPF_OP_JGT_IMM, EBPF_OP_JGT_REG, EBPF_OP_JGT32_IMM,
   EBPF_OP_JGT32_REG, EBPF_OP_JGE_IMM, EBPF_OP_JGE_REG, EBPF_OP_JGE32_IMM,
   EBPF_OP_JGE32_REG, EBPF_OP_JLT_IMM, EBPF_OP_JLT_REG, EBPF_OP_JLT32_IMM,
   EBPF_OP_JLT32_REG, EBPF_OP_JLE_IMM, EBPF_OP_JLE_REG, EBPF_OP_JLE32_IMM,
   EBPF_OP_JLE32_REG, EBPF_OP_JSET_IMM, EBPF_OP_JSET_REG, EBPF_OP_JSET32_IMM,
   EBPF_OP_JSET32_REG, EBPF_OP_JNE_IMM, EBPF_OP_JNE_REG, EBPF_OP_JNE32_IMM,
   EBPF_OP_JNE32_REG, EBPF_OP_JSGT_IMM, EBPF_OP_JSGT_REG, EBPF_OP_JSGT32_IMM,
   EBPF_OP_JSGT32_REG, EBPF_OP_JSGE_IMM, EBPF_OP_JSGE_REG, EBPF_OP_JSGE32_IMM,
   EBPF_OP_JSGE32_REG, EBPF_OP_JSLT_IMM, EBPF_OP_JSLT_REG, EBPF_OP_JSLT32_IMM,
   EBPF_OP_JSLT32_REG, EBPF_OP_JSLE_IMM, EBPF_OP_JSLE_REG, EBPF_OP_JSLE32_IMM,
   EBPF_OP_JSLE32_REG

	Other:
	EBPF_OP_EXIT, EBPF_OP_CALL
*/
Expected<ThreadSafeModule> llvm_bpf_jit_context::generateModule(
	const std::vector<std::string> &extFuncNames,
	const std::vector<std::string> &lddwHelpers,
	bool patch_map_val_at_compile_time)
{
	SPDLOG_DEBUG("Generating module: patch_map_val_at_compile_time={}",
		     patch_map_val_at_compile_time);
	auto context = std::make_unique<LLVMContext>();
	auto jitModule = std::make_unique<Module>("bpf-jit", *context);
	const auto &insts = vm.instructions;
	if (insts.empty()) {
		return llvm::make_error<llvm::StringError>(
			"No instructions provided",
			llvm::inconvertibleErrorCode());
	}

	// Define lddw helper function type
	FunctionType *lddwHelperWithUint32 =
		FunctionType::get(Type::getInt64Ty(*context),
				  { Type::getInt32Ty(*context) }, false);
	FunctionType *lddwHelperWithUint64 =
		FunctionType::get(Type::getInt64Ty(*context),
				  { Type::getInt64Ty(*context) }, false);
	std::map<std::string, Function *> lddwHelper;
	for (const auto &helperName : lddwHelpers) {
		Function *func;
		if (helperName == LDDW_HELPER_MAP_VAL) {
			func = Function::Create(lddwHelperWithUint64,
						Function::ExternalLinkage,
						helperName, jitModule.get());

		} else {
			func = Function::Create(lddwHelperWithUint32,
						Function::ExternalLinkage,
						helperName, jitModule.get());
		}
		SPDLOG_DEBUG("Initializing lddw function with name {}",
			     helperName);
		lddwHelper[helperName] = func;
	}
	// Define ext functions
	std::map<std::string, Function *> extFunc;
	FunctionType *helperFuncTy = FunctionType::get(
		Type::getInt64Ty(*context),
		{ Type::getInt64Ty(*context), Type::getInt64Ty(*context),
		  Type::getInt64Ty(*context), Type::getInt64Ty(*context),
		  Type::getInt64Ty(*context) },
		false);

	for (const auto &name : extFuncNames) {
		auto currFunc = Function::Create(helperFuncTy,
						 Function::ExternalLinkage,
						 name, jitModule.get());
		extFunc[name] = currFunc;
	}
	std::vector<bool> blockBegin(insts.size(), false);
	// Split the blocks
	blockBegin[0] = true;
	for (uint16_t i = 0; i < insts.size(); i++) {
		auto curr = insts[i];
		SPDLOG_TRACE("check pc {} opcode={} ", i,
			     (uint16_t)curr.opcode);
		if (i > 0 && is_jmp(insts[i - 1])) {
			blockBegin[i] = true;
			SPDLOG_TRACE("mark {} block begin", i);
		}
		if (is_imm_jmp(curr)) {
			SPDLOG_TRACE("mark {} block begin", i + curr.imm + 1);
			blockBegin[i + curr.imm + 1] = true;
		} else if (is_jmp(curr)) {
			SPDLOG_TRACE("mark {} block begin",
				     i + curr.offset + 1);
			blockBegin[i + curr.offset + 1] = true;
		}
	}

	// The main function
	Function *bpf_func = Function::Create(
		FunctionType::get(Type::getInt64Ty(*context),
				  { llvm::PointerType::getUnqual(
					    llvm::Type::getInt8Ty(*context)),
				    Type::getInt64Ty(*context) },
				  false),
		Function::ExternalLinkage, "bpf_main", jitModule.get());

	// Get args of uint64_t bpf_main(uint64_t, uint64_t)
	llvm::Argument *mem = bpf_func->getArg(0);
	llvm::Argument *mem_len = bpf_func->getArg(1);

	std::vector<Value *> regs;
	std::vector<BasicBlock *> allBlocks;
	// Stack used to save return address and saved registers
	Value *callStack, *callItemCnt;
	{
		BasicBlock *setupBlock =
			BasicBlock::Create(*context, "setupBlock", bpf_func);
		allBlocks.push_back(setupBlock);
		IRBuilder<> builder(setupBlock);
		// Create registers

		for (int i = 0; i <= 10; i++) {
			regs.push_back(builder.CreateAlloca(
				builder.getInt64Ty(), nullptr,
				"r" + std::to_string(i)));
		}
		// Create stack
		auto stackBegin = builder.CreateAlloca(
			builder.getInt64Ty(),
			builder.getInt32(STACK_SIZE * MAX_LOCAL_FUNC_DEPTH +
					 10),
			"stackBegin");
		auto stackEnd = builder.CreateGEP(
			builder.getInt64Ty(), stackBegin,
			{ builder.getInt32(STACK_SIZE * MAX_LOCAL_FUNC_DEPTH) },
			"stackEnd");
		// Write stack pointer into r10
		builder.CreateStore(stackEnd, regs[10]);
		// Write memory address into r1
		builder.CreateStore(mem, regs[1]);
		// Write memory len into r1
		builder.CreateStore(mem_len, regs[2]);

		callStack = builder.CreateAlloca(
			builder.getPtrTy(),
			builder.getInt32(CALL_STACK_SIZE * 5), "callStack");
		callItemCnt = builder.CreateAlloca(builder.getInt64Ty(),
						   nullptr, "callItemCnt");
		builder.CreateStore(builder.getInt64(0), callItemCnt);
	}
	// These blocks are the next instructions of the returning target of
	// local functions
	std::map<uint16_t, BlockAddress *> localFuncRetBlks;
	// Prepare basic blocks
	std::map<uint16_t, BasicBlock *> instBlocks;
	{
		IRBuilder<> builder(*context);

		for (uint16_t i = 0; i < insts.size(); i++) {
			if (blockBegin[i]) {
				// Create a block
				auto currBlk = BasicBlock::Create(
					*context,
					"bb_inst_" + std::to_string(i),
					bpf_func);
				instBlocks[i] = currBlk;
				allBlocks.push_back(currBlk);

				// Indicating that these block is the next
				// instruction of a local func call
				if (i > 1 &&
				    insts[i - 1].opcode == EBPF_OP_CALL &&
				    insts[i - 1].src == 0x01) {
					auto blockAddr =
						llvm::BlockAddress::get(
							bpf_func, currBlk);
					localFuncRetBlks[i] = blockAddr;
				}
			}
		}
	}

	// Basic block used to exit the eBPF program
	// will read r0 and return it
	BasicBlock *exitBlk =
		BasicBlock::Create(*context, "exitBlock", bpf_func);

	{
		IRBuilder<> builder(exitBlk);
		builder.CreateRet(
			builder.CreateLoad(builder.getInt64Ty(), regs[0]));
	}

	// Basic blocks that handle the returning of local func

	BasicBlock *localRetBlk =
		BasicBlock::Create(*context, "localFuncReturnBlock", bpf_func);
	{
		// The most top one is the returning address, followed by r6,
		// r7, r8, r9
		IRBuilder<> builder(localRetBlk);
		Value *count =
			builder.CreateLoad(builder.getInt64Ty(), callItemCnt);
		// Load return address
		Value *targetAddr = builder.CreateLoad(
			builder.getPtrTy(),
			builder.CreateGEP(
				builder.getPtrTy(), callStack,
				{ builder.CreateSub(count,
						    builder.getInt64(1)) }));
		// Restore registers
		for (int i = 6; i <= 9; i++) {
			builder.CreateStore(
				builder.CreateLoad(
					builder.getInt64Ty(),
					builder.CreateGEP(
						builder.getInt64Ty(), callStack,
						{ builder.CreateSub(
							count,
							builder.getInt64(
								i - 4)) })),
				regs[i]);
		}
		builder.CreateStore(builder.CreateSub(count,
						      builder.getInt64(5)),
				    callItemCnt);
		// Restore data stack
		// r10 += stack_size
		builder.CreateStore(
			builder.CreateAdd(
				builder.CreateLoad(builder.getInt64Ty(),
						   regs[10]),
				builder.getInt64(STACK_SIZE)),
			regs[10]);
		auto indrBr = builder.CreateIndirectBr(targetAddr);
		for (const auto &item : localFuncRetBlks) {
			indrBr->addDestination(instBlocks[item.first]);
		}
	}
	// Iterate over instructions
	BasicBlock *currBB = instBlocks[0];
	IRBuilder<> builder(currBB);
	for (uint16_t pc = 0; pc < insts.size(); pc++) {
		auto inst = insts[pc];
		if (blockBegin[pc]) {
			if (auto itr = instBlocks.find(pc);
			    itr != instBlocks.end()) {
				currBB = itr->second;
			} else {
				return llvm::make_error<llvm::StringError>(
					"pc=" + std::to_string(pc) +
						" was marked block begin, but no BasicBlock* found",
					llvm::inconvertibleErrorCode());
			}
		}
		builder.SetInsertPoint(currBB);
		// Precheck for registers
		if (inst.dst > 10 || inst.src > 10) {
			return llvm::make_error<llvm::StringError>(
				"Illegal src reg/dst reg at pc " +
					std::to_string(pc),
				llvm::inconvertibleErrorCode());
		}
		switch (inst.opcode) {
			// ALU
		case EBPF_OP_ADD64_IMM:
		case EBPF_OP_ADD_IMM:
		case EBPF_OP_ADD64_REG:
		case EBPF_OP_ADD_REG: {
			emitALUWithDstAndSrc(
				inst, builder, &regs[0],
				[&](Value *dst_val, Value *src_val) {
					return builder.CreateAdd(dst_val,
								 src_val);
				});

			break;
		}
		case EBPF_OP_SUB64_IMM:
		case EBPF_OP_SUB_IMM:
		case EBPF_OP_SUB64_REG:
		case EBPF_OP_SUB_REG: {
			emitALUWithDstAndSrc(
				inst, builder, &regs[0],
				[&](Value *dst_val, Value *src_val) {
					return builder.CreateSub(dst_val,
								 src_val);
				});
			break;
		}
		case EBPF_OP_MUL64_IMM:
		case EBPF_OP_MUL_IMM:
		case EBPF_OP_MUL64_REG:
		case EBPF_OP_MUL_REG: {
			emitALUWithDstAndSrc(
				inst, builder, &regs[0],
				[&](Value *dst_val, Value *src_val) {
					return builder.CreateBinOp(
						Instruction::BinaryOps::Mul,
						dst_val, src_val);
				});
			break;
		}
		case EBPF_OP_DIV64_IMM:
		case EBPF_OP_DIV_IMM:
		case EBPF_OP_DIV64_REG:
		case EBPF_OP_DIV_REG: {
			// Set dst to zero if trying to being divided by
			// zero
			{
				emitALUWithDstAndSrc(inst, builder, &regs[0], [&](Value *dst_val, Value *src_val) {
					bool is_64 = is_alu64(inst);
					bool is_sdiv = inst.offset == 1;
					auto src_is_zero = builder.CreateICmpEQ(
						src_val,
						is_64 ? builder.getInt64(0) :
							builder.getInt32(0));
					auto zero =
						is_alu64(inst) ?
							builder.getInt64(0) :
							builder.getInt32(0);
					Value *result;
					if (is_64) {
						if (is_sdiv) {
							/**
							  If
is_64 is true, src_val will be zero-extended to 64-bit. According to
eBPF docs, it should actually be sign-extended to 64-bit, so we perform
this conversion.
							 */
							src_val = builder.CreateSExt(
								builder.CreateTrunc(
									src_val,
									builder.getInt32Ty()),
								builder.getInt64Ty());
							// dst = I64_MIN and src
							// = -1? Overflow!
							auto overflow_cond = builder.CreateAnd(
								{ builder.CreateCmp(
									  CmpInst::Predicate::
										  ICMP_EQ,
									  dst_val,
									  builder.getInt64(
										  INT64_MIN)),
								  builder.CreateCmp(
									  CmpInst::Predicate::
										  ICMP_EQ,
									  src_val,
									  builder.getInt64(
										  -1)) });
							result = builder.CreateSelect(
								overflow_cond,
								builder.getInt64(
									INT64_MIN),
								builder.CreateSDiv(
									dst_val,
									src_val));
						} else {
							result =
								builder.CreateUDiv(
									dst_val,
									src_val);
						}
					} else {
						if (is_sdiv) {
							// dst = I64_MIN and src
							// = -1? Overflow!
							auto overflow_cond = builder.CreateAnd(
								{ builder.CreateCmp(
									  CmpInst::Predicate::
										  ICMP_EQ,
									  dst_val,
									  builder.getInt32(
										  INT32_MIN)),
								  builder.CreateCmp(
									  CmpInst::Predicate::
										  ICMP_EQ,
									  src_val,
									  builder.getInt32(
										  -1)) });
							result = builder.CreateSelect(
								overflow_cond,
								builder.getInt32(
									INT32_MIN),
								builder.CreateSDiv(
									dst_val,
									src_val));
						} else {
							result =
								builder.CreateUDiv(
									dst_val,
									src_val);
						}
					}

					return builder.CreateSelect(
						src_is_zero, zero, result);
				});

				break;
			}
		}
		case EBPF_OP_OR64_IMM:
		case EBPF_OP_OR_IMM:
		case EBPF_OP_OR64_REG:
		case EBPF_OP_OR_REG: {
			emitALUWithDstAndSrc(
				inst, builder, &regs[0],
				[&](Value *dst_val, Value *src_val) {
					return builder.CreateOr(dst_val,
								src_val);
				});
			break;
		}
		case EBPF_OP_AND64_IMM:
		case EBPF_OP_AND_IMM:
		case EBPF_OP_AND64_REG:
		case EBPF_OP_AND_REG: {
			emitALUWithDstAndSrc(
				inst, builder, &regs[0],
				[&](Value *dst_val, Value *src_val) {
					return builder.CreateAnd(dst_val,
								 src_val);
				});
			break;
		}
		case EBPF_OP_LSH64_IMM:
		case EBPF_OP_LSH_IMM:
		case EBPF_OP_LSH64_REG:
		case EBPF_OP_LSH_REG: {
			emitALUWithDstAndSrc(
				inst, builder, &regs[0],
				[&](Value *dst_val, Value *src_val) {
					return builder.CreateShl(
						dst_val,
						is_alu64(inst) ?
							builder.CreateURem(
								src_val,
								builder.getInt64(
									64)) :
							builder.CreateURem(
								src_val,
								builder.getInt32(
									32)));
				});
			break;
		}
		case EBPF_OP_RSH64_IMM:
		case EBPF_OP_RSH_IMM:
		case EBPF_OP_RSH64_REG:
		case EBPF_OP_RSH_REG: {
			emitALUWithDstAndSrc(
				inst, builder, &regs[0],
				[&](Value *dst_val, Value *src_val) {
					return builder.CreateLShr(
						dst_val,
						is_alu64(inst) ?
							builder.CreateURem(
								src_val,
								builder.getInt64(
									64)) :
							builder.CreateURem(
								src_val,
								builder.getInt32(
									32)));
				});

			break;
		}
		case EBPF_OP_NEG:
		case EBPF_OP_NEG64: {
			Value *dst_val =
				emitLoadALUDest(inst, &regs[0], builder, false);
			Value *result = builder.CreateNeg(dst_val);
			emitStoreALUResult(inst, &regs[0], builder, result);
			break;
		}
		case EBPF_OP_MOD64_IMM:
		case EBPF_OP_MOD_IMM:
		case EBPF_OP_MOD64_REG:
		case EBPF_OP_MOD_REG: {
			bool is_smod = inst.offset == 1;
			bool is_64 = is_alu64(inst);
			emitALUWithDstAndSrc(inst, builder, &regs[0], [&](Value *dst_val, Value *src_val) {
				// Keep dst untouched is src is
				// zero
				return builder.CreateSelect(
					builder.CreateICmpEQ(
						src_val,
						is_alu64(inst) ?
							builder.getInt64(0) :
							builder.getInt32(0)),
					dst_val,
					is_smod ?
						builder.CreateSRem(
							is_64 ? builder.CreateSExt(
									dst_val,
									builder.getInt64Ty()) :
								dst_val,
							is_64 ? builder.CreateSExt(
									builder.CreateTrunc(
										src_val,
										builder.getInt32Ty()),
									builder.getInt64Ty()) :
								src_val) :
						builder.CreateURem(dst_val,
								   src_val));
			});

			break;
		}
		case EBPF_OP_XOR64_IMM:
		case EBPF_OP_XOR_IMM:
		case EBPF_OP_XOR64_REG:
		case EBPF_OP_XOR_REG: {
			emitALUWithDstAndSrc(
				inst, builder, &regs[0],
				[&](Value *dst_val, Value *src_val) {
					return builder.CreateXor(dst_val,
								 src_val);
				});
			break;
		}
		case EBPF_OP_MOV64_IMM:
		case EBPF_OP_MOV_IMM:
		case EBPF_OP_MOV64_REG:
		case EBPF_OP_MOV_REG: {
			bool is_mov_sx = inst.offset != 0;
			Value *src_val =
				emitLoadALUSource(inst, &regs[0], builder);
			Value *result;
			if (is_mov_sx) {
				// for alu64: dst = (u64)(s64)(sOFFSET)src
				// for alu(32): dst = (u32)(s32)(sOFFSET)src
				Value *extended_result;
				if (inst.offset == 8) {
					extended_result = builder.CreateSExt(
						builder.CreateTrunc(
							src_val,
							builder.getInt8Ty()),
						builder.getInt8Ty());
				} else if (inst.offset == 16) {
					extended_result = builder.CreateSExt(
						builder.CreateTrunc(
							src_val,
							builder.getInt16Ty()),
						builder.getInt16Ty());
				} else if (inst.offset == 32) {
					extended_result = builder.CreateSExt(
						builder.CreateTrunc(
							src_val,
							builder.getInt32Ty()),
						builder.getInt32Ty());
				} else {
					return llvm::make_error<
						llvm::StringError>(
						"Invalid offset " +
							std::to_string(
								inst.offset) +
							" for movsx at pc " +
							std::to_string(pc),
						llvm::inconvertibleErrorCode());
				}
				if (is_alu64(inst)) {
					// convert it to u64  is not needed,
					// llvm ir uses unsigned numbers
					result = builder.CreateCast(
						Instruction::CastOps::SExt,
						extended_result,
						builder.getInt64Ty());
				} else {
					result = builder.CreateCast(
						Instruction::CastOps::SExt,
						extended_result,
						builder.getInt32Ty());
				}
			} else {
				result = src_val;
			}
			emitStoreALUResult(inst, &regs[0], builder, result);
			break;
		}

		case EBPF_OP_ARSH64_IMM:
		case EBPF_OP_ARSH_IMM:
		case EBPF_OP_ARSH64_REG:
		case EBPF_OP_ARSH_REG: {
			emitALUWithDstAndSrc(
				inst, builder, &regs[0],
				[&](Value *dst_val, Value *src_val) {
					return builder.CreateAShr(
						dst_val,
						is_alu64(inst) ?
							builder.CreateURem(
								src_val,
								builder.getInt64(
									64)) :
							builder.CreateURem(
								src_val,
								builder.getInt32(
									32)));
				});
			break;
		}
		case EBPF_OP_LE:
		case EBPF_OP_BE:
		case EBPF_OP_BYTESWAP: {
			Value *dst_val =
				emitLoadALUDest(inst, &regs[0], builder, true);
			Value *result;
			if (auto exp = emitALUEndianConversion(inst, builder,
							       dst_val);
			    exp) {
				result = exp.get();
			} else {
				return exp.takeError();
			}
			emitStoreALUResult(inst, &regs[0], builder, result);
			break;
		}

			// ST and STX
			//  Only supports mode = 0x60
		case EBPF_OP_STB:
		case EBPF_OP_STXB: {
			emitStore(inst, builder, &regs[0], builder.getInt8Ty());
			break;
		}
		case EBPF_OP_STH:
		case EBPF_OP_STXH: {
			emitStore(inst, builder, &regs[0],
				  builder.getInt16Ty());
			break;
		}
		case EBPF_OP_STW:
		case EBPF_OP_STXW: {
			emitStore(inst, builder, &regs[0],
				  builder.getInt32Ty());
			break;
		}
		case EBPF_OP_STDW:
		case EBPF_OP_STXDW: {
			emitStore(inst, builder, &regs[0],
				  builder.getInt64Ty());
			break;
		}
			// LDX
			// Only supports mode=0x60
		case EBPF_OP_LDXB: {
			emitLoadX(builder, &regs[0], inst, builder.getInt8Ty());
			break;
		}
		case EBPF_OP_LDXH: {
			emitLoadX(builder, &regs[0], inst,
				  builder.getInt16Ty());
			break;
		}
		case EBPF_OP_LDXW: {
			emitLoadX(builder, &regs[0], inst,
				  builder.getInt32Ty());
			break;
		}
		case EBPF_OP_LDXDW: {
			emitLoadX(builder, &regs[0], inst,
				  builder.getInt64Ty());
			break;
		}
		// LD
		// Keep compatiblity to ubpf
		case EBPF_OP_LDDW: {
			// ubpf only supports EBPF_OP_LDDW in instruction class
			// EBPF_CLS_LD, so do us
			auto size = inst.opcode & 0x18;
			auto mode = inst.opcode & 0xe0;
			if (size != 0x18 || mode != 0x00) {
				return llvm::make_error<llvm::StringError>(
					"Unsupported size (" +
						std::to_string(size) +
						") or mode (" +
						std::to_string(mode) +
						") for non-standard load operations" +
						" at pc " + std::to_string(pc),
					llvm::inconvertibleErrorCode());
			}
			if (pc + 1 >= insts.size()) {
				return llvm::make_error<llvm::StringError>(
					"Loaded LDDW at pc=" +
						std::to_string(pc) +
						" which requires an extra pseudo instruction, but it's the last instruction",
					llvm::inconvertibleErrorCode());
			}
			const auto &nextinst = insts[pc + 1];
			if (nextinst.opcode || nextinst.dst || nextinst.src ||
			    nextinst.offset) {
				return llvm::make_error<llvm::StringError>(
					"Loaded LDDW at pc=" +
						std::to_string(pc) +
						" which requires an extra pseudo instruction, but the next instruction is not a legal one",
					llvm::inconvertibleErrorCode());
			}
			uint64_t val =
				(uint64_t)((uint32_t)inst.imm) |
				(((uint64_t)((uint32_t)nextinst.imm)) << 32);
			pc++;

			SPDLOG_DEBUG("Load LDDW val= {} part1={:x} part2={:x}",
				     val, (uint64_t)inst.imm,
				     (uint64_t)nextinst.imm);
			if (inst.src == 0) {
				SPDLOG_DEBUG("Emit lddw helper 0 at pc {}", pc);
				builder.CreateStore(builder.getInt64(val),
						    regs[inst.dst]);
			} else if (inst.src == 1) {
				SPDLOG_DEBUG(
					"Emit lddw helper 1 (map_by_fd) at pc {}, imm={}, patched at compile time",
					pc, inst.imm);
				if (vm.map_by_fd) {
					builder.CreateStore(
						builder.getInt64(
							vm.map_by_fd(inst.imm)),
						regs[inst.dst]);
				} else {
					SPDLOG_INFO(
						"map_by_fd is called in eBPF code, but is not provided, will use the default behavior");
					// Default: input value
					builder.CreateStore(
						builder.getInt64(
							(int64_t)inst.imm),
						regs[inst.dst]);
				}

			} else if (inst.src == 2) {
				SPDLOG_DEBUG(
					"Emit lddw helper 2 (map_by_fd + map_val) at pc {}, imm1={}, imm2={}",
					pc, inst.imm, nextinst.imm);
				uint64_t mapPtr;
				if (vm.map_by_fd) {
					mapPtr = vm.map_by_fd(inst.imm);
				} else {
					SPDLOG_INFO(
						"map_by_fd is called in eBPF code, but is not provided, will use the default behavior");
					// Default: returns the input value
					mapPtr = (uint64_t)inst.imm;
				}
				if (patch_map_val_at_compile_time) {
					SPDLOG_DEBUG(
						"map_val is required to be evaluated at compile time");
					if (!vm.map_val) {
						return llvm::make_error<
							llvm::StringError>(
							"map_val is not provided, unable to compile at pc " +
								std::to_string(
									pc),
							llvm::inconvertibleErrorCode());
					}
					builder.CreateStore(
						builder.getInt64(
							vm.map_val(mapPtr) +
							nextinst.imm),
						regs[inst.dst]);
				} else {
					SPDLOG_DEBUG(
						"map_val is required to be evaluated at runtime, emitting calling instructions");
					if (auto itrMapVal = lddwHelper.find(
						    LDDW_HELPER_MAP_VAL);
					    itrMapVal != lddwHelper.end()) {
						auto retMapVal = builder.CreateCall(
							lddwHelperWithUint64,
							itrMapVal->second,
							{ builder.getInt64(
								mapPtr) });
						auto finalRet = builder.CreateAdd(
							retMapVal,
							builder.getInt64(
								nextinst.imm));
						builder.CreateStore(
							finalRet,
							regs[inst.dst]);

					} else {
						return llvm::make_error<
							llvm::StringError>(
							"Using lddw helper 2, which requires map_val to be defined at pc " +
								std::to_string(
									pc),
							llvm::inconvertibleErrorCode());
					}
				}

			} else if (inst.src == 3) {
				SPDLOG_DEBUG(
					"Emit lddw helper 3 (var_addr) at pc {}, imm1={}",
					pc, inst.imm);
				if (!vm.var_addr) {
					return llvm::make_error<
						llvm::StringError>(
						"var_addr is not provided, unable to compile at pc " +
							std::to_string(pc),
						llvm::inconvertibleErrorCode());
				}
				builder.CreateStore(
					builder.getInt64(vm.var_addr(inst.imm)),
					regs[inst.dst]);
			} else if (inst.src == 4) {
				SPDLOG_DEBUG(
					"Emit lddw helper 4 (code_addr) at pc {}, imm1={}",
					pc, inst.imm);
				if (!vm.code_addr) {
					return llvm::make_error<
						llvm::StringError>(
						"code_addr is not provided, unable to compile at pc " +
							std::to_string(pc),
						llvm::inconvertibleErrorCode());
				}
				builder.CreateStore(
					builder.getInt64(
						vm.code_addr(inst.imm)),
					regs[inst.dst]);
			} else if (inst.src == 5) {
				SPDLOG_DEBUG(
					"Emit lddw helper 4 (map_by_idx) at pc {}, imm1={}",
					pc, inst.imm);
				if (vm.map_by_idx) {
					builder.CreateStore(
						builder.getInt64(vm.map_by_idx(
							inst.imm)),
						regs[inst.dst]);
				} else {
					SPDLOG_INFO(
						"map_by_idx is called in eBPF code, but it's not provided, will use the default behavior");
					// Default: returns the input value
					builder.CreateStore(
						builder.getInt64(
							(int64_t)inst.imm),
						regs[inst.dst]);
				}

			} else if (inst.src == 6) {
				SPDLOG_DEBUG(
					"Emit lddw helper 6 (map_by_idx + map_val) at pc {}, imm1={}, imm2={}",
					pc, inst.imm, nextinst.imm);

				uint64_t mapPtr;
				if (vm.map_by_idx) {
					mapPtr = vm.map_by_idx(inst.imm);
				} else {
					SPDLOG_DEBUG(
						"map_by_idx is called in eBPF code, but it's not provided, will use the default behavior");
					// Default: returns the input value
					mapPtr = (int64_t)inst.imm;
				}
				if (patch_map_val_at_compile_time) {
					SPDLOG_DEBUG(
						"Required to evaluate map_val at compile time");
					if (vm.map_val) {
						builder.CreateStore(
							builder.getInt64(
								vm.map_val(
									mapPtr) +
								nextinst.imm),
							regs[inst.dst]);
					} else {
						return llvm::make_error<
							llvm::StringError>(
							"map_val is not provided, unable to compile at pc " +
								std::to_string(
									pc),
							llvm::inconvertibleErrorCode());
					}

				} else {
					SPDLOG_DEBUG(
						"Required to evaluate map_val at runtime time");
					if (auto itrMapVal = lddwHelper.find(
						    LDDW_HELPER_MAP_VAL);
					    itrMapVal != lddwHelper.end()) {
						auto retMapVal = builder.CreateCall(
							lddwHelperWithUint64,
							itrMapVal->second,
							{ builder.getInt64(
								mapPtr) });
						auto finalRet = builder.CreateAdd(
							retMapVal,
							builder.getInt64(
								nextinst.imm));
						builder.CreateStore(
							finalRet,
							regs[inst.dst]);

					} else {
						return llvm::make_error<
							llvm::StringError>(
							"Using lddw helper 6 at pc " +
								std::to_string(
									pc),
							llvm::inconvertibleErrorCode());
					}
				}
			}
			break;
		}
			// JMP
		case EBPF_OP_JA: {
			if (auto dst =
				    loadJmpDstBlock(pc, inst, instBlocks, true);
			    dst) {
				builder.CreateBr(dst.get());

			} else {
				return dst.takeError();
			}
			break;
		}
		// JMP imm
		case EBPF_OP_JA_IMM: {
			if (auto dst = loadJmpDstBlock(pc, inst, instBlocks,
						       false);
			    dst) {
				builder.CreateBr(dst.get());

			} else {
				return dst.takeError();
			}
			break;
		}
			// Call helper or local function
		case EBPF_OP_CALL:
			// Work around for clang producing instructions
			// that we don't support
		case EBPF_OP_CALL | 0x8: {
			// Call local function
			if (inst.src == 0x1) {
				// Each call will put five 8byte integer
				// onto the call stack the most top one
				// is the return address, followed by
				// r6, r7, r8, r9
				Value *nextPos = builder.CreateAdd(
					builder.CreateLoad(builder.getInt64Ty(),
							   callItemCnt),
					builder.getInt64(5));
				builder.CreateStore(nextPos, callItemCnt);
				assert(localFuncRetBlks.contains(pc + 1));
				// Store returning address
				builder.CreateStore(
					localFuncRetBlks[pc + 1],
					builder.CreateGEP(
						builder.getPtrTy(), callStack,
						{ builder.CreateSub(
							nextPos,
							builder.getInt64(1)) }));
				// Store callee-saved registers
				for (int i = 6; i <= 9; i++) {
					builder.CreateStore(
						builder.CreateLoad(
							builder.getInt64Ty(),
							regs[i]),
						builder.CreateGEP(
							builder.getInt64Ty(),
							callStack,
							{ builder.CreateSub(
								nextPos,
								builder.getInt64(
									i -
									4)) }));
				}
				// Move data stack
				// r10 -= stackSize
				builder.CreateStore(
					builder.CreateSub(
						builder.CreateLoad(
							builder.getInt64Ty(),
							regs[10]),
						builder.getInt64(STACK_SIZE)),
					regs[10]);
				if (auto dstBlk = loadCallDstBlock(pc, inst,
								   instBlocks);
				    dstBlk) {
					builder.CreateBr(dstBlk.get());
				} else {
					return dstBlk.takeError();
				}

			} else {
				if (auto exp = emitExtFuncCall(
					    builder, inst, extFunc, &regs[0],
					    helperFuncTy, pc, exitBlk);
				    !exp) {
					return exp.takeError();
				}
			}

			break;
		}
		case EBPF_OP_EXIT: {
			builder.CreateCondBr(
				builder.CreateICmpEQ(
					builder.CreateLoad(builder.getInt64Ty(),
							   callItemCnt),
					builder.getInt64(0)),
				exitBlk, localRetBlk);
			break;
		}

#define HANDLE_ERR(ret)                                                        \
	{                                                                      \
		if (!ret)                                                      \
			return ret.takeError();                                \
	}

		case EBPF_OP_JEQ32_IMM:
		case EBPF_OP_JEQ_IMM:
		case EBPF_OP_JEQ32_REG:
		case EBPF_OP_JEQ_REG: {
			HANDLE_ERR(emitCondJmpWithDstAndSrc(
				builder, pc, inst, instBlocks, &regs[0],
				[&](auto dst, auto src) {
					return builder.CreateICmpEQ(dst, src);
				}));
			break;
		}

		case EBPF_OP_JGT32_IMM:
		case EBPF_OP_JGT_IMM:
		case EBPF_OP_JGT32_REG:
		case EBPF_OP_JGT_REG: {
			HANDLE_ERR(emitCondJmpWithDstAndSrc(
				builder, pc, inst, instBlocks, &regs[0],
				[&](auto dst, auto src) {
					return builder.CreateICmpUGT(dst, src);
				}));
			break;
		}
		case EBPF_OP_JGE32_IMM:
		case EBPF_OP_JGE_IMM:
		case EBPF_OP_JGE32_REG:
		case EBPF_OP_JGE_REG: {
			HANDLE_ERR(emitCondJmpWithDstAndSrc(
				builder, pc, inst, instBlocks, &regs[0],
				[&](auto dst, auto src) {
					return builder.CreateICmpUGE(dst, src);
				}));
			break;
		}
		case EBPF_OP_JSET32_IMM:
		case EBPF_OP_JSET_IMM:
		case EBPF_OP_JSET32_REG:
		case EBPF_OP_JSET_REG: {
			if (auto ret =
				    localJmpDstAndNextBlk(pc, inst, instBlocks);
			    ret) {
				auto [dstBlk, nextBlk] = ret.get();
				auto [src, dst, zero] =
					emitJmpLoadSrcAndDstAndZero(
						inst, &regs[0], builder);
				builder.CreateCondBr(
					builder.CreateICmpNE(
						builder.CreateAnd(dst, src),
						zero),
					dstBlk, nextBlk);
			} else {
				return ret.takeError();
			}

			break;
		}
		case EBPF_OP_JNE32_IMM:
		case EBPF_OP_JNE_IMM:
		case EBPF_OP_JNE32_REG:
		case EBPF_OP_JNE_REG: {
			HANDLE_ERR(emitCondJmpWithDstAndSrc(
				builder, pc, inst, instBlocks, &regs[0],
				[&](auto dst, auto src) {
					return builder.CreateICmpNE(dst, src);
				}));
			break;
		}
		case EBPF_OP_JSGT32_IMM:
		case EBPF_OP_JSGT_IMM:
		case EBPF_OP_JSGT32_REG:
		case EBPF_OP_JSGT_REG: {
			HANDLE_ERR(emitCondJmpWithDstAndSrc(
				builder, pc, inst, instBlocks, &regs[0],
				[&](auto dst, auto src) {
					return builder.CreateICmpSGT(dst, src);
				}));
			break;
		}
		case EBPF_OP_JSGE32_IMM:
		case EBPF_OP_JSGE_IMM:
		case EBPF_OP_JSGE32_REG:
		case EBPF_OP_JSGE_REG: {
			HANDLE_ERR(emitCondJmpWithDstAndSrc(
				builder, pc, inst, instBlocks, &regs[0],
				[&](auto dst, auto src) {
					return builder.CreateICmpSGE(dst, src);
				}));
			break;
		}
		case EBPF_OP_JLT32_IMM:
		case EBPF_OP_JLT_IMM:
		case EBPF_OP_JLT32_REG:
		case EBPF_OP_JLT_REG: {
			HANDLE_ERR(emitCondJmpWithDstAndSrc(
				builder, pc, inst, instBlocks, &regs[0],
				[&](auto dst, auto src) {
					return builder.CreateICmpULT(dst, src);
				}));
			break;
		}
		case EBPF_OP_JLE32_IMM:
		case EBPF_OP_JLE_IMM:
		case EBPF_OP_JLE32_REG:
		case EBPF_OP_JLE_REG: {
			HANDLE_ERR(emitCondJmpWithDstAndSrc(
				builder, pc, inst, instBlocks, &regs[0],
				[&](auto dst, auto src) {
					return builder.CreateICmpULE(dst, src);
				}));
			break;
		}
		case EBPF_OP_JSLT32_IMM:
		case EBPF_OP_JSLT_IMM:
		case EBPF_OP_JSLT32_REG:
		case EBPF_OP_JSLT_REG: {
			HANDLE_ERR(emitCondJmpWithDstAndSrc(
				builder, pc, inst, instBlocks, &regs[0],
				[&](auto dst, auto src) {
					return builder.CreateICmpSLT(dst, src);
				}));
			break;
		}
		case EBPF_OP_JSLE32_IMM:
		case EBPF_OP_JSLE_IMM:
		case EBPF_OP_JSLE32_REG:
		case EBPF_OP_JSLE_REG: {
			HANDLE_ERR(emitCondJmpWithDstAndSrc(
				builder, pc, inst, instBlocks, &regs[0],
				[&](auto dst, auto src) {
					return builder.CreateICmpSLE(dst, src);
				}));
			break;
		}
		case EBPF_ATOMIC_OPCODE_32:
		case EBPF_ATOMIC_OPCODE_64: {
			switch (inst.imm) {
			case EBPF_ATOMIC_ADD:
			case EBPF_ATOMIC_ADD | EBPF_ATOMIC_OP_FETCH: {
				emitAtomicBinOp(
					builder, &regs[0],
					llvm::AtomicRMWInst::BinOp::Add, inst,
					inst.opcode == EBPF_ATOMIC_OPCODE_64,
					(inst.imm & EBPF_ATOMIC_OP_FETCH) ==
						EBPF_ATOMIC_OP_FETCH);
				break;
			}

			case EBPF_ATOMIC_AND:
			case EBPF_ATOMIC_AND | EBPF_ATOMIC_OP_FETCH: {
				emitAtomicBinOp(
					builder, &regs[0],
					llvm::AtomicRMWInst::BinOp::And, inst,
					inst.opcode == EBPF_ATOMIC_OPCODE_64,
					(inst.imm & EBPF_ATOMIC_OP_FETCH) ==
						EBPF_ATOMIC_OP_FETCH);
				break;
			}

			case EBPF_ATOMIC_OR:
			case EBPF_ATOMIC_OR | EBPF_ATOMIC_OP_FETCH: {
				emitAtomicBinOp(
					builder, &regs[0],
					llvm::AtomicRMWInst::BinOp::Or, inst,
					inst.opcode == EBPF_ATOMIC_OPCODE_64,
					(inst.imm & EBPF_ATOMIC_OP_FETCH) ==
						EBPF_ATOMIC_OP_FETCH);
				break;
			}
			case EBPF_ATOMIC_XOR:
			case EBPF_ATOMIC_XOR | EBPF_ATOMIC_OP_FETCH: {
				emitAtomicBinOp(
					builder, &regs[0],
					llvm::AtomicRMWInst::BinOp::Xor, inst,
					inst.opcode == EBPF_ATOMIC_OPCODE_64,
					(inst.imm & EBPF_ATOMIC_OP_FETCH) ==
						EBPF_ATOMIC_OP_FETCH);
				break;
			}
			case EBPF_ATOMIC_OP_XCHG: {
				emitAtomicBinOp(
					builder, &regs[0],
					llvm::AtomicRMWInst::BinOp::Xchg, inst,
					inst.opcode == EBPF_ATOMIC_OPCODE_64,
					false);
				break;
			}
			case EBPF_ATOMIC_OP_CMPXCHG: {
				bool is64 =
					inst.opcode == EBPF_ATOMIC_OPCODE_64;
				auto vPtr = builder.CreateGEP(
					builder.getInt8Ty(),
					builder.CreateLoad(builder.getPtrTy(),
							   regs[inst.dst]),
					{ builder.getInt64(inst.offset) });
				auto beforeVal = builder.CreateLoad(
					is64 ? builder.getInt64Ty() :
					       builder.getInt32Ty(),
					vPtr);
				builder.CreateAtomicCmpXchg(
					vPtr,
					builder.CreateLoad(
						is64 ? builder.getInt64Ty() :
						       builder.getInt32Ty(),
						regs[0]),
					builder.CreateLoad(
						is64 ? builder.getInt64Ty() :
						       builder.getInt32Ty(),
						regs[inst.src]),
					MaybeAlign(0),
					AtomicOrdering::Monotonic,
					AtomicOrdering::Monotonic);
				builder.CreateStore(
					builder.CreateZExt(beforeVal,
							   builder.getInt64Ty()),
					regs[0]);
				break;
			}
			default: {
				return llvm::make_error<llvm::StringError>(
					"Unsupported atomic operation: " +
						std::to_string(inst.imm),
					llvm::inconvertibleErrorCode());
			}
			}
			break;
		}
		default:
			return llvm::make_error<llvm::StringError>(
				"Unsupported or illegal opcode: " +
					std::to_string(inst.opcode) +
					" at pc " + std::to_string(pc),
				llvm::inconvertibleErrorCode());
		}
	}

	// Add br for all blocks
	for (size_t i = 0; i < allBlocks.size() - 1; i++) {
		auto &currBlk = allBlocks[i];
		if (currBlk->getTerminator() == nullptr) {
			builder.SetInsertPoint(allBlocks[i]);
			builder.CreateBr(allBlocks[i + 1]);
		}
	}
	std::string buffer;
	llvm::raw_string_ostream stream(buffer);
	if (verifyModule(*jitModule, &stream)) {
		SPDLOG_ERROR("Failed to verify module: {}", buffer);
		return llvm::make_error<llvm::StringError>(
			"Invalid module generated",
			llvm::inconvertibleErrorCode());
	}

	return ThreadSafeModule(std::move(jitModule), std::move(context));
}
