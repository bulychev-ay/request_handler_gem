class RequestHandlerGem

   @@using_handler = if ENV['STORAGE_TYPE'].eql? 'redis'
      LocalStorageModules::RedisHandler
   else
      LocalStorageModules::PStoreHandler
   end

   include @@using_handler
   
end