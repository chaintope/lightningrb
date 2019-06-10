# Protocol Documentation
<a name="top"></a>

## Table of Contents

- [lightning/channel/events.proto](#lightning/channel/events.proto)
    - [ChannelClosed](#lightning.channel.events.ChannelClosed)
    - [ChannelCreated](#lightning.channel.events.ChannelCreated)
    - [ChannelIdAssigned](#lightning.channel.events.ChannelIdAssigned)
    - [ChannelRestored](#lightning.channel.events.ChannelRestored)
    - [ChannelSignatureReceived](#lightning.channel.events.ChannelSignatureReceived)
    - [ChannelStateChanged](#lightning.channel.events.ChannelStateChanged)
    - [LocalChannelDown](#lightning.channel.events.LocalChannelDown)
    - [LocalChannelUpdate](#lightning.channel.events.LocalChannelUpdate)
    - [ShortChannelIdAssigned](#lightning.channel.events.ShortChannelIdAssigned)
  
  
  
  

- [lightning/channel/short_channel_id.proto](#lightning/channel/short_channel_id.proto)
    - [ShortChannelId](#lightning.channel.generated.ShortChannelId)
  
  
  
  

- [lightning/grpc/service.proto](#lightning/grpc/service.proto)
    - [Channel](#lightning.grpc.Channel)
    - [ConnectRequest](#lightning.grpc.ConnectRequest)
    - [ConnectResponse](#lightning.grpc.ConnectResponse)
    - [EventsRequest](#lightning.grpc.EventsRequest)
    - [EventsResponse](#lightning.grpc.EventsResponse)
    - [GetChannelRequest](#lightning.grpc.GetChannelRequest)
    - [GetChannelResponse](#lightning.grpc.GetChannelResponse)
    - [InvoiceRequest](#lightning.grpc.InvoiceRequest)
    - [InvoiceResponse](#lightning.grpc.InvoiceResponse)
    - [ListChannelsRequest](#lightning.grpc.ListChannelsRequest)
    - [ListChannelsResponse](#lightning.grpc.ListChannelsResponse)
    - [OpenRequest](#lightning.grpc.OpenRequest)
    - [OpenResponse](#lightning.grpc.OpenResponse)
    - [PaymentRequest](#lightning.grpc.PaymentRequest)
    - [PaymentResponse](#lightning.grpc.PaymentResponse)
    - [RouteRequest](#lightning.grpc.RouteRequest)
    - [RouteResponse](#lightning.grpc.RouteResponse)
  
    - [Operation](#lightning.grpc.Operation)
  
  
    - [LightningService](#lightning.grpc.LightningService)
  

- [lightning/io/events.proto](#lightning/io/events.proto)
    - [PeerAlreadyConnected](#lightning.io.events.PeerAlreadyConnected)
    - [PeerConnected](#lightning.io.events.PeerConnected)
    - [PeerDisconnected](#lightning.io.events.PeerDisconnected)
  
  
  
  

- [lightning/payment/events.proto](#lightning/payment/events.proto)
    - [PaymentFailed](#lightning.payment.events.PaymentFailed)
    - [PaymentReceived](#lightning.payment.events.PaymentReceived)
    - [PaymentRelayed](#lightning.payment.events.PaymentRelayed)
    - [PaymentSent](#lightning.payment.events.PaymentSent)
    - [PaymentSucceeded](#lightning.payment.events.PaymentSucceeded)
  
  
  
  

- [lightning/router/events.proto](#lightning/router/events.proto)
    - [ChannelRegistered](#lightning.router.events.ChannelRegistered)
    - [ChannelUpdated](#lightning.router.events.ChannelUpdated)
  
  
  
  

- [lightning/router/messages.proto](#lightning/router/messages.proto)
    - [RouteDiscovered](#lightning.router.messages.RouteDiscovered)
    - [RouteNotFound](#lightning.router.messages.RouteNotFound)
    - [RoutingInfo](#lightning.router.messages.RoutingInfo)
  
  
  
  

- [lightning/wire/signature.proto](#lightning/wire/signature.proto)
    - [Signature](#lightning.wire.Signature)
  
  
  
  

- [lightning/wire/types.proto](#lightning/wire/types.proto)
  
  
    - [File-level Extensions](#lightning/wire/types.proto-extensions)
    - [File-level Extensions](#lightning/wire/types.proto-extensions)
    - [File-level Extensions](#lightning/wire/types.proto-extensions)
    - [File-level Extensions](#lightning/wire/types.proto-extensions)
  
  

- [lightning/wire/lightning_messages/accept_channel.proto](#lightning/wire/lightning_messages/accept_channel.proto)
    - [AcceptChannel](#lightning.wire.lightningMessages.generated.AcceptChannel)
  
  
  
  

- [lightning/wire/lightning_messages/announcement_signatures.proto](#lightning/wire/lightning_messages/announcement_signatures.proto)
    - [AnnouncementSignatures](#lightning.wire.lightningMessages.generated.AnnouncementSignatures)
  
  
  
  

- [lightning/wire/lightning_messages/channel_announcement.proto](#lightning/wire/lightning_messages/channel_announcement.proto)
    - [ChannelAnnouncement](#lightning.wire.lightningMessages.generated.ChannelAnnouncement)
    - [ChannelAnnouncementWitness](#lightning.wire.lightningMessages.generated.ChannelAnnouncementWitness)
  
  
  
  

- [lightning/wire/lightning_messages/channel_reestablish.proto](#lightning/wire/lightning_messages/channel_reestablish.proto)
    - [ChannelReestablish](#lightning.wire.lightningMessages.generated.ChannelReestablish)
  
  
  
  

- [lightning/wire/lightning_messages/channel_update.proto](#lightning/wire/lightning_messages/channel_update.proto)
    - [ChannelUpdate](#lightning.wire.lightningMessages.generated.ChannelUpdate)
    - [ChannelUpdateWitness](#lightning.wire.lightningMessages.generated.ChannelUpdateWitness)
  
  
  
  

- [lightning/wire/lightning_messages/closing_signed.proto](#lightning/wire/lightning_messages/closing_signed.proto)
    - [ClosingSigned](#lightning.wire.lightningMessages.generated.ClosingSigned)
  
  
  
  

- [lightning/wire/lightning_messages/commitment_signed.proto](#lightning/wire/lightning_messages/commitment_signed.proto)
    - [CommitmentSigned](#lightning.wire.lightningMessages.generated.CommitmentSigned)
  
  
  
  

- [lightning/wire/lightning_messages/error.proto](#lightning/wire/lightning_messages/error.proto)
    - [Error](#lightning.wire.lightningMessages.generated.Error)
  
  
  
  

- [lightning/wire/lightning_messages/funding_created.proto](#lightning/wire/lightning_messages/funding_created.proto)
    - [FundingCreated](#lightning.wire.lightningMessages.generated.FundingCreated)
  
  
  
  

- [lightning/wire/lightning_messages/funding_locked.proto](#lightning/wire/lightning_messages/funding_locked.proto)
    - [FundingLocked](#lightning.wire.lightningMessages.generated.FundingLocked)
  
  
  
  

- [lightning/wire/lightning_messages/funding_signed.proto](#lightning/wire/lightning_messages/funding_signed.proto)
    - [FundingSigned](#lightning.wire.lightningMessages.generated.FundingSigned)
  
  
  
  

- [lightning/wire/lightning_messages/gossip_timestamp_filter.proto](#lightning/wire/lightning_messages/gossip_timestamp_filter.proto)
    - [GossipTimestampFilter](#lightning.wire.lightningMessages.generated.GossipTimestampFilter)
  
  
  
  

- [lightning/wire/lightning_messages/init.proto](#lightning/wire/lightning_messages/init.proto)
    - [Init](#lightning.wire.lightningMessages.generated.Init)
  
  
  
  

- [lightning/wire/lightning_messages/lightning_message.proto](#lightning/wire/lightning_messages/lightning_message.proto)
    - [LightningMessage](#lightning.wire.lightningMessages.generated.LightningMessage)
  
  
  
  

- [lightning/wire/lightning_messages/node_announcement.proto](#lightning/wire/lightning_messages/node_announcement.proto)
    - [Address](#lightning.wire.lightningMessages.generated.Address)
    - [IP4](#lightning.wire.lightningMessages.generated.IP4)
    - [IP6](#lightning.wire.lightningMessages.generated.IP6)
    - [NodeAnnouncement](#lightning.wire.lightningMessages.generated.NodeAnnouncement)
    - [NodeAnnouncementWitness](#lightning.wire.lightningMessages.generated.NodeAnnouncementWitness)
    - [Tor2](#lightning.wire.lightningMessages.generated.Tor2)
    - [Tor3](#lightning.wire.lightningMessages.generated.Tor3)
  
  
  
  

- [lightning/wire/lightning_messages/open_channel.proto](#lightning/wire/lightning_messages/open_channel.proto)
    - [OpenChannel](#lightning.wire.lightningMessages.generated.OpenChannel)
  
  
  
  

- [lightning/wire/lightning_messages/ping.proto](#lightning/wire/lightning_messages/ping.proto)
    - [Ping](#lightning.wire.lightningMessages.generated.Ping)
  
  
  
  

- [lightning/wire/lightning_messages/pong.proto](#lightning/wire/lightning_messages/pong.proto)
    - [Pong](#lightning.wire.lightningMessages.generated.Pong)
  
  
  
  

- [lightning/wire/lightning_messages/query_channel_range.proto](#lightning/wire/lightning_messages/query_channel_range.proto)
    - [QueryChannelRange](#lightning.wire.lightningMessages.generated.QueryChannelRange)
  
  
  
  

- [lightning/wire/lightning_messages/query_short_channel_ids.proto](#lightning/wire/lightning_messages/query_short_channel_ids.proto)
    - [QueryShortChannelIds](#lightning.wire.lightningMessages.generated.QueryShortChannelIds)
  
  
  
  

- [lightning/wire/lightning_messages/reply_channel_range.proto](#lightning/wire/lightning_messages/reply_channel_range.proto)
    - [ReplyChannelRange](#lightning.wire.lightningMessages.generated.ReplyChannelRange)
  
  
  
  

- [lightning/wire/lightning_messages/reply_short_channel_ids_end.proto](#lightning/wire/lightning_messages/reply_short_channel_ids_end.proto)
    - [ReplyShortChannelIdsEnd](#lightning.wire.lightningMessages.generated.ReplyShortChannelIdsEnd)
  
  
  
  

- [lightning/wire/lightning_messages/revoke_and_ack.proto](#lightning/wire/lightning_messages/revoke_and_ack.proto)
    - [RevokeAndAck](#lightning.wire.lightningMessages.generated.RevokeAndAck)
  
  
  
  

- [lightning/wire/lightning_messages/shutdown.proto](#lightning/wire/lightning_messages/shutdown.proto)
    - [Shutdown](#lightning.wire.lightningMessages.generated.Shutdown)
  
  
  
  

- [lightning/wire/lightning_messages/update_add_htlc.proto](#lightning/wire/lightning_messages/update_add_htlc.proto)
    - [UpdateAddHtlc](#lightning.wire.lightningMessages.generated.UpdateAddHtlc)
  
  
  
  

- [lightning/wire/lightning_messages/update_fail_htlc.proto](#lightning/wire/lightning_messages/update_fail_htlc.proto)
    - [UpdateFailHtlc](#lightning.wire.lightningMessages.generated.UpdateFailHtlc)
  
  
  
  

- [lightning/wire/lightning_messages/update_fail_malformed_htlc.proto](#lightning/wire/lightning_messages/update_fail_malformed_htlc.proto)
    - [UpdateFailMalformedHtlc](#lightning.wire.lightningMessages.generated.UpdateFailMalformedHtlc)
  
  
  
  

- [lightning/wire/lightning_messages/update_fee.proto](#lightning/wire/lightning_messages/update_fee.proto)
    - [UpdateFee](#lightning.wire.lightningMessages.generated.UpdateFee)
  
  
  
  

- [lightning/wire/lightning_messages/update_fulfill_htlc.proto](#lightning/wire/lightning_messages/update_fulfill_htlc.proto)
    - [UpdateFulfillHtlc](#lightning.wire.lightningMessages.generated.UpdateFulfillHtlc)
  
  
  
  

- [Scalar Value Types](#scalar-value-types)



<a name="lightning/channel/events.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/channel/events.proto



<a name="lightning.channel.events.ChannelClosed"></a>

### ChannelClosed
Event fired when channel closed.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| channel_id | [string](#string) |  |  |






<a name="lightning.channel.events.ChannelCreated"></a>

### ChannelCreated
Event fired when channel created.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| remote_node_id | [string](#string) |  |  |
| is_funder | [uint32](#uint32) |  |  |
| temporary_channel_id | [string](#string) |  |  |






<a name="lightning.channel.events.ChannelIdAssigned"></a>

### ChannelIdAssigned
Event fired when channel_id is calculated and assigned to the channel.

A channel_id is based on funding transaction (txid and output_index), so
this event is fired after funding transaction is created
(but the funding transaction is not required to be broadcasted).


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| remote_node_id | [string](#string) |  |  |
| temporary_channel_id | [string](#string) |  |  |
| channel_id | [string](#string) |  |  |






<a name="lightning.channel.events.ChannelRestored"></a>

### ChannelRestored
Event fired after lightning node started and channel data restored from database.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| remote_node_id | [string](#string) |  |  |
| is_funder | [uint32](#uint32) |  |  |
| channel_id | [string](#string) |  |  |






<a name="lightning.channel.events.ChannelSignatureReceived"></a>

### ChannelSignatureReceived



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| channel_id | [string](#string) |  |  |






<a name="lightning.channel.events.ChannelStateChanged"></a>

### ChannelStateChanged



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| remote_node_id | [string](#string) |  |  |
| previous_state | [string](#string) |  |  |
| current_state | [string](#string) |  |  |






<a name="lightning.channel.events.LocalChannelDown"></a>

### LocalChannelDown



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| channel_id | [string](#string) |  |  |
| short_channel_id | [uint64](#uint64) |  |  |
| remote_node_id | [string](#string) |  |  |






<a name="lightning.channel.events.LocalChannelUpdate"></a>

### LocalChannelUpdate
Event fired when channel updated.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| channel_id | [string](#string) |  |  |
| short_channel_id | [uint64](#uint64) |  |  |
| remote_node_id | [string](#string) |  |  |






<a name="lightning.channel.events.ShortChannelIdAssigned"></a>

### ShortChannelIdAssigned
Event fired when short_channel_id is calculated and assigned to the channel.

A short_channel_id is calculated with txid, block_height and tx_index of the funding
transaction. So the funding transaction is need to be * broadcasted and confirmed.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| channel_id | [string](#string) |  |  |
| short_channel_id | [uint64](#uint64) |  |  |





 

 

 

 



<a name="lightning/channel/short_channel_id.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/channel/short_channel_id.proto



<a name="lightning.channel.generated.ShortChannelId"></a>

### ShortChannelId



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| block_height | [uint32](#uint32) |  |  |
| tx_index | [uint32](#uint32) |  |  |
| output_index | [uint32](#uint32) |  |  |





 

 

 

 



<a name="lightning/grpc/service.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/grpc/service.proto



<a name="lightning.grpc.Channel"></a>

### Channel



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| channel_id | [string](#string) |  |  |
| status | [string](#string) |  |  |
| to_local_msat | [uint64](#uint64) |  |  |
| to_remote_msat | [uint64](#uint64) |  |  |
| local_node_id | [string](#string) |  |  |
| remote_node_id | [string](#string) |  |  |






<a name="lightning.grpc.ConnectRequest"></a>

### ConnectRequest



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| remote_node_id | [string](#string) |  |  |
| host | [string](#string) |  |  |
| port | [uint32](#uint32) |  |  |






<a name="lightning.grpc.ConnectResponse"></a>

### ConnectResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| peer_connected | [lightning.io.events.PeerConnected](#lightning.io.events.PeerConnected) |  |  |
| peer_already_connected | [lightning.io.events.PeerAlreadyConnected](#lightning.io.events.PeerAlreadyConnected) |  |  |
| peer_disconnected | [lightning.io.events.PeerDisconnected](#lightning.io.events.PeerDisconnected) |  |  |






<a name="lightning.grpc.EventsRequest"></a>

### EventsRequest



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| operation | [Operation](#lightning.grpc.Operation) |  |  |
| event_type | [string](#string) |  |  |






<a name="lightning.grpc.EventsResponse"></a>

### EventsResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| channel_created | [lightning.channel.events.ChannelCreated](#lightning.channel.events.ChannelCreated) |  |  |
| channel_restored | [lightning.channel.events.ChannelRestored](#lightning.channel.events.ChannelRestored) |  |  |
| channel_id_assigned | [lightning.channel.events.ChannelIdAssigned](#lightning.channel.events.ChannelIdAssigned) |  |  |
| short_channel_id_assigned | [lightning.channel.events.ShortChannelIdAssigned](#lightning.channel.events.ShortChannelIdAssigned) |  |  |
| local_channel_update | [lightning.channel.events.LocalChannelUpdate](#lightning.channel.events.LocalChannelUpdate) |  |  |
| local_channel_down | [lightning.channel.events.LocalChannelDown](#lightning.channel.events.LocalChannelDown) |  |  |
| channel_state_changed | [lightning.channel.events.ChannelStateChanged](#lightning.channel.events.ChannelStateChanged) |  |  |
| channel_signature_received | [lightning.channel.events.ChannelSignatureReceived](#lightning.channel.events.ChannelSignatureReceived) |  |  |
| channel_closed | [lightning.channel.events.ChannelClosed](#lightning.channel.events.ChannelClosed) |  |  |
| payment_sent | [lightning.payment.events.PaymentSent](#lightning.payment.events.PaymentSent) |  |  |
| payment_relayed | [lightning.payment.events.PaymentRelayed](#lightning.payment.events.PaymentRelayed) |  |  |
| payment_received | [lightning.payment.events.PaymentReceived](#lightning.payment.events.PaymentReceived) |  |  |
| payment_succeeded | [lightning.payment.events.PaymentSucceeded](#lightning.payment.events.PaymentSucceeded) |  |  |






<a name="lightning.grpc.GetChannelRequest"></a>

### GetChannelRequest



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| channel_id | [string](#string) |  |  |






<a name="lightning.grpc.GetChannelResponse"></a>

### GetChannelResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| channel | [Channel](#lightning.grpc.Channel) |  |  |






<a name="lightning.grpc.InvoiceRequest"></a>

### InvoiceRequest



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| amount_msat | [uint64](#uint64) |  |  |
| description | [string](#string) |  |  |






<a name="lightning.grpc.InvoiceResponse"></a>

### InvoiceResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| prefix | [string](#string) |  |  |
| amount | [uint64](#uint64) |  |  |
| multiplier | [string](#string) |  |  |
| timestamp | [uint64](#uint64) |  |  |
| signature | [string](#string) |  |  |
| payment_hash | [string](#string) |  |  |
| description | [string](#string) |  |  |
| pubkey | [string](#string) |  |  |
| description_hash | [string](#string) |  |  |
| expiry | [uint32](#uint32) |  |  |
| min_final_cltv_expiry | [uint32](#uint32) |  |  |
| fallback_address | [string](#string) |  |  |
| routing_info | [lightning.router.messages.RoutingInfo](#lightning.router.messages.RoutingInfo) | repeated |  |
| payload | [string](#string) |  |  |






<a name="lightning.grpc.ListChannelsRequest"></a>

### ListChannelsRequest



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| node_id | [string](#string) |  |  |






<a name="lightning.grpc.ListChannelsResponse"></a>

### ListChannelsResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| channel | [Channel](#lightning.grpc.Channel) | repeated |  |






<a name="lightning.grpc.OpenRequest"></a>

### OpenRequest



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| remote_node_id | [string](#string) |  |  |
| funding_satoshis | [uint64](#uint64) |  |  |
| push_msat | [uint64](#uint64) |  |  |
| channel_flags | [uint32](#uint32) |  |  |






<a name="lightning.grpc.OpenResponse"></a>

### OpenResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| channel_created | [lightning.channel.events.ChannelCreated](#lightning.channel.events.ChannelCreated) |  |  |
| channel_restored | [lightning.channel.events.ChannelRestored](#lightning.channel.events.ChannelRestored) |  |  |
| channel_id_assigned | [lightning.channel.events.ChannelIdAssigned](#lightning.channel.events.ChannelIdAssigned) |  |  |
| short_channel_id_assigned | [lightning.channel.events.ShortChannelIdAssigned](#lightning.channel.events.ShortChannelIdAssigned) |  |  |
| local_channel_update | [lightning.channel.events.LocalChannelUpdate](#lightning.channel.events.LocalChannelUpdate) |  |  |
| channel_registered | [lightning.router.events.ChannelRegistered](#lightning.router.events.ChannelRegistered) |  |  |
| channel_updated | [lightning.router.events.ChannelUpdated](#lightning.router.events.ChannelUpdated) |  |  |






<a name="lightning.grpc.PaymentRequest"></a>

### PaymentRequest



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| node_id | [string](#string) |  |  |
| payment_hash | [string](#string) |  |  |
| amount_msat | [uint64](#uint64) |  |  |






<a name="lightning.grpc.PaymentResponse"></a>

### PaymentResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| payment_succeeded | [lightning.payment.events.PaymentSucceeded](#lightning.payment.events.PaymentSucceeded) |  |  |






<a name="lightning.grpc.RouteRequest"></a>

### RouteRequest



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| source_node_id | [string](#string) |  |  |
| target_node_id | [string](#string) |  |  |






<a name="lightning.grpc.RouteResponse"></a>

### RouteResponse



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| route_discovered | [lightning.router.messages.RouteDiscovered](#lightning.router.messages.RouteDiscovered) |  |  |
| route_not_found | [lightning.router.messages.RouteNotFound](#lightning.router.messages.RouteNotFound) |  |  |





 


<a name="lightning.grpc.Operation"></a>

### Operation


| Name | Number | Description |
| ---- | ------ | ----------- |
| SUBSCRIBE | 0 |  |
| UNSUBSCRIBE | 1 |  |


 

 


<a name="lightning.grpc.LightningService"></a>

### LightningService
Service for the lightning network.

| Method Name | Request Type | Response Type | Description |
| ----------- | ------------ | ------------- | ------------|
| Events | [EventsRequest](#lightning.grpc.EventsRequest) stream | [EventsResponse](#lightning.grpc.EventsResponse) stream |  |
| Connect | [ConnectRequest](#lightning.grpc.ConnectRequest) | [ConnectResponse](#lightning.grpc.ConnectResponse) stream | Connect to a remote peer. |
| Open | [OpenRequest](#lightning.grpc.OpenRequest) | [OpenResponse](#lightning.grpc.OpenResponse) stream | Open a channel. Call Connect api before calling this api. |
| Invoice | [InvoiceRequest](#lightning.grpc.InvoiceRequest) | [InvoiceResponse](#lightning.grpc.InvoiceResponse) | Make an invoice. This api is not required to connect remote peer. |
| Payment | [PaymentRequest](#lightning.grpc.PaymentRequest) | [PaymentResponse](#lightning.grpc.PaymentResponse) stream | Make a payment. Wait until receiving PaymentSucceeded event. |
| Route | [RouteRequest](#lightning.grpc.RouteRequest) | [RouteResponse](#lightning.grpc.RouteResponse) stream | Find routing to destination node. |
| GetChannel | [GetChannelRequest](#lightning.grpc.GetChannelRequest) | [GetChannelResponse](#lightning.grpc.GetChannelResponse) | Get the channel data with specified channel_id. |
| ListChannels | [ListChannelsRequest](#lightning.grpc.ListChannelsRequest) | [ListChannelsResponse](#lightning.grpc.ListChannelsResponse) | List channel data with specified remote_node_id. node_id is optional. if node_id is not specified, return all channels connected to this node. |

 



<a name="lightning/io/events.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/io/events.proto



<a name="lightning.io.events.PeerAlreadyConnected"></a>

### PeerAlreadyConnected
Event fired when local node tries to connect to the remote node,
but has been already connected to it.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| remote_node_id | [string](#string) |  |  |






<a name="lightning.io.events.PeerConnected"></a>

### PeerConnected
Event fired when local node connects to the remote node


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| remote_node_id | [string](#string) |  |  |






<a name="lightning.io.events.PeerDisconnected"></a>

### PeerDisconnected
Event fired when local node disconnects from the remote node


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| remote_node_id | [string](#string) |  |  |





 

 

 

 



<a name="lightning/payment/events.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/payment/events.proto



<a name="lightning.payment.events.PaymentFailed"></a>

### PaymentFailed
Event fired when a payment process is failed.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| payment_hash | [string](#string) |  |  |






<a name="lightning.payment.events.PaymentReceived"></a>

### PaymentReceived
Event fired when node receive a payment.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| channel_id | [string](#string) |  |  |
| amount_msat | [uint64](#uint64) |  |  |
| payment_hash | [string](#string) |  |  |






<a name="lightning.payment.events.PaymentRelayed"></a>

### PaymentRelayed
Event fired when node receive a payment to other node and relayed to next node.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| original_channel_id | [string](#string) |  |  |
| amount_msat_in | [uint64](#uint64) |  |  |
| amount_msat_out | [uint64](#uint64) |  |  |
| payment_hash | [string](#string) |  |  |






<a name="lightning.payment.events.PaymentSent"></a>

### PaymentSent
Event fired when local node send a payment to other node.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| channel_id | [string](#string) |  |  |
| amount_msat | [uint64](#uint64) |  |  |
| fees_paid | [uint64](#uint64) |  |  |
| payment_hash | [string](#string) |  |  |






<a name="lightning.payment.events.PaymentSucceeded"></a>

### PaymentSucceeded
Event fired when node receive a payment preimage.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| amount_msat | [uint64](#uint64) |  |  |
| payment_hash | [string](#string) |  |  |
| payment_preimage | [string](#string) |  |  |





 

 

 

 



<a name="lightning/router/events.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/router/events.proto



<a name="lightning.router.events.ChannelRegistered"></a>

### ChannelRegistered
Event fired when node receive ChannelUpdate messages which is not registered in the node.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| short_channel_id | [uint64](#uint64) |  |  |






<a name="lightning.router.events.ChannelUpdated"></a>

### ChannelUpdated
Event fired when node receive ChannelUpdate messages which is already registered in the node.


| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| short_channel_id | [uint64](#uint64) |  |  |





 

 

 

 



<a name="lightning/router/messages.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/router/messages.proto



<a name="lightning.router.messages.RouteDiscovered"></a>

### RouteDiscovered



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| routing_info | [RoutingInfo](#lightning.router.messages.RoutingInfo) | repeated |  |






<a name="lightning.router.messages.RouteNotFound"></a>

### RouteNotFound



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| source_node_id | [string](#string) |  |  |
| target_node_id | [string](#string) |  |  |






<a name="lightning.router.messages.RoutingInfo"></a>

### RoutingInfo



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| pubkey | [string](#string) |  |  |
| short_channel_id | [uint64](#uint64) |  |  |
| fee_base_msat | [uint64](#uint64) |  |  |
| fee_proportional_millionths | [uint64](#uint64) |  |  |
| cltv_expiry_delta | [uint32](#uint32) |  |  |





 

 

 

 



<a name="lightning/wire/signature.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/signature.proto



<a name="lightning.wire.Signature"></a>

### Signature



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| value | [string](#string) |  |  |





 

 

 

 



<a name="lightning/wire/types.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/types.proto


 

 


<a name="lightning/wire/types.proto-extensions"></a>

### File-level Extensions
| Extension | Type | Base | Number | Description |
| --------- | ---- | ---- | ------ | ----------- |
| bits | uint32 | .google.protobuf.FieldOptions | 60001 |  |
| hex | bool | .google.protobuf.FieldOptions | 60003 |  |
| length | uint32 | .google.protobuf.FieldOptions | 60002 |  |
| type | uint32 | .google.protobuf.MessageOptions | 50001 |  |

 

 



<a name="lightning/wire/lightning_messages/accept_channel.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/accept_channel.proto



<a name="lightning.wire.lightningMessages.generated.AcceptChannel"></a>

### AcceptChannel



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| temporary_channel_id | [string](#string) |  |  |
| dust_limit_satoshis | [uint64](#uint64) |  |  |
| max_htlc_value_in_flight_msat | [uint64](#uint64) |  |  |
| channel_reserve_satoshis | [uint64](#uint64) |  |  |
| htlc_minimum_msat | [uint64](#uint64) |  |  |
| minimum_depth | [uint32](#uint32) |  |  |
| to_self_delay | [uint32](#uint32) |  |  |
| max_accepted_htlcs | [uint32](#uint32) |  |  |
| funding_pubkey | [string](#string) |  |  |
| revocation_basepoint | [string](#string) |  |  |
| payment_basepoint | [string](#string) |  |  |
| delayed_payment_basepoint | [string](#string) |  |  |
| htlc_basepoint | [string](#string) |  |  |
| first_per_commitment_point | [string](#string) |  |  |
| shutdown_scriptpubkey | [string](#string) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/announcement_signatures.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/announcement_signatures.proto



<a name="lightning.wire.lightningMessages.generated.AnnouncementSignatures"></a>

### AnnouncementSignatures



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| channel_id | [string](#string) |  |  |
| short_channel_id | [uint64](#uint64) |  |  |
| node_signature | [lightning.wire.Signature](#lightning.wire.Signature) |  |  |
| bitcoin_signature | [lightning.wire.Signature](#lightning.wire.Signature) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/channel_announcement.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/channel_announcement.proto



<a name="lightning.wire.lightningMessages.generated.ChannelAnnouncement"></a>

### ChannelAnnouncement



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| node_signature_1 | [lightning.wire.Signature](#lightning.wire.Signature) |  |  |
| node_signature_2 | [lightning.wire.Signature](#lightning.wire.Signature) |  |  |
| bitcoin_signature_1 | [lightning.wire.Signature](#lightning.wire.Signature) |  |  |
| bitcoin_signature_2 | [lightning.wire.Signature](#lightning.wire.Signature) |  |  |
| features | [string](#string) |  |  |
| chain_hash | [string](#string) |  |  |
| short_channel_id | [uint64](#uint64) |  |  |
| node_id_1 | [string](#string) |  |  |
| node_id_2 | [string](#string) |  |  |
| bitcoin_key_1 | [string](#string) |  |  |
| bitcoin_key_2 | [string](#string) |  |  |






<a name="lightning.wire.lightningMessages.generated.ChannelAnnouncementWitness"></a>

### ChannelAnnouncementWitness



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| features | [string](#string) |  |  |
| chain_hash | [string](#string) |  |  |
| short_channel_id | [uint64](#uint64) |  |  |
| node_id_1 | [string](#string) |  |  |
| node_id_2 | [string](#string) |  |  |
| bitcoin_key_1 | [string](#string) |  |  |
| bitcoin_key_2 | [string](#string) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/channel_reestablish.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/channel_reestablish.proto



<a name="lightning.wire.lightningMessages.generated.ChannelReestablish"></a>

### ChannelReestablish



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| channel_id | [string](#string) |  |  |
| next_local_commitment_number | [uint64](#uint64) |  |  |
| next_remote_revocation_number | [uint64](#uint64) |  |  |
| your_last_per_commitment_secret | [string](#string) |  |  |
| my_current_per_commitment_point | [string](#string) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/channel_update.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/channel_update.proto



<a name="lightning.wire.lightningMessages.generated.ChannelUpdate"></a>

### ChannelUpdate



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| signature | [lightning.wire.Signature](#lightning.wire.Signature) |  |  |
| chain_hash | [string](#string) |  |  |
| short_channel_id | [uint64](#uint64) |  |  |
| timestamp | [uint32](#uint32) |  |  |
| message_flags | [string](#string) |  |  |
| channel_flags | [string](#string) |  |  |
| cltv_expiry_delta | [uint32](#uint32) |  |  |
| htlc_minimum_msat | [uint64](#uint64) |  |  |
| fee_base_msat | [uint32](#uint32) |  |  |
| fee_proportional_millionths | [uint32](#uint32) |  |  |
| htlc_maximum_msat | [uint64](#uint64) |  |  |






<a name="lightning.wire.lightningMessages.generated.ChannelUpdateWitness"></a>

### ChannelUpdateWitness



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| chain_hash | [string](#string) |  |  |
| short_channel_id | [uint64](#uint64) |  |  |
| timestamp | [uint32](#uint32) |  |  |
| message_flags | [string](#string) |  |  |
| channel_flags | [string](#string) |  |  |
| cltv_expiry_delta | [uint32](#uint32) |  |  |
| htlc_minimum_msat | [uint64](#uint64) |  |  |
| fee_base_msat | [uint32](#uint32) |  |  |
| fee_proportional_millionths | [uint32](#uint32) |  |  |
| htlc_maximum_msat | [uint64](#uint64) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/closing_signed.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/closing_signed.proto



<a name="lightning.wire.lightningMessages.generated.ClosingSigned"></a>

### ClosingSigned



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| channel_id | [string](#string) |  |  |
| fee_satoshis | [uint64](#uint64) |  |  |
| signature | [lightning.wire.Signature](#lightning.wire.Signature) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/commitment_signed.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/commitment_signed.proto



<a name="lightning.wire.lightningMessages.generated.CommitmentSigned"></a>

### CommitmentSigned



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| channel_id | [string](#string) |  |  |
| signature | [lightning.wire.Signature](#lightning.wire.Signature) |  |  |
| htlc_signature | [lightning.wire.Signature](#lightning.wire.Signature) | repeated |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/error.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/error.proto



<a name="lightning.wire.lightningMessages.generated.Error"></a>

### Error



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| channel_id | [string](#string) |  |  |
| data | [string](#string) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/funding_created.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/funding_created.proto



<a name="lightning.wire.lightningMessages.generated.FundingCreated"></a>

### FundingCreated



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| temporary_channel_id | [string](#string) |  |  |
| funding_txid | [string](#string) |  |  |
| funding_output_index | [uint32](#uint32) |  |  |
| signature | [lightning.wire.Signature](#lightning.wire.Signature) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/funding_locked.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/funding_locked.proto



<a name="lightning.wire.lightningMessages.generated.FundingLocked"></a>

### FundingLocked



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| channel_id | [string](#string) |  |  |
| next_per_commitment_point | [string](#string) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/funding_signed.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/funding_signed.proto



<a name="lightning.wire.lightningMessages.generated.FundingSigned"></a>

### FundingSigned



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| channel_id | [string](#string) |  |  |
| signature | [lightning.wire.Signature](#lightning.wire.Signature) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/gossip_timestamp_filter.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/gossip_timestamp_filter.proto



<a name="lightning.wire.lightningMessages.generated.GossipTimestampFilter"></a>

### GossipTimestampFilter



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| chain_hash | [string](#string) |  |  |
| first_timestamp | [uint32](#uint32) |  |  |
| timestamp_range | [uint32](#uint32) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/init.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/init.proto



<a name="lightning.wire.lightningMessages.generated.Init"></a>

### Init



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| globalfeatures | [string](#string) |  |  |
| localfeatures | [string](#string) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/lightning_message.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/lightning_message.proto



<a name="lightning.wire.lightningMessages.generated.LightningMessage"></a>

### LightningMessage



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| init | [Init](#lightning.wire.lightningMessages.generated.Init) |  |  |
| error | [Error](#lightning.wire.lightningMessages.generated.Error) |  |  |
| ping | [Ping](#lightning.wire.lightningMessages.generated.Ping) |  |  |
| pong | [Pong](#lightning.wire.lightningMessages.generated.Pong) |  |  |
| open_channel | [OpenChannel](#lightning.wire.lightningMessages.generated.OpenChannel) |  |  |
| accept_channel | [AcceptChannel](#lightning.wire.lightningMessages.generated.AcceptChannel) |  |  |
| funding_created | [FundingCreated](#lightning.wire.lightningMessages.generated.FundingCreated) |  |  |
| funding_signed | [FundingSigned](#lightning.wire.lightningMessages.generated.FundingSigned) |  |  |
| funding_locked | [FundingLocked](#lightning.wire.lightningMessages.generated.FundingLocked) |  |  |
| shutdown | [Shutdown](#lightning.wire.lightningMessages.generated.Shutdown) |  |  |
| closing_signed | [ClosingSigned](#lightning.wire.lightningMessages.generated.ClosingSigned) |  |  |
| update_add_htlc | [UpdateAddHtlc](#lightning.wire.lightningMessages.generated.UpdateAddHtlc) |  |  |
| update_fulfill_htlc | [UpdateFulfillHtlc](#lightning.wire.lightningMessages.generated.UpdateFulfillHtlc) |  |  |
| update_fail_htlc | [UpdateFailHtlc](#lightning.wire.lightningMessages.generated.UpdateFailHtlc) |  |  |
| update_fail_malformed_htlc | [UpdateFailMalformedHtlc](#lightning.wire.lightningMessages.generated.UpdateFailMalformedHtlc) |  |  |
| commitment_signed | [CommitmentSigned](#lightning.wire.lightningMessages.generated.CommitmentSigned) |  |  |
| revoke_and_ack | [RevokeAndAck](#lightning.wire.lightningMessages.generated.RevokeAndAck) |  |  |
| update_fee | [UpdateFee](#lightning.wire.lightningMessages.generated.UpdateFee) |  |  |
| channel_reestablish | [ChannelReestablish](#lightning.wire.lightningMessages.generated.ChannelReestablish) |  |  |
| announcement_signatures | [AnnouncementSignatures](#lightning.wire.lightningMessages.generated.AnnouncementSignatures) |  |  |
| channel_announcement | [ChannelAnnouncement](#lightning.wire.lightningMessages.generated.ChannelAnnouncement) |  |  |
| node_announcement | [NodeAnnouncement](#lightning.wire.lightningMessages.generated.NodeAnnouncement) |  |  |
| channel_update | [ChannelUpdate](#lightning.wire.lightningMessages.generated.ChannelUpdate) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/node_announcement.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/node_announcement.proto



<a name="lightning.wire.lightningMessages.generated.Address"></a>

### Address



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| ip4 | [IP4](#lightning.wire.lightningMessages.generated.IP4) |  |  |
| ip6 | [IP6](#lightning.wire.lightningMessages.generated.IP6) |  |  |
| tor2 | [Tor2](#lightning.wire.lightningMessages.generated.Tor2) |  |  |
| tor3 | [Tor3](#lightning.wire.lightningMessages.generated.Tor3) |  |  |






<a name="lightning.wire.lightningMessages.generated.IP4"></a>

### IP4



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| ipv4_addr | [string](#string) |  |  |
| port | [uint32](#uint32) |  |  |






<a name="lightning.wire.lightningMessages.generated.IP6"></a>

### IP6



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| ipv6_addr | [string](#string) |  |  |
| port | [uint32](#uint32) |  |  |






<a name="lightning.wire.lightningMessages.generated.NodeAnnouncement"></a>

### NodeAnnouncement



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| signature | [lightning.wire.Signature](#lightning.wire.Signature) |  |  |
| features | [string](#string) |  |  |
| timestamp | [uint32](#uint32) |  |  |
| node_id | [string](#string) |  |  |
| node_rgb_color | [uint32](#uint32) |  |  |
| node_alias | [string](#string) |  |  |
| addresses | [string](#string) |  |  |






<a name="lightning.wire.lightningMessages.generated.NodeAnnouncementWitness"></a>

### NodeAnnouncementWitness



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| features | [string](#string) |  |  |
| timestamp | [uint32](#uint32) |  |  |
| node_id | [string](#string) |  |  |
| node_rgb_color | [uint32](#uint32) |  |  |
| node_alias | [string](#string) |  |  |
| addresses | [string](#string) |  |  |






<a name="lightning.wire.lightningMessages.generated.Tor2"></a>

### Tor2



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| onion_addr | [string](#string) |  |  |
| port | [uint32](#uint32) |  |  |






<a name="lightning.wire.lightningMessages.generated.Tor3"></a>

### Tor3



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| onion_addr | [string](#string) |  |  |
| port | [uint32](#uint32) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/open_channel.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/open_channel.proto



<a name="lightning.wire.lightningMessages.generated.OpenChannel"></a>

### OpenChannel



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| chain_hash | [string](#string) |  |  |
| temporary_channel_id | [string](#string) |  |  |
| funding_satoshis | [uint64](#uint64) |  |  |
| push_msat | [uint64](#uint64) |  |  |
| dust_limit_satoshis | [uint64](#uint64) |  |  |
| max_htlc_value_in_flight_msat | [uint64](#uint64) |  |  |
| channel_reserve_satoshis | [uint64](#uint64) |  |  |
| htlc_minimum_msat | [uint64](#uint64) |  |  |
| feerate_per_kw | [uint32](#uint32) |  |  |
| to_self_delay | [uint32](#uint32) |  |  |
| max_accepted_htlcs | [uint32](#uint32) |  |  |
| funding_pubkey | [string](#string) |  |  |
| revocation_basepoint | [string](#string) |  |  |
| payment_basepoint | [string](#string) |  |  |
| delayed_payment_basepoint | [string](#string) |  |  |
| htlc_basepoint | [string](#string) |  |  |
| first_per_commitment_point | [string](#string) |  |  |
| channel_flags | [uint32](#uint32) |  |  |
| shutdown_scriptpubkey | [string](#string) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/ping.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/ping.proto



<a name="lightning.wire.lightningMessages.generated.Ping"></a>

### Ping



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| num_pong_bytes | [uint32](#uint32) |  |  |
| ignored | [string](#string) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/pong.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/pong.proto



<a name="lightning.wire.lightningMessages.generated.Pong"></a>

### Pong



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| ignored | [string](#string) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/query_channel_range.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/query_channel_range.proto



<a name="lightning.wire.lightningMessages.generated.QueryChannelRange"></a>

### QueryChannelRange



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| chain_hash | [string](#string) |  |  |
| first_blocknum | [uint32](#uint32) |  |  |
| number_of_blocks | [uint32](#uint32) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/query_short_channel_ids.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/query_short_channel_ids.proto



<a name="lightning.wire.lightningMessages.generated.QueryShortChannelIds"></a>

### QueryShortChannelIds



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| chain_hash | [string](#string) |  |  |
| encoded_short_ids | [string](#string) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/reply_channel_range.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/reply_channel_range.proto



<a name="lightning.wire.lightningMessages.generated.ReplyChannelRange"></a>

### ReplyChannelRange



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| chain_hash | [string](#string) |  |  |
| first_blocknum | [uint32](#uint32) |  |  |
| number_of_blocks | [uint32](#uint32) |  |  |
| complete | [uint32](#uint32) |  |  |
| encoded_short_ids | [string](#string) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/reply_short_channel_ids_end.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/reply_short_channel_ids_end.proto



<a name="lightning.wire.lightningMessages.generated.ReplyShortChannelIdsEnd"></a>

### ReplyShortChannelIdsEnd



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| chain_hash | [string](#string) |  |  |
| complete | [uint32](#uint32) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/revoke_and_ack.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/revoke_and_ack.proto



<a name="lightning.wire.lightningMessages.generated.RevokeAndAck"></a>

### RevokeAndAck



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| channel_id | [string](#string) |  |  |
| per_commitment_secret | [string](#string) |  |  |
| next_per_commitment_point | [string](#string) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/shutdown.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/shutdown.proto



<a name="lightning.wire.lightningMessages.generated.Shutdown"></a>

### Shutdown



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| channel_id | [string](#string) |  |  |
| scriptpubkey | [string](#string) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/update_add_htlc.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/update_add_htlc.proto



<a name="lightning.wire.lightningMessages.generated.UpdateAddHtlc"></a>

### UpdateAddHtlc



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| channel_id | [string](#string) |  |  |
| id | [uint64](#uint64) |  |  |
| amount_msat | [uint64](#uint64) |  |  |
| payment_hash | [string](#string) |  |  |
| cltv_expiry | [uint32](#uint32) |  |  |
| onion_routing_packet | [string](#string) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/update_fail_htlc.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/update_fail_htlc.proto



<a name="lightning.wire.lightningMessages.generated.UpdateFailHtlc"></a>

### UpdateFailHtlc



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| channel_id | [string](#string) |  |  |
| id | [uint64](#uint64) |  |  |
| reason | [string](#string) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/update_fail_malformed_htlc.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/update_fail_malformed_htlc.proto



<a name="lightning.wire.lightningMessages.generated.UpdateFailMalformedHtlc"></a>

### UpdateFailMalformedHtlc



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| channel_id | [string](#string) |  |  |
| id | [uint64](#uint64) |  |  |
| sha256_of_onion | [string](#string) |  |  |
| failure_code | [uint32](#uint32) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/update_fee.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/update_fee.proto



<a name="lightning.wire.lightningMessages.generated.UpdateFee"></a>

### UpdateFee



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| channel_id | [string](#string) |  |  |
| feerate_per_kw | [uint32](#uint32) |  |  |





 

 

 

 



<a name="lightning/wire/lightning_messages/update_fulfill_htlc.proto"></a>
<p align="right"><a href="#top">Top</a></p>

## lightning/wire/lightning_messages/update_fulfill_htlc.proto



<a name="lightning.wire.lightningMessages.generated.UpdateFulfillHtlc"></a>

### UpdateFulfillHtlc



| Field | Type | Label | Description |
| ----- | ---- | ----- | ----------- |
| type | [uint32](#uint32) |  |  |
| channel_id | [string](#string) |  |  |
| id | [uint64](#uint64) |  |  |
| payment_preimage | [string](#string) |  |  |





 

 

 

 



## Scalar Value Types

| .proto Type | Notes | C++ Type | Java Type | Python Type |
| ----------- | ----- | -------- | --------- | ----------- |
| <a name="double" /> double |  | double | double | float |
| <a name="float" /> float |  | float | float | float |
| <a name="int32" /> int32 | Uses variable-length encoding. Inefficient for encoding negative numbers – if your field is likely to have negative values, use sint32 instead. | int32 | int | int |
| <a name="int64" /> int64 | Uses variable-length encoding. Inefficient for encoding negative numbers – if your field is likely to have negative values, use sint64 instead. | int64 | long | int/long |
| <a name="uint32" /> uint32 | Uses variable-length encoding. | uint32 | int | int/long |
| <a name="uint64" /> uint64 | Uses variable-length encoding. | uint64 | long | int/long |
| <a name="sint32" /> sint32 | Uses variable-length encoding. Signed int value. These more efficiently encode negative numbers than regular int32s. | int32 | int | int |
| <a name="sint64" /> sint64 | Uses variable-length encoding. Signed int value. These more efficiently encode negative numbers than regular int64s. | int64 | long | int/long |
| <a name="fixed32" /> fixed32 | Always four bytes. More efficient than uint32 if values are often greater than 2^28. | uint32 | int | int |
| <a name="fixed64" /> fixed64 | Always eight bytes. More efficient than uint64 if values are often greater than 2^56. | uint64 | long | int/long |
| <a name="sfixed32" /> sfixed32 | Always four bytes. | int32 | int | int |
| <a name="sfixed64" /> sfixed64 | Always eight bytes. | int64 | long | int/long |
| <a name="bool" /> bool |  | bool | boolean | boolean |
| <a name="string" /> string | A string must always contain UTF-8 encoded or 7-bit ASCII text. | string | String | str/unicode |
| <a name="bytes" /> bytes | May contain any arbitrary sequence of bytes. | string | ByteString | str |

