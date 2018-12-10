module LocalStorageModules
   module RedisHandler

      def self.included(base)  # `base` is `HostClass` in our case
         base.extend ClassMethods
      end
      
      #extend ActiveSupport::Concern
      require 'pstore'
      #require 'securerandom'

      STORAGES =
          {
              customer: 0,
              request: 1
          }
      VIDEO_EXPIRED_TIME = 6
      REQUEST_EXPIRED_TIME = 60
      HOST = ENV['REDIS_HOST']

      MAIN_STORAGE_OPTIONS = {
          host: HOST,
          db: STORAGES[:customer]
      }

      SERVICE_STORAGE_OPTIONS = {
          host: HOST,
          db: STORAGES[:request]
      }

      module ClassMethods
         #Saves information about watching videostream.
         #
         # @param customer_id [Integer] - customer identfier.
         # @param video_id    [Integer] - video identfier.
         #
         # @return [Boolean] - whether the operation completed successfully.
         #
         def save_session(customer_id, video_id)
            customer_store = Redis.new MAIN_STORAGE_OPTIONS
            return false unless customer_store.ping.eql?('PONG')
            current_key = "#{customer_id}-#{video_id}"
            customer_store.set current_key, video_id
            customer_store.expire current_key, VIDEO_EXPIRED_TIME
         end

         #Gets list of videostreams is being watched by given customer
         #
         # @param customer_id [Integer] - customer identfier
         #
         # @return [Array] - list of users on given videostream
         #
         def get_user_videos(customer_id)
            customer_store = Redis.new MAIN_STORAGE_OPTIONS
            return [] unless customer_store.ping.eql?('PONG')
            customer_store.keys("#{customer_id}-*").map do |key|
               key[/(?<=^#{customer_id}-).+/].to_i
            end
         end

         #Gets list of customers watching given videostream.
         #
         # @param video_id [Integer] - videostream identfier.
         #
         # @return [Array] - list of customers on given videostream.
         #
         def get_watching_users(video_id)
            watch_store = Redis.new MAIN_STORAGE_OPTIONS
            return [] unless watch_store.ping.eql?('PONG')
            all_keys = watch_store.keys
            return [] unless all_keys.present?
            watch_store.mapped_mget(*all_keys).select do |user_key, video_key|
               video_key.eql? video_id
            end.keys.map{|user_key| user_key[/.+(?=-#{video_id}$)/].to_i}
         end

         #Saves information about the fact of receiving the request.
         #
         # @param nil
         #
         # @return [Boolean] - whether the operation completed successfully.
         #
         def logging_request
            uniq_key = SecureRandom.uuid
            request_store = Redis.new SERVICE_STORAGE_OPTIONS
            return false unless request_store.ping.eql?('PONG')
            request_store.set uniq_key, 1
            request_store.expire uniq_key, REQUEST_EXPIRED_TIME
         end

         #Gets number of received requests for last minute.
         #
         # @param nil
         #
         # @return [Integer] - number of requests.
         #
         def get_requests_count_for_minute
            request_store = Redis.new SERVICE_STORAGE_OPTIONS
            return 0 unless request_store.ping.eql?('PONG')
            request_store.keys.count
         end

         #Clear storage from any data
         #
         # @param nil
         #
         # @return [Boolean] - whether the operation completed successfully.
         #
         def clear_storage
            storage = Redis.new MAIN_STORAGE_OPTIONS
            storage.flushall.eql? 'OK'
         end

      end

   end

end
