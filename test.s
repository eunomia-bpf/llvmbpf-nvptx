	.text
	.file	"test.cu"
	.globl	__device_stub__bpf_main         # -- Begin function __device_stub__bpf_main
	.p2align	4, 0x90
	.type	__device_stub__bpf_main,@function
__device_stub__bpf_main:                # @__device_stub__bpf_main
	.cfi_startproc
# %bb.0:
	subq	$88, %rsp
	.cfi_def_cfa_offset 96
	movq	%rdi, 56(%rsp)
	movq	%rsi, 48(%rsp)
	leaq	56(%rsp), %rax
	movq	%rax, 64(%rsp)
	leaq	48(%rsp), %rax
	movq	%rax, 72(%rsp)
	leaq	32(%rsp), %rdi
	leaq	16(%rsp), %rsi
	leaq	8(%rsp), %rdx
	movq	%rsp, %rcx
	callq	__cudaPopCallConfiguration@PLT
	movq	32(%rsp), %rsi
	movl	40(%rsp), %edx
	movq	16(%rsp), %rcx
	movl	24(%rsp), %r8d
	leaq	__device_stub__bpf_main(%rip), %rdi
	leaq	64(%rsp), %r9
	pushq	(%rsp)
	.cfi_adjust_cfa_offset 8
	pushq	16(%rsp)
	.cfi_adjust_cfa_offset 8
	callq	cudaLaunchKernel@PLT
	addq	$104, %rsp
	.cfi_adjust_cfa_offset -104
	retq
.Lfunc_end0:
	.size	__device_stub__bpf_main, .Lfunc_end0-__device_stub__bpf_main
	.cfi_endproc
                                        # -- End function
	.globl	_Z14signal_handleri             # -- Begin function _Z14signal_handleri
	.p2align	4, 0x90
	.type	_Z14signal_handleri,@function
_Z14signal_handleri:                    # @_Z14signal_handleri
	.cfi_startproc
# %bb.0:
	movb	$1, %al
	xchgb	%al, _ZL11should_exit.0(%rip)
	retq
.Lfunc_end1:
	.size	_Z14signal_handleri, .Lfunc_end1-_Z14signal_handleri
	.cfi_endproc
                                        # -- End function
	.globl	main                            # -- Begin function main
	.p2align	4, 0x90
	.type	main,@function
main:                                   # @main
.Lfunc_begin0:
	.cfi_startproc
	.cfi_personality 155, DW.ref.__gxx_personality_v0
	.cfi_lsda 27, .Lexception0
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%rbx
	.cfi_def_cfa_offset 40
	subq	$56, %rsp
	.cfi_def_cfa_offset 96
	.cfi_offset %rbx, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	leaq	_Z14signal_handleri(%rip), %rsi
	movl	$2, %edi
	callq	signal@PLT
	movl	$2147483752, %edi               # imm = 0x80000068
	callq	malloc@PLT
	movq	%rax, 8(%rsp)
	testq	%rax, %rax
	je	.LBB2_1
# %bb.2:
	movq	%rax, %rbx
	movl	$2147483752, %esi               # imm = 0x80000068
	movq	%rax, %rdi
	movl	$2, %edx
	callq	cudaHostRegister@PLT
	testl	%eax, %eax
	je	.LBB2_10
# %bb.3:
	movl	%eax, %ebp
	movq	_ZSt4cerr@GOTPCREL(%rip), %r14
	leaq	.L.str.1(%rip), %rsi
	movl	$24, %edx
	movq	%r14, %rdi
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	movl	%ebp, %edi
	callq	cudaGetErrorString@PLT
	testq	%rax, %rax
	je	.LBB2_4
# %bb.5:
	movq	%rax, %r15
	movq	%rax, %rdi
	callq	strlen@PLT
	movq	_ZSt4cerr@GOTPCREL(%rip), %rdi
	movq	%r15, %rsi
	movq	%rax, %rdx
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	jmp	.LBB2_6
.LBB2_1:
	movq	_ZSt4cerr@GOTPCREL(%rip), %rdi
	leaq	.L.str(%rip), %rsi
	movl	$27, %edx
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	jmp	.LBB2_8
.LBB2_10:
	movq	$0, 24(%rsp)
	leaq	24(%rsp), %rdi
	movq	%rbx, %rsi
	xorl	%edx, %edx
	callq	cudaHostGetDevicePointer@PLT
	testl	%eax, %eax
	je	.LBB2_16
