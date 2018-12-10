module LocalStorageModules
   module PStoreHandler

      def self.included(base)  # `base` is `HostClass` in our case
         base.extend ClassMethods
      end

      #extend ActiveSupport::Concern
      require 'pstore'

      STORAGES =
          {
              customer: 'customer_watch.pstore',
              request: 'request_count.pstore'
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
            customer_store = PStore.new(STORAGES[:customer],true)
            customer_store.transaction do
               customer_store[customer_id] ||= {}
               customer_store[customer_id][video_id] = Time.now+6
            end

            true
         end

         #Gets list of videostreams is being watched by given customer
         #
         # @param customer_id [Integer] - customer identfier
         #
         # @return [Array] - list of users on given videostream
         #
         def get_user_videos(customer_id)
            actual_videos = []
            watch_store = PStore.new(STORAGES[:customer],false)
            watch_store.transaction(true) do
               user_videos = watch_store[customer_id]
               watch_store.abort unless user_videos.present?
               actual_videos = user_videos.select do |video_id, due_time|
                  Time.now < due_time
               end.keys
            end
            actual_videos.map(&:to_i)
         end

         #Gets list of customers watching given videostream.
         #
         # @param video_id [Integer] - videostream identfier.
         #
         # @return [Array] - list of customers on given videostream.
         #
         def get_watching_users(video_id)
            watching_users = []
            watch_store = PStore.new(STORAGES[:customer],false)
            watch_store.transaction(true) do
               current_time = Time.now
               watching_users = watch_store.roots.select do |user_id|
                  due_time = watch_store[user_id][video_id]
                  if due_time.present?
                     current_time < due_time
                  else
                     false
                  end
               end

            end
            watching_users.map(&:to_i)
         end

         #Saves information about the fact of receiving the request.
         #
         # @param nil
         #
         # @return [Boolean] - whether the operation completed successfully.
         #
         def logging_request
            scoped_time = get_scoped_time
            current_minute = scoped_time[:current_minute]
            current_second = scoped_time[:current_second]
            previous_minute = scoped_time[:previous_minute]

            request_store = PStore.new(STORAGES[:request],true)
            request_store.transaction do
               request_store[current_minute] ||= Array.new(60,0)
               request_store[current_minute][current_second] += 1
               waste_roots =
                   request_store.roots - [current_minute, previous_minute]
               waste_roots.each do |root|
                  request_store.delete root
               end
            end

         end

         #Gets number of received requests for last minute.
         #
         # @param nil
         #
         # @return [Integer] - number of requests.
         #
         def get_requests_count_for_minute
            scoped_time = get_scoped_time
            current_minute = scoped_time[:current_minute]
            current_second = scoped_time[:current_second]
            previous_minute = scoped_time[:previous_minute]
            requests_count = 0

            request_store = PStore.new(STORAGES[:request],false)
            request_store.transaction(true) do
               current = request_store[current_minute] || Array.new(60,0)
               previous = request_store[previous_minute] || Array.new(60,0)
               requests_count = (previous[current_second,59]+current).sum
            end

            requests_count
         end

         #Clear storage from any data
         #
         # @param nil
         #
         # @return [Boolean] - whether the operation completed successfully.
         #
         def clear_storage
            STORAGES.values.each do |storage_file|
               storage = PStore.new(storage_file,true)
               storage.transaction do
                  storage.roots.each do |key|
                     storage.delete key
                  end
               end
            end
            true
         end

         private
            #Collects information about current time.
            #
            # @param nil
            #
            # @return [Hash] - info about current time. Structure:
            #           :current_minute  [Integer] - number of current minute.
            #           :current_second  [Integer] - number of current_second.
            #           :previous_minute [Integer] - number of previous minute.
            #
            def get_scoped_time
               current_time = Time.now
               current_minute = current_time.strftime('%M').to_i
               current_second = current_time.strftime('%S').to_i
               descendant_minute = current_minute-1
               previous_minute = descendant_minute >= 0 ? descendant_minute : 59

               {
                   current_minute: current_minute,
                   previous_minute: previous_minute,
                   current_second: current_second
               }
            end

      end

   end
end
