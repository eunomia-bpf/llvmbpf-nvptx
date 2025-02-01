#include <atomic>
#include <chrono>
#include <csignal>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cuda_runtime.h>
#include <iostream>
#include <ostream>
#include <string>
#include <thread>
#include <vector>

/**
 * @brief Compile with clang-17 -S ./test.cu -Wall --cuda-gpu-arch=sm_60 -O2
 *
 */
enum class MapOperation { LOOKUP = 1, UPDATE = 2, DELETE = 3, NEXT_KEY = 4 };

union CallRequest {
	struct {
		char key[256];
	} map_lookup;
	struct {
		char key[256];
		char value[256];
		uint64_t flags;
	} map_update;
	struct {
		char key[256];
	} map_delete;
};

union CallResponse {
	struct {
		int result;
	} map_update, map_delete;
	struct {
		const void *value;
	} map_lookup;
};
/**
 * 我们在这块结构体里放两个标志位和一个简单的参数字段
 * - flag1: device -> host 的信号，“我有请求要处理”
 * - flag2: host   -> device 的信号，“我处理完了”
 * - paramA: 设备端写入的参数，让主机端使用
 */
struct SharedMem {
	int flag1;
	int flag2;
	int occupy_flag;
	int request_id;
	long map_id;
	CallRequest req;
	CallResponse resp;
};

struct MapBasicInfo {
	bool enabled;
	int key_size;
	int value_size;
	int max_entries;
};

__constant__ uintptr_t constData;
__constant__ MapBasicInfo map_info[256];
extern "C" __device__ void spin_lock(volatile int *lock)
{
	while (atomicCAS((int *)lock, 0, 1) == 1) {
		// 自旋等待锁变为可用
	}
	// printf("lock acquired by %d\n", threadIdx.x + blockIdx.x *
	// blockDim.x);
}

extern "C" __device__ void spin_unlock(int *lock)
{
	atomicExch(lock, 0); // 将锁标志重置为 0
	// printf("lock released by %d\n", threadIdx.x + blockIdx.x *
	// blockDim.x);
}
extern "C" __device__ CallResponse make_map_call(long map_id, int req_id,
						 CallRequest req)
{
	SharedMem *g_data = (SharedMem *)constData;
	// printf("make_map_call at %d, constdata=%lx\n",
	//        threadIdx.x + blockIdx.x * blockDim.x, (uintptr_t)g_data);
	spin_lock(&g_data->occupy_flag);
	// 准备要写入的参数值
	int val = 42; // 这里就写一个固定值，示例用
	g_data->req = req;
	g_data->request_id = req_id;
	g_data->map_id = map_id;
	// printf("making call for %d\n", req_id);
	// 在内联PTX里演示 store/load + acquire/release + 自旋
	asm volatile(
		".reg .pred p0;                   \n\t" // 声明谓词寄存器
		"membar.sys;                      \n\t" // 内存屏障
							// 设置 flag1 = 1 (替代
							// st.global.rel.u32)
		"st.global.u32 [%1], 1;           \n\t"
		// 自旋等待 flag2 == 1 (替代 ld.global.acq.u32)
		"spin_wait:                       \n\t"
		"membar.sys;                      \n\t"
		"ld.global.u32 %0, [%2];          \n\t" // 读取 flag2
		"setp.eq.u32 p0, %0, 0;           \n\t" // 比较值
		"@p0 bra spin_wait;               \n\t" // 谓词分支
							// 若跳出循环，复位
							// flag2 = 0
		"st.global.u32 [%2], 0;           \n\t"
		"membar.sys;                      \n\t"
		:
		: "r"(val), "l"(&g_data->flag1), "l"(&g_data->flag2)
		: "memory");
	CallResponse resp = g_data->resp;

	spin_unlock(&g_data->occupy_flag);
	return resp;
}

extern "C" __device__ void simple_memcpy(void *dst, void *src, int sz)
{
	for (int i = 0; i < sz; i++)
		((char *)dst)[i] = ((char *)src)[i];
}