# %bb.11:
	movl	%eax, %ebp
	movq	_ZSt4cerr@GOTPCREL(%rip), %r14
	leaq	.L.str.3(%rip), %rsi
	movl	$32, %edx
	jmp	.LBB2_12
.LBB2_4:
	movq	(%r14), %rax
	movq	-24(%rax), %rax
	leaq	(%r14,%rax), %rdi
	movl	32(%r14,%rax), %esi
	orl	$1, %esi
	callq	_ZNSt9basic_iosIcSt11char_traitsIcEE5clearESt12_Ios_Iostate@PLT
.LBB2_6:
	movq	_ZSt4cerr@GOTPCREL(%rip), %rdi
	leaq	.L.str.2(%rip), %rsi
	movl	$1, %edx
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	jmp	.LBB2_7
.LBB2_16:
	movq	24(%rsp), %rsi
	leaq	.L.str.4(%rip), %rdi
	movq	%rbx, %rdx
	xorl	%eax, %eax
	callq	printf@PLT
	leaq	constData(%rip), %rdi
	leaq	24(%rsp), %rsi
	movl	$8, %edx
	xorl	%ecx, %ecx
	movl	$1, %r8d
	callq	cudaMemcpyToSymbol@PLT
	testl	%eax, %eax
	je	.LBB2_18
# %bb.17:
	movl	%eax, %ebp
	movq	_ZSt4cerr@GOTPCREL(%rip), %r14
	leaq	.L.str.5(%rip), %rsi
	movl	$26, %edx
.LBB2_12:
	movq	%r14, %rdi
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	movl	%ebp, %edi
	callq	cudaGetErrorString@PLT
	testq	%rax, %rax
	je	.LBB2_13
# %bb.14:
	movq	%rax, %r15
	movq	%rax, %rdi
	callq	strlen@PLT
	movq	_ZSt4cerr@GOTPCREL(%rip), %rdi
	movq	%r15, %rsi
	movq	%rax, %rdx
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	jmp	.LBB2_15
.LBB2_13:
	movq	(%r14), %rax
	movq	-24(%rax), %rax
	leaq	(%r14,%rax), %rdi
	movl	32(%r14,%rax), %esi
	orl	$1, %esi
	callq	_ZNSt9basic_iosIcSt11char_traitsIcEE5clearESt12_Ios_Iostate@PLT
.LBB2_15:
	movq	_ZSt4cerr@GOTPCREL(%rip), %rdi
	leaq	.L.str.2(%rip), %rsi
	movl	$1, %edx
.LBB2_24:
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	movq	%rbx, %rdi
	callq	cudaHostUnregister@PLT
.LBB2_7:
	movq	%rbx, %rdi
	callq	free@PLT
.LBB2_8:
	movl	$-1, %eax
.LBB2_9:
	addq	$56, %rsp
	.cfi_def_cfa_offset 40
	popq	%rbx
	.cfi_def_cfa_offset 32
	popq	%r14
	.cfi_def_cfa_offset 24
	popq	%r15
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	retq
.LBB2_18:
	.cfi_def_cfa_offset 96
	movl	$11223344, 4(%rsp)              # imm = 0xAB4130
	leaq	4(%rsp), %rdi
	movl	$4, %esi
	movl	$2, %edx
	callq	cudaHostRegister@PLT
	testl	%eax, %eax
	je	.LBB2_25
# %bb.19:
	movl	%eax, %ebp
	movq	_ZSt4cerr@GOTPCREL(%rip), %r14
	leaq	.L.str.6(%rip), %rsi
	movl	$27, %edx
	movq	%r14, %rdi
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	movl	%ebp, %edi
	callq	cudaGetErrorString@PLT
	testq	%rax, %rax
	je	.LBB2_20
