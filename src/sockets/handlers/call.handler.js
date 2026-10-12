const activeCalls = new Map(); // userId -> { peerId, callType, status }

module.exports = (io, socket) => {
    const currentUserId = socket.user.id;

    // 1. Call User (Offer)
    socket.on('call_user', async (data, callback) => {
        try {
            const { receiverId, callType = 'video', offer, callerInfo } = data;
            console.log(`\n📞 [CALL_USER] Caller: ${currentUserId} (${callerInfo?.name}) -> Receiver: ${receiverId} [Type: ${callType}]`);

            if (!receiverId || !offer) {
                console.log(`❌ [CALL_USER] Missing receiverId or offer`);
                if (callback) callback({ success: false, message: 'Receiver ID and Offer SDP are required' });
                return;
            }

            // Check if receiver socket room exists
            const receiverRoom = io.sockets.adapter.rooms.get(receiverId);
            const clientCount = receiverRoom ? receiverRoom.size : 0;
            console.log(`📡 [CALL_USER] Active sockets in receiver's room (${receiverId}): ${clientCount}`);
            if (clientCount === 0) {
                console.log(`⚠️ [CALL_USER] Receiver ${receiverId} is NOT currently online/connected to Socket!`);
            }

            // Check if receiver is already busy
            if (activeCalls.has(receiverId)) {
                console.log(`⚠️ [CALL_USER] Receiver ${receiverId} is already busy on another call.`);
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
            console.log(`✅ [CALL_USER] 'incoming_call' event emitted to room: ${receiverId}`);

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
            console.log(`\n📞 [ANSWER_CALL] Receiver: ${currentUserId} -> Caller: ${callerId}`);
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
            console.log(`✅ [ANSWER_CALL] 'call_accepted' event emitted to caller: ${callerId}`);

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
        console.log(`❄️ [ICE_CANDIDATE] Forwarding candidate from ${currentUserId} to ${targetId}`);

        io.to(targetId).emit('receive_ice_candidate', {
            senderId: currentUserId,
            candidate
        });
    });

    // 4. Reject Call
    socket.on('reject_call', (data) => {
        const { callerId, reason } = data;
        console.log(`❌ [REJECT_CALL] Call rejected by ${currentUserId} for caller ${callerId}. Reason: ${reason}`);
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
        console.log(`🛑 [END_CALL] Call terminated by ${currentUserId} for peer ${targetId}`);
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
