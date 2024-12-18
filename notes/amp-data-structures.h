/* AMP shared memory structures */

/* Each side of a queue pair has its own queue_head
**
** status indicates when this peer is ready for communication to start.
** if status does not indicate ready, the other elements should be ignored.
** 
** head is an element index that points at the next element to be written by
** this peer in its own data area.  head will always point to a free element.
** 
** tail is an element index that points at the last element read by this peer
** from the other peers data area.
**
** head and tail wrap-around at element size, 
** each should always be < element_size
**
** my_q->head == other_q->tail means empty
** my_q->head == WRAP(other_q->tail - 1) means full
**
*/
struct amp_queue_head_t {
	uint16_t	status;		// magic & ready indication
	uint16_t	resv;		// reserved for now, maybe restart detect
	uint16_t	head;		// head index for my queue
	uint16_t	tail;		// tail index for other queue
}

/* AMP memory reference
** A memory reference is an unsigned 64 bit integer
** The upper most bits contain the memory area ID
** The lower bits contain the offset within the memory area
**
** There are 4096 possible memory area IDs,
**    although only one or two are used in most case
** ID 0 is always reserved for driver side PA addresses
** ID 1 is often the only memory area used and is normally the main memory area
**
** The maximum size of any memory area is 4096 TB
*/
#define AMP_MEMREF_AREA_MASK	0xFFF0000000000000ul
#define AMP_MEMREF_OFFSET_MASK	0x000FFFFFFFFFFFFFul
#define AMP_MEMREF_AREA_SHIFT	12
typedef uint64_t amp_memref_t;

/* Queue layout definition
** This structure can be used in the start of shared memory to define the 
** shared memory layout for a queue pair.
**
** This structure is static at run time from the device & driver POV
**
** Use of this structure is not required if both sides can get this information
** from other places such as devicetree or compile time constants.
*/
struct amp_queue_def_t {
	uint32_t	magic;			// magic & ready indication
						// ready = MAGIC_Q_DEF
						// not ready = 0 or MAGIC_Q_DEF_NOT_READY
	uint32_t	version;		// 0x0001_0000
	uint32_t	driver_peer_ord;	// should be 0 if not used
	uint32_t	device_peer_ord;	// should be 1 if not used

	/* size and count of queue elements from driver to device
	** element size should be a power of 2,
	**    some implementations may only support a given size such as 64
	** number of elements should be > 1 */
	uint16_t	driver_element_size;
	uint16_t	driver_num_elements;

	/* size and count of queue elements from device to driver
	** same constraints as driver to device */
	uint16_t	device_element_size;
	uint16_t	device_num_elements;

	/* offsets from the start of the containing memory area
	** each head is of type amp_queue_head_t
	** each data is u8 data[num_elements][element_size]
	*/
	amp_memref_t	driver_head;
	amp_memref_t	driver_data;
	amp_memref_t	device_head;
	amp_memref_t	device_data;
}

/*
I need to find the right terms and I have more data structures to add but here is the idea:

I expect one or more share memory areas. Example:
	one area somewhere in DDR and one in OCRAM

Each memory area will have a data structure that gives it an ID and defines sub-regions.
Each sub-region will define which peers have what r/w permissions and who has allocate ownership.

The 4k below is just an example, it could be 256 bytes or 1k or whatever fits the data.
Memory permissions can be the honor system or can be enforced by HW or hypervisors etc.
If enforced the side of the sub-areas will need to be adjusted to fit.

This sketch shows TWO virtio-msg buses:
	Linux driver and M4 device
	M4 driver and Linux device

DDR shared memory segment:
4K coordinator owned data, ro for peer 0  & 1
	memory area header 	// header for this memory area
	memory ID table		// table of all memory areas
	memory sub-area table	// sub-area list for this memory area
	peer ID table		// list of peers 
	device table		// list of virtio-msg buses and other devices
4k peer 0 (Linux) owned data, rw by peer 1, ro peer 0
	peer 0 info structures
	queue heads and queue data for Linux driver to M4 device
	queue heads and queue data for M4 driver to Linux device
4k peer 1 (M4) owned data, rw by peer 1, ro peer 0
	peer 1 info structures
	queue heads and queue data for M4 device to Linux driver
	queue heads and queue data for M4 driver to Linux device
2M-12K
	r/w by Linux and M4, allocation owner = M4
	M4 allocates virt-queues and buffers here for its drivers
8M
	r/w by Linux and M4, allocation owner = Linux
	Linux allocates virt-queues and buffers here for its drivers


Shared OCRAM:
	memory area header
	r/w by Linux and M4, allocation owner = Linux

*/