# %bb.21:
	movq	%rax, %r15
	movq	%rax, %rdi
	callq	strlen@PLT
	movq	_ZSt4cerr@GOTPCREL(%rip), %rdi
	movq	%r15, %rsi
	movq	%rax, %rdx
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	jmp	.LBB2_22
.LBB2_25:
	movq	$0, 32(%rsp)
	leaq	32(%rsp), %r14
	leaq	4(%rsp), %rsi
	movq	%r14, %rdi
	xorl	%edx, %edx
	callq	cudaHostGetDevicePointer@PLT
	testl	%eax, %eax
	je	.LBB2_27
# %bb.26:
	movl	%eax, %ebp
	movq	_ZSt4cerr@GOTPCREL(%rip), %r14
	leaq	.L.str.8(%rip), %rsi
	movl	$35, %edx
	movq	%r14, %rdi
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	movl	%ebp, %edi
	callq	cudaGetErrorString@PLT
	movq	%r14, %rdi
	movq	%rax, %rsi
	callq	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@PLT
	jmp	.LBB2_23
.LBB2_20:
	movq	(%r14), %rax
	movq	-24(%rax), %rax
	leaq	(%r14,%rax), %rdi
	movl	32(%r14,%rax), %esi
	orl	$1, %esi
	callq	_ZNSt9basic_iosIcSt11char_traitsIcEE5clearESt12_Ios_Iostate@PLT
.LBB2_22:
	movq	_ZSt4cerr@GOTPCREL(%rip), %r14
	leaq	.L.str.7(%rip), %rsi
	movl	$1, %edx
	movq	%r14, %rdi
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	movq	%r14, %rdi
	movl	%ebp, %esi
	callq	_ZNSolsEi@PLT
.LBB2_23:
	leaq	.L.str.2(%rip), %rsi
	movl	$1, %edx
	movq	%rax, %rdi
	jmp	.LBB2_24
.LBB2_27:
	movl	$2147483752, %edx               # imm = 0x80000068
	movq	%rbx, %rdi
	xorl	%esi, %esi
	callq	memset@PLT
	leaq	8(%rsp), %rax
	movq	%rax, 40(%rsp)
	movq	%r14, 48(%rsp)
	leaq	16(%rsp), %rdi
	leaq	40(%rsp), %rsi
	callq	_ZNSt6threadC2IZ4mainEUlvE_JEvEEOT_DpOT0_
.Ltmp0:
	movl	$4096, %edi                     # imm = 0x1000
	callq	_Znwm@PLT
.Ltmp1:
# %bb.28:
	movq	%rax, %rbx
	xorps	%xmm0, %xmm0
	movups	%xmm0, (%rax)
	movl	$48, %eax
.LBB2_29:                               # =>This Inner Loop Header: Depth=1
	movups	(%rbx), %xmm0
	movups	%xmm0, -32(%rbx,%rax)
	movups	(%rbx), %xmm0
	movups	%xmm0, -16(%rbx,%rax)
	movups	(%rbx), %xmm0
	movups	%xmm0, (%rbx,%rax)
	addq	$48, %rax
	cmpq	$4128, %rax                     # imm = 0x1020
	jne	.LBB2_29
# %bb.30:
	movb	$1, 16(%rbx)
	movabsq	$68719476752, %rax              # imm = 0x1000000010
	movq	%rax, 20(%rbx)
.Ltmp3:
	leaq	map_info(%rip), %rdi
	movl	$4096, %edx                     # imm = 0x1000
	movq	%rbx, %rsi
	xorl	%ecx, %ecx
	movl	$1, %r8d
	callq	cudaMemcpyToSymbol@PLT
.Ltmp4:
# %bb.31:
.Ltmp5:
	movabsq	$4294967297, %rdi               # imm = 0x100000001
	movl	$1, %esi
	movq	%rdi, %rdx
	movl	$1, %ecx
	xorl	%r8d, %r8d
	xorl	%r9d, %r9d
	callq	__cudaPushCallConfiguration@PLT
.Ltmp6:
# %bb.32:
	testl	%eax, %eax
	jne	.LBB2_34
# %bb.33:
	movq	8(%rsp), %rdi
.Ltmp7:
	movl	$2147483752, %esi               # imm = 0x80000068
	callq	__device_stub__bpf_main
