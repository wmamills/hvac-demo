#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <sys/mman.h>

int main(int argc, char **argv)
{
	int fd = open(argv[1], O_RDWR);
	int n = -1;
	uint32_t buf;
	volatile uint32_t *mmr;
	volatile uint32_t *shm;

	if (fd < 0) {
		printf("Failed to open uio device %s\n", argv[1]);
		exit(1);
	}

	void* mmr_section = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0*getpagesize());
        void* shmem_section = mmap(NULL, 4194304, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 1*getpagesize());

	if (!mmr_section || !shmem_section) {
		printf("Section mmap() failed on uio device %s\n", argv[1]);
		exit(1);
	} else {
		printf("MMRs mapped at %p in VMA.\n", mmr_section);
		printf("shmem mapped at %p in VMA.\n", shmem_section);

		mmr = mmr_section;
		for (int i = 0; i < 4 /* There are 4 mmrs */; ++i) {
			printf("mmr%d: %d %0x\n", i, *(mmr+i), *(mmr+i));
		}

                shm = shmem_section;
		/*
		 * Save our peer ID taken from IVPOSITION register to shm[0] so
		 * the Zephyr peer knows which peer it should notify back.
		 */
		*(shm + 0) = *(mmr + 2);
	}

	/* Notify peer given in argv[2] by writting its peer ID to the DOORBELL register */
	*(mmr + 3) = atoi(argv[2]) << 16;

	/*
	 * Wait notification. read() will block until Zephyr finishes writting
	 * the whole shmem region with value 0xb5b5b5b5.
	 */
	n = read(fd, (uint8_t *)&buf, 4);

	/*
	printf("n = %d\n", n);
	printf("buf = %d\n", buf);
	*/

	/* Check shmem region: 4 MiB */
	int i;
	for (i = 1 /* skip peer id */; i < ((4 * 1024 * 1024) / 4) ; i++) {
		if (*(shm + i) != 0xb5b5b5b5) {
			printf("Data mismatch at %d: %x\n", i, *(shm +i));
			exit(1)	;
		}
	}

	printf("Data ok. %d byte(s) checked.\n", i * 4);
}
