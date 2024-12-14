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
	uint64_t	driver_head;
	uint64_t	driver_data;
	uint64_t	device_head;
	uint64_t	device_data;
}