.Ltmp8:
.LBB2_34:
.Ltmp9:
	callq	cudaDeviceSynchronize@PLT
.Ltmp10:
# %bb.35:
.Ltmp11:
	leaq	16(%rsp), %rdi
	callq	_ZNSt6thread4joinEv@PLT
.Ltmp12:
# %bb.36:
	movq	8(%rsp), %rdi
.Ltmp13:
	callq	cudaHostUnregister@PLT
.Ltmp14:
# %bb.37:
	movq	8(%rsp), %rdi
	callq	free@PLT
.Ltmp15:
	movq	_ZSt4cout@GOTPCREL(%rip), %rdi
	leaq	.L.str.9(%rip), %rsi
	movl	$10, %edx
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
.Ltmp16:
# %bb.38:
	movq	%rbx, %rdi
	callq	_ZdlPv@PLT
	cmpq	$0, 16(%rsp)
	jne	.LBB2_44
# %bb.39:
	xorl	%eax, %eax
	jmp	.LBB2_9
.LBB2_40:
.Ltmp2:
	movq	%rax, %r14
	jmp	.LBB2_41
.LBB2_43:
.Ltmp17:
	movq	%rax, %r14
	movq	%rbx, %rdi
	callq	_ZdlPv@PLT
.LBB2_41:
	cmpq	$0, 16(%rsp)
	jne	.LBB2_44
# %bb.42:
	movq	%r14, %rdi
	callq	_Unwind_Resume@PLT
.LBB2_44:
	callq	_ZSt9terminatev@PLT
.Lfunc_end2:
	.size	main, .Lfunc_end2-main
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table2:
.Lexception0:
	.byte	255                             # @LPStart Encoding = omit
	.byte	255                             # @TType Encoding = omit
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end0-.Lcst_begin0
.Lcst_begin0:
	.uleb128 .Lfunc_begin0-.Lfunc_begin0    # >> Call Site 1 <<
	.uleb128 .Ltmp0-.Lfunc_begin0           #   Call between .Lfunc_begin0 and .Ltmp0
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp0-.Lfunc_begin0           # >> Call Site 2 <<
	.uleb128 .Ltmp1-.Ltmp0                  #   Call between .Ltmp0 and .Ltmp1
	.uleb128 .Ltmp2-.Lfunc_begin0           #     jumps to .Ltmp2
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp3-.Lfunc_begin0           # >> Call Site 3 <<
	.uleb128 .Ltmp16-.Ltmp3                 #   Call between .Ltmp3 and .Ltmp16
	.uleb128 .Ltmp17-.Lfunc_begin0          #     jumps to .Ltmp17
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp16-.Lfunc_begin0          # >> Call Site 4 <<
	.uleb128 .Lfunc_end2-.Ltmp16            #   Call between .Ltmp16 and .Lfunc_end2
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end0:
	.p2align	2, 0x0
                                        # -- End function
	.text
	.p2align	4, 0x90                         # -- Begin function _ZNSt6threadC2IZ4mainEUlvE_JEvEEOT_DpOT0_
	.type	_ZNSt6threadC2IZ4mainEUlvE_JEvEEOT_DpOT0_,@function
_ZNSt6threadC2IZ4mainEUlvE_JEvEEOT_DpOT0_: # @_ZNSt6threadC2IZ4mainEUlvE_JEvEEOT_DpOT0_
.Lfunc_begin1:
	.cfi_startproc
	.cfi_personality 155, DW.ref.__gxx_personality_v0
	.cfi_lsda 27, .Lexception1
# %bb.0:
	pushq	%r14
	.cfi_def_cfa_offset 16
	pushq	%rbx
	.cfi_def_cfa_offset 24
	pushq	%rax
	.cfi_def_cfa_offset 32
	.cfi_offset %rbx, -24
	.cfi_offset %r14, -16
	movq	%rsi, %rbx
	movq	%rdi, %r14
	movq	$0, (%rdi)
	movl	$24, %edi
	callq	_Znwm@PLT
	leaq	_ZTVNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEEE+16(%rip), %rcx
	movq	%rcx, (%rax)
	movups	(%rbx), %xmm0
	movups	%xmm0, 8(%rax)
	movq	%rax, (%rsp)
