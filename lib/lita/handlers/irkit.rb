require 'irkit'
require 'json'

module Lita
  module Handlers
    class Irkit < Handler
      def self.default_config(handler_config)
        handler_config.deviceid  = ENV['IRKIT_DEVICEID']
        handler_config.clientkey = ENV['IRKIT_CLIENTKEY']
      end

      route /^ir list/,        :ir_list,   command: true, help: { "ir list"                  => "list irkit command names" }
      route /^ir save (.+)/,   :ir_save,   command: true, help: { "ir save [command_name]"   => "save irkit command as name" }
      route /^ir send (.+)/,   :ir_send,   command: true, help: { "ir send [command_name]"   => "send irkit command" }
      route /^ir remove (.+)/, :ir_remove, command: true, help: { "ir remove [command_name]" => "remove irkit command" }

      def ir_list(response)
        response.reply Lita.redis.keys('irkit:messages:*').map{|key| key.gsub(/^irkit:messages:/, '')}.join(', ')
      end

      def ir_save(response)
        cmd     = response.matches[0][0]
        ir_data = irkit.get_messages
        return response.reply "ir data not found" unless ir_data

        Lita.redis["irkit:messages:#{cmd}"] = ir_data.message.to_json
        response.reply "ir data saved: #{cmd}"
      end

      def ir_send(response)
        cmd = response.matches[0][0]
        message = Lita.redis["irkit:messages:#{cmd}"]
        return response.reply 'ir data not found' unless message

        irkit.post_messages JSON.parse(message)
        response.reply "ir data send: #{cmd}"
      end

      def ir_remove(response)
        cmd = response.matches[0][0]
        Lita.redis.del "irkit:messages:#{cmd}"
        response.reply "ir data deleted: #{cmd}"
      end

      def config
        Lita.config.handlers.irkit
      end

      def irkit
        @irkit ||= ::IRKit::InternetAPI.new(clientkey: config.clientkey, deviceid: config.deviceid)
      end
    end

    Lita.register_handler(Irkit)
  end
end
