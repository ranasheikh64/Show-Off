const activeCalls = new Map(); // userId -> { peerId, callType, status }

module.exports = (io, socket) => {
    const currentUserId = socket.user.id;

    // 1. Call User (Offer)
    socket.on('call_user', async (data, callback) => {
        try {
            const { receiverId, callType = 'video', offer, callerInfo } = data;
            if (!receiverId || !offer) {
                if (callback) callback({ success: false, message: 'Receiver ID and Offer SDP are required' });
                return;
            }

            // Check if receiver is already busy
            if (activeCalls.has(receiverId)) {
                if (callback) callback({ success: false, isBusy: true, message: 'User is busy on another call' });
                return;
            }

            activeCalls.set(currentUserId, { peerId: receiverId, callType, status: 'calling' });

            io.to(receiverId).emit('incoming_call', {
                callerId: currentUserId,
                callerName: callerInfo?.name || socket.user?.name || 'Someone',
                callerAvatar: callerInfo?.avatar || socket.user?.profileImage || null,
                callType,
                offer
            });

            if (callback) callback({ success: true });
        } catch (error) {
            console.error('call_user error:', error);
            if (callback) callback({ success: false, message: error.message });
        }
    });

    // 2. Answer Call
    socket.on('answer_call', (data, callback) => {
        try {
            const { callerId, answer } = data;
            if (!callerId || !answer) {
                if (callback) callback({ success: false, message: 'Caller ID and Answer SDP are required' });
                return;
            }

            activeCalls.set(currentUserId, { peerId: callerId, status: 'connected' });
            if (activeCalls.has(callerId)) {
                activeCalls.get(callerId).status = 'connected';
            }

            io.to(callerId).emit('call_accepted', {
                receiverId: currentUserId,
                answer
            });

            if (callback) callback({ success: true });
        } catch (error) {
            console.error('answer_call error:', error);
            if (callback) callback({ success: false, message: error.message });
        }
    });

    // 3. ICE Candidate Forwarding
    socket.on('ice_candidate', (data) => {
        const { targetId, candidate } = data;
        if (!targetId || !candidate) return;

        io.to(targetId).emit('receive_ice_candidate', {
            senderId: currentUserId,
            candidate
        });
    });

    // 4. Reject Call
    socket.on('reject_call', (data) => {
        const { callerId, reason } = data;
        activeCalls.delete(currentUserId);
        if (callerId) {
            activeCalls.delete(callerId);
            io.to(callerId).emit('call_rejected', {
                receiverId: currentUserId,
                reason: reason || 'Call declined'
            });
        }
    });

    // 5. End Call
    socket.on('end_call', (data) => {
        const { targetId } = data;
        activeCalls.delete(currentUserId);
        if (targetId) {
            activeCalls.delete(targetId);
            io.to(targetId).emit('call_ended', {
                senderId: currentUserId
            });
        }
    });

    // 6. Handle Disconnect
    socket.on('disconnect', () => {
        const active = activeCalls.get(currentUserId);
        if (active && active.peerId) {
            io.to(active.peerId).emit('call_ended', {
                senderId: currentUserId,
                reason: 'User disconnected'
            });
            activeCalls.delete(active.peerId);
        }
        activeCalls.delete(currentUserId);
    });
};