.Ltmp18:
	movq	%rsp, %rsi
	movq	%r14, %rdi
	xorl	%edx, %edx
	callq	_ZNSt6thread15_M_start_threadESt10unique_ptrINS_6_StateESt14default_deleteIS1_EEPFvvE@PLT
.Ltmp19:
# %bb.1:
	movq	(%rsp), %rdi
	testq	%rdi, %rdi
	je	.LBB3_3
# %bb.2:
	movq	(%rdi), %rax
	callq	*8(%rax)
.LBB3_3:
	addq	$8, %rsp
	.cfi_def_cfa_offset 24
	popq	%rbx
	.cfi_def_cfa_offset 16
	popq	%r14
	.cfi_def_cfa_offset 8
	retq
.LBB3_4:
	.cfi_def_cfa_offset 32
.Ltmp20:
	movq	%rax, %rbx
	movq	(%rsp), %rdi
	testq	%rdi, %rdi
	je	.LBB3_6
# %bb.5:
	movq	(%rdi), %rax
	callq	*8(%rax)
.LBB3_6:
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.Lfunc_end3:
	.size	_ZNSt6threadC2IZ4mainEUlvE_JEvEEOT_DpOT0_, .Lfunc_end3-_ZNSt6threadC2IZ4mainEUlvE_JEvEEOT_DpOT0_
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table3:
.Lexception1:
	.byte	255                             # @LPStart Encoding = omit
	.byte	255                             # @TType Encoding = omit
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end1-.Lcst_begin1
.Lcst_begin1:
	.uleb128 .Lfunc_begin1-.Lfunc_begin1    # >> Call Site 1 <<
	.uleb128 .Ltmp18-.Lfunc_begin1          #   Call between .Lfunc_begin1 and .Ltmp18
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp18-.Lfunc_begin1          # >> Call Site 2 <<
	.uleb128 .Ltmp19-.Ltmp18                #   Call between .Ltmp18 and .Ltmp19
	.uleb128 .Ltmp20-.Lfunc_begin1          #     jumps to .Ltmp20
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp19-.Lfunc_begin1          # >> Call Site 3 <<
	.uleb128 .Lfunc_end3-.Ltmp19            #   Call between .Ltmp19 and .Lfunc_end3
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end1:
	.p2align	2, 0x0
                                        # -- End function
	.text
	.p2align	4, 0x90                         # -- Begin function _ZNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEED0Ev
	.type	_ZNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEED0Ev,@function
_ZNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEED0Ev: # @_ZNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEED0Ev
	.cfi_startproc
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset %rbx, -16
	movq	%rdi, %rbx
	callq	_ZNSt6thread6_StateD2Ev@PLT
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmp	_ZdlPv@PLT                      # TAILCALL
.Lfunc_end4:
	.size	_ZNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEED0Ev, .Lfunc_end4-_ZNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEED0Ev
	.cfi_endproc
                                        # -- End function
	.p2align	4, 0x90                         # -- Begin function _ZNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEE6_M_runEv
	.type	_ZNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEE6_M_runEv,@function
_ZNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEE6_M_runEv: # @_ZNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEE6_M_runEv
	.cfi_startproc
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%r13
	.cfi_def_cfa_offset 40
	pushq	%r12
	.cfi_def_cfa_offset 48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	subq	$24, %rsp
	.cfi_def_cfa_offset 80
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	movq	%rdi, %rbx
	movq	_ZSt4cout@GOTPCREL(%rip), %r14
	leaq	.L.str.10(%rip), %rsi
	movl	$31, %edx
	movq	%r14, %rdi
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	movzbl	_ZL11should_exit.0(%rip), %eax
	testb	$1, %al
	jne	.LBB5_18
# %bb.1:
	leaq	.L.str.14(%rip), %rbp
	leaq	8(%rsp), %r13
	jmp	.LBB5_2
	.p2align	4, 0x90
.LBB5_17:                               #   in Loop: Header=BB5_2 Depth=1
	movzbl	_ZL11should_exit.0(%rip), %eax
	testb	$1, %al
	jne	.LBB5_18