extern "C" __noinline__ __device__ uint64_t _bpf_helper_ext_0001(
	uint64_t map, uint64_t key, uint64_t a, uint64_t b, uint64_t c)
{
	CallRequest req;
	const auto &map_info = ::map_info[map >> 32];
	printf("helper1 map %ld keysize=%d valuesize=%d\n", map,
	       map_info.key_size, map_info.value_size);
	simple_memcpy(&req.map_lookup.key, (void *)(uintptr_t)key,
		      map_info.key_size);

	CallResponse resp =
		make_map_call((long)map, (int)MapOperation::LOOKUP, req);

	return (uintptr_t)resp.map_lookup.value;
}

extern "C" __noinline__ __device__ uint64_t _bpf_helper_ext_0002(
	uint64_t map, uint64_t key, uint64_t value, uint64_t flags, uint64_t a)
{
	CallRequest req;
	const auto &map_info = ::map_info[map >> 32];
	// printf("helper2 map %ld keysize=%d
	// valuesize=%d\n",map,map_info.key_size,map_info.value_size);
	simple_memcpy(&req.map_update.key, (void *)(uintptr_t)key,
		      map_info.key_size);
	simple_memcpy(&req.map_update.value, (void *)(uintptr_t)value,
		      map_info.value_size);
	req.map_update.flags = (uintptr_t)flags;

	CallResponse resp =
		make_map_call((long)map, (int)MapOperation::UPDATE, req);
	return resp.map_update.result;
}

extern "C" __noinline__ __device__ uint64_t _bpf_helper_ext_0003(
	uint64_t map, uint64_t key, uint64_t a, uint64_t b, uint64_t c)
{
	CallRequest req;
	const auto &map_info = ::map_info[map >> 32];
	// printf("helper3 map %ld keysize=%d
	// valuesize=%d\n",map,map_info.key_size,map_info.value_size);
	simple_memcpy(&req.map_delete.key, (void *)(uintptr_t)key,
		      map_info.key_size);
	CallResponse resp =
		make_map_call((long)map, (int)MapOperation::DELETE, req);
	return resp.map_delete.result;
}

extern "C" __global__ void bpf_main(void *mem, size_t sz)
{
	// printf("kernel function entered, mem=%lx, memsz=%ld\n",
	// (uintptr_t)mem,
	//        sz);
	char buf[16] = "aaa";
	//   printf("setup function, const data=%lx\n", constData);
	auto result = _bpf_helper_ext_0001(1, (uintptr_t)buf, 0, 0, 0);
	_bpf_helper_ext_0002(1, (uintptr_t)buf, (uintptr_t)buf, 0, 0);
	_bpf_helper_ext_0003(1, (uintptr_t)buf, 0, 0, 0);
	printf("call done\n");
	printf("got response %d at %d\n", *(int *)result,
	       threadIdx.x + blockIdx.x * blockDim.x);
	*(int *)mem = 123;
}

