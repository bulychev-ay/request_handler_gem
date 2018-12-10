class RequestHandlerGem

   require 'local_storage_modules/p_store_handler.rb'
   require 'local_storage_modules/redis_handler.rb'
   
   if ENV['STORAGE_TYPE'].eql? 'redis'
      @@include_handler = LocalStorageModules::RedisHandler
      @@extend_methods = LocalStorageModules::RedisHandler::ClassMethods
   else
      @@include_handler = LocalStorageModules::PStoreHandler
      @@extend_methods = LocalStorageModules::PStoreHandler::ClassMethods
   end

   include @@include_handler
   extend @@extend_methods
   
end