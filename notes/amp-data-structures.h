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

// An array of notification bits
// each peer will have its own array
// pending events n:
//        unit64_t pending = self->notify->rx[n] ^ peer->notify->tx[n]
//    gives 64 bits of pending events
//    events must be acknowledged before action is taken
//    events are acknowledged via
//        self->notify->rx[n] ^= pending
//    if mask is present, each 1 bit will prevent low level notification for the
//    event.  Events can still be made pending but no IRQ will be fired.
//    On Rx, masked events can be:
//              not acknowledge and not acted upon (expected)
//              acknowledged and acted upon
//    Said, another way, a receiver may acknowledged a masked event or not but
//    any acknowledged event MUST then be acted upon.
//
// Some layouts will use the notification array in multiple levels
// A direct level will be triggered by a lower level IRQ
// An indirect level will be triggered by a different direct level bit
// One common layout is that n=0 will be triggered by the IRQ
// and n=1 to 63 will be triggered by a bit in level 0.
// The bit in level 0 depends on the value of N such that the MSBs of level 0
// are used for the indirect cascade with the MSB of level 0 corresponding to
// n = N -1.
// For example if N = 2
// 	There will be 63 direct events, 0 to 62 (in bits 0 to 62) of n=0
//      There will be 64 indirect events in n=1 triggered by bit 63 of n=0
// For example if N = 63
//      There will be 1 direct event, 0 (bit 0 (LSB) of n=0)
//      There will be 64 indirect events numbered 64 to 127 in n=1,
//          triggered by bit 1 of n=0
//      There will be 64 indirect events in n=63 triggered by bit 63 of n=0
struct amp_notification_t<u8 N, bool mask> {
	uint64_t		tx[N];		// array of rx bits
	uint64_t		rx[N];		// array of rx bits
	if mask {
		uint64_t 	rx_mask[N];	// array of mask bits
	}
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

/* Example Layout, (medium)
**
** Driver Segment 4k, driver r/w, device ro
**    512 bytes layout definition & queue heads
**    512 bytes rx notification (1 direct notification and 4032 indirect )
**    512 bytes rx mask
**    512 bytes tx notification
**    2K  bytes 32 64 byte messages
** Device Segment 4k, device r/w, device ro
**    (same)
**
** Notification layout: N=48, bits/device = 16
** word 0
**    0 message queue always
**    1 all virtqueues for all devices > 201
**    2 all virtqueues for device 188
**    3 to 15 same for devices 189 to 201
**    16 to 63, indirect cascade for n = 1 to 47
** word 1
**    bit 0 to 14, per virtqueue notification, device 0
**    bit 15       all other virtqueues for device 0
**    bit 16 to 30, per virtqueue notification, device 1
**    bit 31       all other virtqueues for device 1
**    bit 32 to 46, per virtqueue notification, device 2
**    bit 47       all other virtqueues for device 2
**    bit 48 to 62, per virtqueue notification, device 3
**    bit 63       all other virtqueues for device 3
** word 2 to 47
**    same for devices 4 to 187
**
**    status and config change is always done in band via messages
*/

/* Example Layout, (reasonable minimal)
**
** Shared Device / Driver Segment 576 bytes
**    16   byte shared header
**    [optional padding]
**    Device:
**    8   byte queue heard
**    8   bytes rx notification (64 direct notifications, no masking)
**    8   bytes tx notification
**    [optional padding]
**    Driver:
**    8   byte queue heard
**    8   bytes rx notification (64 direct notifications, no masking)
**    8   bytes tx notification
**    [optional padding]
**    Device:
**    256 bytes, 4 64 byte message
**    [optional padding]
**    Driver:
**    256 bytes, 4 64 byte message
**
** Notification layout:
**    64 direct notifications
**    0 message queue always
**    for device 0 to 2 (3 devices)
**       virtqueues 0 to 6 each have individual notification bits
**       virtqueues 7 and above share 1 notification bit
**    for devices 3 to 8 (6 devices)
**       all virtqueues share one notification bit (one bit per device)
**    for devices 9 and above
**       all virtqueues on all devices share one notification bit
**
**    status and config change is always done in band via messages
*/

/* Example Layout, (pathologically minimal)
**
** Shared Device / Driver Segment 160 bytes
**    8   byte shared header
**    Device:
**    8   byte queue heard
**    Driver:
**    8   byte queue heard
**    pad:
**    8   (pad to 64 byte boundary)
**    Device:
**    64 bytes, 1 64 byte message
**    Driver:
**    64 bytes, 1 64 byte message
**
** Notification layout:
**    all device and virtqueue notifications are done in band via messages
*/

/* The small layout definition is an in memory self description of the
** communication shared memory area and appears at byte 0 of this area
** This form of the structure does:
**     * allows 0 to 4038 bit of bi-directional notification, with optional mask
**     * defines one queue in each direction with element size of 64 bytes and
**       with the number of elements from 1 to
*/
struct amp_layout_def_small_t {
	uint16_t	magic;			// magic & ready indication
						// ready = MAGIC_LAYOUT_DEF_SMALL
						// not ready = 0 or MAGIC_Q_DEF_NOT_READY
	uint8_t		version;		// 0x01
	uint8_t		length;			// size of this structure

	// driver and device know who they are, no peer_id's are used

	/* number of notification words provided in each direction
	** 0 to 64
	** implies number of direct & indirect
	** layout is implied device, then driver
	** for each:
	**    u64 tx[N];
	**    u64 rx[N];
	**    optional u64 mask[N];
	*/
	#define AMP_LAYOUT_NOTIFICATION_FLAG_BITMASK 0xF000
	#define AMP_LAYOUT_NOTIFICATION_FLAG_MASK    0x8000 // include mask array in layout
	uint8_t	num_notifications;		// 0 to 64
	uint8_t num_vq_notify_per_device;	// 1, 2, 4, 8, 16

	/* count of number of queue elements for each direction
	** expected range 1 to 8096
	** for size == 16, max elements <= 480
	*/
	uint16_t	num_q_elements;

// if size == 8, stop here, offsets are implied by values above
// if size == 16, everything fits in 64K (always include, never include)
	uint16_t	off_dev_notifications;
	uint16_t	off_drv_notifications;
	uint16_t	off_dev_q_elements;
	uint16_t	off_drv_q_elements;
// if size == 32, everything fits in one segment < 4G (overkill?)
	uint32_t	off_dev_notifications;
	uint32_t	off_drv_notifications;
	uint32_t	off_dev_q_elements;
	uint32_t	off_drv_q_elements;
	uint32_t	size_dev_q_elements;
	uint32_t	size_drv_q_elements;
// if size == 40, big offsets with MAP IDs in MSB (overkill!?)
	uint64_t	off_dev_notifications;
	uint64_t	off_drv_notifications;
	uint64_t	off_dev_q_elements;
	uint64_t	off_drv_q_elements;
	uint32_t	size_dev_q_elements;
	uint32_t	size_drv_q_elements;
}
