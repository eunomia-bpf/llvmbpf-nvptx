#include <cerrno>
#include <chrono>
#include <csignal>
#include <cstdio>
#include <sys/ptrace.h>
#include <iostream>
#include <ostream>
#include <stdexcept>
#include <thread>
#include <unistd.h>
#include <vector>
#include <cudadebugger.h>
#include <sys/wait.h>
#include <dlfcn.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>

#define CUDBG_SAFE_CALL(x, error_message)                                      \
	do {                                                                   \
		CUDBGResult result = x;                                        \
		if (result != CUDBGResult::CUDBG_SUCCESS) {                    \
			std::cerr << result << ": " << error_message           \
				  << std::endl;                                \
			throw std::runtime_error(error_message);               \
		}                                                              \
	} while (0)

#define NV_SAFE_CALL(x, error_message)                                         \
	do {                                                                   \
		cudaError_t result = x;                                        \
		if (result != cudaSuccess) {                                   \
			std::cerr << result << ": " << error_message           \
				  << std::endl;                                \
			throw std::runtime_error(error_message);               \
		}                                                              \
	} while (0)

/*
clang++-17 ./debugger-test.cu -Wall --cuda-gpu-arch=sm_60 -O2 -L
/usr/local/cuda/lib64/ -lcudart -lcuda -I/usr/local/cuda/extras/Debugger/include
*/

__global__ void test_kernel(int *x, int y, int z)
{
	*x = y + z;
	printf("x=%d, y=%d, z=%d\n", *x, y, z);
}

int main()
{
    shm_unlink("cuda_test");
	CUDBGAPI x;

    int shmfd = shm_open("cuda_test", O_CREAT | O_RDWR|O_EXCL,0600);
    ftruncate(shmfd, sizeof(uintptr_t)*10);
    std::cout<<"shmfd="<<shmfd<<std::endl;
    uintptr_t* mapped_array = (uintptr_t*)mmap(nullptr, sizeof(uintptr_t)*10, PROT_READ|PROT_WRITE, MAP_SHARED, shmfd, 0);
    for(int i=0;i<10;i++) mapped_array[i]=0;
    if(shmfd<0){
        std::cerr<<"failed to open shm "<<errno<<std::endl;
        return -1;
    }
	int chdpid = fork();
    if (chdpid == 0) {
		std::cout << "Child started, pid = " << getpid() << std::endl;
		std::cout << "child: CUDBG_IPC_FLAG_NAME = "
			  << CUDBG_IPC_FLAG_NAME << std::endl;
		cudbgApiInit(2);
        cudbgApiAttach();
		uint32_t *i_am_debugger =
			(uint32_t *)dlsym(RTLD_DEFAULT, "CUDBG_I_AM_DEBUGGER");
		std::cout << "child debugger flag addr=" << (uintptr_t)i_am_debugger
			  << std::endl;
		if (i_am_debugger)
			std::cout << "child flag value=" << *i_am_debugger
				  << std::endl;
                  mapped_array[0] = (uintptr_t)&CUDBG_RESUME_FOR_ATTACH_DETACH ;
                mapped_array[1] = (uintptr_t)i_am_debugger;
		ptrace(PTRACE_TRACEME);
		kill(getpid(), SIGSTOP);
        while(true){
            std::cout<<"child spinning.."<<std::endl;
            std::this_thread::sleep_for(std::chrono::seconds(1));
        }
		return 0;

	} else {
		// ptrace(PTRACE_ATTACH, chdpid);
		// waitpid(chdpid, nullptr, 0);
        std::this_thread::sleep_for(std::chrono::seconds(3));
        std::cout<<"i am debugger addr="<<mapped_array[1]<<" CUDBG_RESUME_FOR_ATTACH_DETACH addr="<<mapped_array[0]<<" value="<<(*(uint32_t*)mapped_array[0])<<std::endl;
	}
	{
		uint32_t major, minor, rev;
		CUDBG_SAFE_CALL(cudbgGetAPIVersion(&major, &minor, &rev),
				"Unable to get version");
		std::cout << major << " - " << minor << " - " << rev
			  << std::endl;
		CUDBG_SAFE_CALL(cudbgGetAPI(major, minor, rev, &x),
				"unable to get api");
	}

	//   std::cout<<"CUDBG_I_AM_DEBUGGER =
	//   "<<CUDBG_I_AM_DEBUGGER<<std::endl;
    CUDBG_SAFE_CALL(x->initializeAttachStub(), "initializeAttachStub");
	while (true) {
		auto result = x->initialize();
		std::cout << "Checking if initializes successfully.." << result
			  << std::endl;
		if (result != CUDBGResult::CUDBG_SUCCESS) {
			std::cout << "Waiting and retrying.." << std::endl;
			std::this_thread::sleep_for(std::chrono::seconds(1));

		} else {
			std::cout << "Initialized" << std::endl;
			break;
		}
	}
	int y = 10;
	int z = 20;
	std::vector<int> buf;
	buf.push_back(0);
	NV_SAFE_CALL(cudaHostRegister(buf.data(), sizeof(int), 0),
		     "Unable to register");

	test_kernel<<<1, 1>>>(buf.data(), y, z);
	cudaDeviceSynchronize();
	std::cout << "x=" << buf[0] << std::endl;
	return 0;
}
