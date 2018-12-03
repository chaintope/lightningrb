# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module FundingCreated
        def self.load(payload)
          _, rest = payload.unpack('na*')
          temporary_channel_id, funding_txid, funding_output_index, signature = rest.unpack('H64H64na64')
          signature = LightningMessages.wire2der(signature)
          # FIXME: In Eclair, funding_txid in funding_created message means hash of funding transaction
          funding_txid = funding_txid.rhex
          new(temporary_channel_id, funding_txid, funding_output_index, signature)
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::FUNDING_CREATED
        end

        def to_payload
          payload = +''
          payload << [FundingCreated.to_type].pack('n')
          payload << self[:temporary_channel_id].htb

          # FIXME: In Eclair, funding_txid in funding_created message means hash of funding transaction
          payload << self[:funding_txid].rhex.htb
          payload << [self[:funding_output_index]].pack('n')
          payload << LightningMessages.der2wire(self[:signature].htb)
          payload
        end

        def validate!(temporary_channel_id)
          unless self[:temporary_channel_id] == temporary_channel_id
            raise Lightning::Exceptions::TemporaryChannelIdNotMatch.new(self[:temporary_channel_id])
          end
        end
      end
    end
  end
end
