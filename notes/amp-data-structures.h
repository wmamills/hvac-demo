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
	uint16_t	magic;		// magic / valid indication
	uint16_t	status;		// status of self
	uint16_t	head;		// head index for my queue
	uint16_t	tail;		// tail index for other queue
}

// self status and peer status
#DEFINE AMP_Q_STATUS_INIT	0	// just started up and not ready
#DEFINE AMP_Q_STATUS_READY	1	// just started up and ready
#DEFINE AMP_Q_STATUS_RUN	2	// normal run state
#DEFINE AMP_Q_STATUS_SHUTDOWN	3	// shutting down, won't send new messages
#DEFINE AMP_Q_STATUS_PEER_DEAD	4	// peer has been called dead

// One normally starts in the INIT state but it is valid to start in the READY
// state so long as the peer state is NOT RUN
//
// Once one is ready to start communication, and the peer is in any state other
// than READY, the head and tail should be set to 0 and the state set to READY.
//
// Once self is set to the READY state and the peer is seen in the READY state,
// self will transition to the RUN state.  Once both sides are in the RUN state,
// communication starts
//
// A graceful shutdown is done via Bus level messages.  Once one side has issued
// its last message, it will set state to SHUTDOWN. Once both sides are in the
// SHUTDOWN state, graceful SHUTDOWN has been achieved.
//
// A "signaled abortive shutdown" can be signaled to the peer by setting self
// state to SHUTDOWN.  The peer can do its own clean up and wait for bus
// restart.  All devices should be assumed to be reset. No messages nor
// additional notifications are expected once a peer sets the state to SHUTDOWN.
// (Example: a crash handler can set the state to SHUTDOWN w/o doing anything
// else.)
//
// If in RUN,RUN state and then peer goes to INIT, it means the peer has
// silently restarted. Set the state to SHUTDOWN and do any cleanup locally.
// After the local cleanup is done, the state can be set to INIT or READY.
//
// If self determins that the peer is unresponsive, it will set its state to
// PEER_DEAD and do local cleanup.  The state should stay in PEER_DEAD until
// the peer's state is READY, at which time self state should be set to
// INIT or READY.
//
// If either peer is in SHUTDOWN or PEER_DEAD state, the bus may only be
// restarted by each side doing its own cleanup and then setting its state to
// INIT or (if peer state != RUN) READY

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
