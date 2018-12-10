class RequestHandlerGem

   require 'local_storage_modules/p_store_handler.rb'
   require 'local_storage_modules/redis_handler.rb'
   
   @@using_handler = if ENV['STORAGE_TYPE'].eql? 'redis'
      LocalStorageModules::RedisHandler
   else
      LocalStorageModules::PStoreHandler
   end

   include @@using_handler
   
end