.LBB5_2:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB5_15 Depth 2
	movq	8(%rbx), %rax
	movq	(%rax), %rax
	cmpl	$1, (%rax)
	jne	.LBB5_14
# %bb.3:                                #   in Loop: Header=BB5_2 Depth=1
	movl	$0, (%rax)
	movl	$34, %edx
	movq	%r14, %rdi
	leaq	.L.str.11(%rip), %rsi
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	movq	8(%rbx), %rax
	movq	(%rax), %rax
	movl	12(%rax), %esi
	movq	%r14, %rdi
	callq	_ZNSolsEi@PLT
	movl	$14, %edx
	movq	%rax, %rdi
	leaq	.L.str.12(%rip), %rsi
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	movq	8(%rbx), %rax
	movq	(%rax), %rax
	cmpl	$1, 12(%rax)
	jne	.LBB5_9
# %bb.4:                                #   in Loop: Header=BB5_2 Depth=1
	movl	$16, %edx
	movq	%r14, %rdi
	leaq	.L.str.13(%rip), %rsi
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	movq	8(%rbx), %rax
	movq	(%rax), %r15
	addq	$24, %r15
	movq	%r15, %rdi
	callq	strlen@PLT
	movq	%r14, %rdi
	movq	%r15, %rsi
	movq	%rax, %rdx
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	movq	(%r14), %rax
	movq	-24(%rax), %rax
	movq	240(%r14,%rax), %r15
	testq	%r15, %r15
	je	.LBB5_19
# %bb.5:                                #   in Loop: Header=BB5_2 Depth=1
	cmpb	$0, 56(%r15)
	je	.LBB5_7
# %bb.6:                                #   in Loop: Header=BB5_2 Depth=1
	movzbl	67(%r15), %eax
	jmp	.LBB5_8
.LBB5_7:                                #   in Loop: Header=BB5_2 Depth=1
	movq	%r15, %rdi
	callq	_ZNKSt5ctypeIcE13_M_widen_initEv@PLT
	movq	(%r15), %rax
	movq	%r15, %rdi
	movl	$10, %esi
	callq	*48(%rax)
.LBB5_8:                                #   in Loop: Header=BB5_2 Depth=1
	movsbl	%al, %esi
	movq	%r14, %rdi
	callq	_ZNSo3putEc@PLT
	movq	%rax, %rdi
	callq	_ZNSo5flushEv@PLT
	movq	8(%rbx), %rax
	movq	16(%rbx), %rcx
	movq	(%rcx), %rcx
	movq	(%rax), %rax
	movl	$2147483680, %edx               # imm = 0x80000020
	movq	%rcx, (%rax,%rdx)
	movq	8(%rbx), %rax
	movq	(%rax), %rax
.LBB5_9:                                #   in Loop: Header=BB5_2 Depth=1
	movl	$1, 4(%rax)
	mfence
	movl	$23, %edx
	movq	%r14, %rdi
	movq	%rbp, %rsi
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	movq	8(%rbx), %rax
	movq	(%rax), %rax
	movl	$2147483696, %ecx               # imm = 0x80000030
	movq	(%rax,%rcx), %rsi
	movq	%r14, %rdi
	callq	_ZNSo9_M_insertImEERSoT_@PLT
	movq	%rax, %r15
	movq	(%rax), %rax
	movq	-24(%rax), %rax
	movq	240(%r15,%rax), %r12
	testq	%r12, %r12
	je	.LBB5_19
# %bb.10:                               #   in Loop: Header=BB5_2 Depth=1
	cmpb	$0, 56(%r12)
	je	.LBB5_12
# %bb.11:                               #   in Loop: Header=BB5_2 Depth=1
	movzbl	67(%r12), %eax
	jmp	.LBB5_13
.LBB5_12:                               #   in Loop: Header=BB5_2 Depth=1
	movq	%r12, %rdi
	callq	_ZNKSt5ctypeIcE13_M_widen_initEv@PLT
	movq	(%r12), %rax
	movq	%r12, %rdi
	movl	$10, %esi
	callq	*48(%rax)
.LBB5_13:                               #   in Loop: Header=BB5_2 Depth=1
	movsbl	%al, %esi
	movq	%r15, %rdi
	callq	_ZNSo3putEc@PLT
	movq	%rax, %rdi
	callq	_ZNSo5flushEv@PLT