static std::atomic<bool> should_exit;
void signal_handler(int)
{
	should_exit.store(true);
}
int main()
{
	signal(SIGINT, signal_handler);

	// 1. 先在主机上分配一块普通内存
	SharedMem *hostMem = (SharedMem *)malloc(sizeof(SharedMem));
	if (!hostMem) {
		std::cerr << "Failed to allocate hostMem\n";
		return -1;
	}

	// 2. 注册成 pinned memory (可被GPU直接访问)
	cudaError_t err = cudaHostRegister(hostMem, sizeof(SharedMem),
					   cudaHostRegisterMapped);
	if (err != cudaSuccess) {
		std::cerr
			<< "cudaHostRegister error: " << cudaGetErrorString(err)
			<< "\n";
		free(hostMem);
		return -1;
	}

	// 3. 获取对应的设备指针(这样DeviceKernel就能直接访问这个地址)
	SharedMem *devPtr = nullptr;
	err = cudaHostGetDevicePointer((void **)&devPtr, (void *)hostMem, 0);
	if (err != cudaSuccess) {
		std::cerr << "cudaHostGetDevicePointer error: "
			  << cudaGetErrorString(err) << "\n";
		cudaHostUnregister(hostMem);
		free(hostMem);
		return -1;
	}
	printf("dev ptr should be %lx, host ptr is %lx\n", (uintptr_t)devPtr,
	       (uintptr_t)hostMem);
	err = cudaMemcpyToSymbol(constData, &devPtr, sizeof(SharedMem *));
	if (err != cudaSuccess) {
		std::cerr << "cudaMemcpyToSymbol error: "
			  << cudaGetErrorString(err) << "\n";
		cudaHostUnregister(hostMem);
		free(hostMem);
		return -1;
	}
	int buf = 11223344;
	err = cudaHostRegister((void *)&buf, sizeof(buf),
			       cudaHostRegisterMapped);
	if (err != cudaSuccess) {
		std::cerr << "cudaHostRegister(2) error: "
			  << cudaGetErrorString(err) << " " << err << "\n";
		cudaHostUnregister(hostMem);
		free(hostMem);
		return -1;
	}
	char *devPtrStr = nullptr;
	err = cudaHostGetDevicePointer((void **)&devPtrStr, (void *)&buf, 0);
	if (err != cudaSuccess) {
		std::cerr << "cudaHostGetDevicePointer(2) error: "
			  << cudaGetErrorString(err) << "\n";
		cudaHostUnregister(hostMem);
		free(hostMem);
		return -1;
	}
	// 初始化标志位
	memset(hostMem, 0, sizeof(*hostMem));
	// 4. 启动一个线程, 模拟host侧的处理逻辑
	std::thread hostThread([&]() {
		std::cout << "[Host Thread] Start waiting...\n";

		// 这里简单用轮询，检测到flag1=1就处理
		while (!should_exit.load()) {
			if (hostMem->flag1 == 1) {
				// 清掉flag1防止重复处理
				hostMem->flag1 = 0;
				// 假设处理数据 paramA
				std::cout
					<< "[Host Thread] Got request: req_id="
					<< hostMem->request_id
					<< ", handling...\n";
				if (hostMem->request_id == 1) {
					std::cout << "call map_lookup="
						  << hostMem->req.map_lookup.key
						  << std::endl;
					// strcpy(hostMem->resp.map_lookup.value,
					//        "your value");
					hostMem->resp.map_lookup.value =
						devPtrStr;
				}
				// std::atomic_thread_fence(std::memory_order_seq_cst);

				// 处理完后, 把 flag2=1, 让设备端退出自旋
				hostMem->flag2 = 1;

				// 在实际开发中，可以加个内存栅栏，比如：
				std::atomic_thread_fence(
					std::memory_order_seq_cst);

				// 处理一次就退出本线程循环
				// break;
				std::cout << "handle done" << std::endl;
			}

			// 为了演示，这里短暂休眠，避免100%占用CPU
			std::this_thread::sleep_for(
				std::chrono::milliseconds(10));
		}

		std::cout << "[Host Thread] Done.\n";
	});
	std::vector<MapBasicInfo> local_map_info(256);

	local_map_info[1].enabled = true;
	local_map_info[1].key_size = 16;
	local_map_info[1].value_size = 16;
	cudaMemcpyToSymbol(map_info, local_map_info.data(),
			   sizeof(MapBasicInfo) * local_map_info.size());
	// 5. 启动核函数 (只发1个block,1个thread做演示)
	bpf_main<<<1, 1>>>(hostMem, sizeof(*hostMem));

	// 等待核函数执行完毕
	cudaDeviceSynchronize();

	// 等待host线程结束
	hostThread.join();

	// 6. 收尾：解绑 pinned memory 并释放
	cudaHostUnregister(hostMem);
	free(hostMem);

	std::cout << "All done.\n";
	return 0;
}
