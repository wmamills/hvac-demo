/* AMP shared memory structures */

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
**
** TODO: max AREA_SHIFT bus defined at run time?
*/
#define AMP_MEMREF_AREA_MASK	0xFFF0000000000000ul
#define AMP_MEMREF_OFFSET_MASK	0x000FFFFFFFFFFFFFul
#define AMP_MEMREF_AREA_SHIFT	12
typedef uint64_t amp_memref_t;

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
};

// status field layout
#define AMP_Q_STATUS_STATE_MASK 0x001F
#define AMP_Q_STATUS_FLAG_MASK  0xF000

#define AMP_Q_FLAG_DEBUGGABLE   0x8000	// this side may enter debug mode

// state field of queue status
#define AMP_Q_STATE_INIT        0       // just started up and not ready
#define AMP_Q_STATE_READY       1       // just started up and ready
#define AMP_Q_STATE_RUN         2       // normal run state
#define AMP_Q_STATE_SHUTDOWN    3       // shutting down, won't send new messages
#define AMP_Q_STATE_PEER_DEAD   4       // peer has been called dead


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
};

/* Example Layout, (medium, 4k for device, 4k for driver)
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
** Notification layout: N=1 bits/device=8
**    Summary:
**    64 direct notifications
**    7 devices with 7 vq specific notification and one catch-all for other vq
**    6 devices with 1 catch-all for all vq
**    1 catch-all for all vq's on all other devices
**    1 for the message queue
**
**    Layout:
**    0 message queue always
**    1 all virtqueues on all devices > 12
**    2 all virtqueues on device 7
**    3 all virtqueues on device 8
**    4 to 7 same for devices 9 to 12
**    8 to 15 device 0
**        8  virtqueue 0 on device 0
**        9  virtquque 1 on device 0
**        10 to 14 same for virtqueues 2 to 6 of device 0
**        15 all virtqueus > 6 on device 0
**    16 to 23 same pattern as above for device 1
**    24 to 31 same pattern as above for device 2
**    32 to 39 same pattern as above for device 3
**    40 to 39 same pattern as above for device 4
**    48 to 39 same pattern as above for device 5
**    56 to 63 same pattern as above for device 6
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

/* The simple layout definition is an in memory self description of the
** communication shared memory area and appears at byte 0 of this area
** This form of the structure does:
**     * allows 0 to 4038 bits of bi-directional notification, with optional mask
**     * defines one queue in each direction with specified element size and
**       number of elements
**     * 64 bit memrefs are used to specify either offsets from the start of
**       this structure or references to other memory areas
*/
struct amp_layout_def_simple_t {
	uint16_t	magic;			// magic & ready indication
						// ready = MAGIC_LAYOUT_DEF_SIMPLE
						// not ready = 0 or MAGIC_Q_DEF_NOT_READY
	uint16_t	version;		// 0x01
	uint16_t	length;			// 64

	// include mask array in layout
	#define AMP_LAYOUT_OPTION_NOTIFICATION_MASK    0x0001
	uint16_t	options;

	// driver and device know who they are, no peer_id's are used

	/* number of notification words provided in each direction
	** 0 to 64
	** implies number of direct & indirect
	** for each:
	**    u64 tx[N];
	**    u64 rx[N];
	**    optional u64 mask[N];
	*/
	uint8_t		num_notifications;		// 0 to 64
	uint8_t 	num_vq_notify_per_device;	// 1, 2, 4, 8, 16

	/* count of number of queue elements for each direction
	** and the size of each queue element
	*/
	uint16_t	num_q_elements;
	uint16_t	size_q_elements;

	uint16_t	pad1;			// reserved, should be zero

	/* if the AREA of each memref is 1, then it an unsigned offset from the 
	** start of this memory area and this data structure is assumed to be
	** as offset 0.  This is the normal expected usage
	** 
	** An AREA ID of 0 is a driver side PA address and can point anywhere 
	** but the device will need to understand it.
	** 
	** other AREA ID may be used by mutual agreement by the driver and device
	** side bus implementations.
	*/
	amp_memref_t	off_dev_notifications;
	amp_memref_t	off_drv_notifications;
	amp_memref_t	off_dev_q_head;
	amp_memref_t	off_drv_q_head;
	amp_memref_t	off_dev_q_elements;
	amp_memref_t	off_drv_q_elements;
};