.LBB5_14:                               #   in Loop: Header=BB5_2 Depth=1
	movq	$0, 8(%rsp)
	movq	$10000000, 16(%rsp)             # imm = 0x989680
	.p2align	4, 0x90
.LBB5_15:                               #   Parent Loop BB5_2 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%r13, %rdi
	movq	%r13, %rsi
	callq	nanosleep@PLT
	cmpl	$-1, %eax
	jne	.LBB5_17
# %bb.16:                               #   in Loop: Header=BB5_15 Depth=2
	callq	__errno_location@PLT
	cmpl	$4, (%rax)
	je	.LBB5_15
	jmp	.LBB5_17
.LBB5_18:
	movq	_ZSt4cout@GOTPCREL(%rip), %rdi
	leaq	.L.str.15(%rip), %rsi
	movl	$20, %edx
	callq	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	addq	$24, %rsp
	.cfi_def_cfa_offset 56
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%r12
	.cfi_def_cfa_offset 40
	popq	%r13
	.cfi_def_cfa_offset 32
	popq	%r14
	.cfi_def_cfa_offset 24
	popq	%r15
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	retq
.LBB5_19:
	.cfi_def_cfa_offset 80
	callq	_ZSt16__throw_bad_castv@PLT
.Lfunc_end5:
	.size	_ZNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEE6_M_runEv, .Lfunc_end5-_ZNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEE6_M_runEv
	.cfi_endproc
                                        # -- End function
	.section	.text.startup,"ax",@progbits
	.p2align	4, 0x90                         # -- Begin function _GLOBAL__sub_I_test.cu
	.type	_GLOBAL__sub_I_test.cu,@function
_GLOBAL__sub_I_test.cu:                 # @_GLOBAL__sub_I_test.cu
	.cfi_startproc
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset %rbx, -16
	leaq	_ZStL8__ioinit(%rip), %rbx
	movq	%rbx, %rdi
	callq	_ZNSt8ios_base4InitC1Ev@PLT
	movq	_ZNSt8ios_base4InitD1Ev@GOTPCREL(%rip), %rdi
	leaq	__dso_handle(%rip), %rdx
	movq	%rbx, %rsi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmp	__cxa_atexit@PLT                # TAILCALL
.Lfunc_end6:
	.size	_GLOBAL__sub_I_test.cu, .Lfunc_end6-_GLOBAL__sub_I_test.cu
	.cfi_endproc
                                        # -- End function
	.type	_ZStL8__ioinit,@object          # @_ZStL8__ioinit
	.local	_ZStL8__ioinit
	.comm	_ZStL8__ioinit,1,1
	.hidden	__dso_handle
	.type	constData,@object               # @constData
	.local	constData
	.comm	constData,8,8
	.type	map_info,@object                # @map_info
	.local	map_info
	.comm	map_info,4096,16
	.type	_ZL11should_exit.0,@object      # @_ZL11should_exit.0
	.local	_ZL11should_exit.0
	.comm	_ZL11should_exit.0,1,1
	.type	.L.str,@object                  # @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"Failed to allocate hostMem\n"
	.size	.L.str, 28

	.type	.L.str.1,@object                # @.str.1
.L.str.1:
	.asciz	"cudaHostRegister error: "
	.size	.L.str.1, 25

	.type	.L.str.2,@object                # @.str.2
.L.str.2:
	.asciz	"\n"
	.size	.L.str.2, 2

	.type	.L.str.3,@object                # @.str.3
.L.str.3:
	.asciz	"cudaHostGetDevicePointer error: "
	.size	.L.str.3, 33

	.type	.L.str.4,@object                # @.str.4
.L.str.4:
	.asciz	"dev ptr should be %lx, host ptr is %lx\n"
	.size	.L.str.4, 40

	.type	.L.str.5,@object                # @.str.5
.L.str.5:
	.asciz	"cudaMemcpyToSymbol error: "
	.size	.L.str.5, 27

	.type	.L.str.6,@object                # @.str.6
