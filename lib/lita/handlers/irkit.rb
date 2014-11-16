require 'faraday'
require 'json'

module Lita
  module Handlers
    class Irkit < Handler
      def self.default_config(handler_config)
        handler_config.deviceid  = ENV['IRKIT_DEVICEID']
        handler_config.clientkey = ENV['IRKIT_CLIENTKEY']
      end

      route /^ir list/,            :ir_list,       command: false, help: { "ir list"                      => "list irkit command names" }
      route /^ir send (.+)/,       :ir_send,       command: false, help: { "ir send [command_name]"       => "send irkit command" }
      route /^ir register (.+)/,   :ir_register,   command: true,  help: { "ir register [command_name]"   => "register irkit command" }
      route /^ir unregister (.+)/, :ir_unregister, command: true,  help: { "ir unregister [command_name]" => "unregister irkit command" }

      def ir_list(response)
        response.reply Lita.redis.keys('irkit:messages:*').map{|key| key.gsub(/^irkit:messages:/, '')}.join(', ')
      end

      def ir_register(response)
        cmd     = response.matches[0][0]
        ir_data = irkit_api.get('/1/messages', clientkey: config.clientkey).body
        return response.reply "ir data not found" if ir_data.length == 0

        Lita.redis["irkit:messages:#{cmd}"] = JSON.parse(ir_data)['message'].to_json
        response.reply ":ok_woman:"
      end

      def ir_send(response)
        cmd = response.matches[0][0]
        message = Lita.redis["irkit:messages:#{cmd}"]
        return response.reply 'ir data not found' unless message

        irkit_api.post('/1/messages', clientkey: config.clientkey, deviceid: config.deviceid, message: message)
        response.reply ":ok_woman:"
      end

      def ir_unregister(response)
        cmd = response.matches[0][0]
        Lita.redis.del "irkit:messages:#{cmd}"
        response.reply ":ok_woman:"
      end

      def config
        Lita.config.handlers.irkit
      end

      def irkit_api
        @conn ||= Faraday.new(url: 'https://api.getirkit.com') do |faraday|
          faraday.request  :url_encoded             # form-encode POST params
          faraday.response :logger                  # log requests to STDOUT
          faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
        end
      end
    end

    Lita.register_handler(Irkit)
  end
end