.L.str.6:
	.asciz	"cudaHostRegister(2) error: "
	.size	.L.str.6, 28

	.type	.L.str.7,@object                # @.str.7
.L.str.7:
	.asciz	" "
	.size	.L.str.7, 2

	.type	.L.str.8,@object                # @.str.8
.L.str.8:
	.asciz	"cudaHostGetDevicePointer(2) error: "
	.size	.L.str.8, 36

	.type	.L.str.9,@object                # @.str.9
.L.str.9:
	.asciz	"All done.\n"
	.size	.L.str.9, 11

	.type	_ZTVNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEEE,@object # @_ZTVNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEEE
	.section	.data.rel.ro,"aw",@progbits
	.p2align	3, 0x0
_ZTVNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEEE:
	.quad	0
	.quad	_ZTINSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEEE
	.quad	_ZNSt6thread6_StateD2Ev
	.quad	_ZNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEED0Ev
	.quad	_ZNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEE6_M_runEv
	.size	_ZTVNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEEE, 40

	.type	_ZTSNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEEE,@object # @_ZTSNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEEE
	.section	.rodata,"a",@progbits
_ZTSNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEEE:
	.asciz	"NSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEEE"
	.size	_ZTSNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEEE, 66

	.type	_ZTINSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEEE,@object # @_ZTINSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEEE
	.section	.data.rel.ro,"aw",@progbits
	.p2align	3, 0x0
_ZTINSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEEE:
	.quad	_ZTVN10__cxxabiv120__si_class_type_infoE+16
	.quad	_ZTSNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEEE
	.quad	_ZTINSt6thread6_StateE
	.size	_ZTINSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEEE, 24

	.type	.L.str.10,@object               # @.str.10
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str.10:
	.asciz	"[Host Thread] Start waiting...\n"
	.size	.L.str.10, 32

	.type	.L.str.11,@object               # @.str.11
.L.str.11:
	.asciz	"[Host Thread] Got request: req_id="
	.size	.L.str.11, 35

	.type	.L.str.12,@object               # @.str.12
.L.str.12:
	.asciz	", handling...\n"
	.size	.L.str.12, 15

	.type	.L.str.13,@object               # @.str.13
.L.str.13:
	.asciz	"call map_lookup="
	.size	.L.str.13, 17

	.type	.L.str.14,@object               # @.str.14
.L.str.14:
	.asciz	"handle done, timesum = "
	.size	.L.str.14, 24

	.type	.L.str.15,@object               # @.str.15
.L.str.15:
	.asciz	"[Host Thread] Done.\n"
	.size	.L.str.15, 21

	.section	.init_array,"aw",@init_array
	.p2align	3, 0x90
	.quad	_GLOBAL__sub_I_test.cu
	.hidden	DW.ref.__gxx_personality_v0
	.weak	DW.ref.__gxx_personality_v0
	.section	.data.DW.ref.__gxx_personality_v0,"aGw",@progbits,DW.ref.__gxx_personality_v0,comdat
	.p2align	3, 0x0
	.type	DW.ref.__gxx_personality_v0,@object
	.size	DW.ref.__gxx_personality_v0, 8
DW.ref.__gxx_personality_v0:
	.quad	__gxx_personality_v0
	.ident	"clang version 17.0.2 (https://github.com/llvm/llvm-project b2417f51dbbd7435eb3aaf203de24de6754da50e)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __device_stub__bpf_main
	.addrsig_sym _Z14signal_handleri
	.addrsig_sym __gxx_personality_v0
	.addrsig_sym _GLOBAL__sub_I_test.cu
	.addrsig_sym _Unwind_Resume
	.addrsig_sym _ZStL8__ioinit
	.addrsig_sym __dso_handle
	.addrsig_sym constData
	.addrsig_sym map_info
	.addrsig_sym _ZSt4cerr
	.addrsig_sym _ZSt4cout
	.addrsig_sym _ZTVN10__cxxabiv120__si_class_type_infoE
	.addrsig_sym _ZTSNSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEEE
	.addrsig_sym _ZTINSt6thread6_StateE
	.addrsig_sym _ZTINSt6thread11_State_implINS_8_InvokerISt5tupleIJZ4mainEUlvE_EEEEEE
