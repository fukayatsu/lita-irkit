require 'faraday'
require 'json'

module Lita
  module Handlers
    class Irkit < Handler
      config :deviceid,  required: true, default: ENV['IRKIT_DEVICEID']
      config :clientkey, required: true, default: ENV['IRKIT_CLIENTKEY']

      route /^ir list/,            :ir_list,         command: false, help: { "ir list"                      => "list irkit command names" }
      route /^ir send (.+)/,       :ir_send,         command: false, help: { "ir send [command_name]"       => "send irkit command" }
      route /^ir all off/,         :ir_send_all_off, command: false, help: { "ir all off"                   => "send irkit commands which end with 'off'" }
      route /^ir register (.+)/,   :ir_register,     command: true,  help: { "ir register [command_name]"   => "register irkit command" }
      route /^ir unregister (.+)/, :ir_unregister,   command: true,  help: { "ir unregister [command_name]" => "unregister irkit command" }
      route /^ir migrate/,         :ir_migrate,      command: true

      def ir_list(response)
        response.reply redis.keys.map{ |key| key.sub(/^messages:/, '') }.join(', ')
      end

      def ir_register(response)
        cmd     = response.matches[0][0]
        ir_data = irkit_api.get('messages', clientkey: config.clientkey).body
        return response.reply "ir data not found" if ir_data.length == 0

        redis["messages:#{cmd}"] = JSON.parse(ir_data)['message'].to_json
        response.reply ":ok_woman:"
      end

      def ir_send(response)
        cmd = response.matches[0][0]

        if send_command(cmd)
          response.reply ":ok_woman:"
        else
          response.reply 'ir data not found' unless message
        end
      end

      def ir_send_all_off(response)
        keys = redis.keys('messages:*off')
        keys.each do |key|
          send_command(key)
        end
        response.reply ":ok_woman:"
      end

      def ir_unregister(response)
        cmd = response.matches[0][0]
        redis.del "messages:#{cmd}"
        response.reply ":ok_woman:"
      end

      def ir_migrate(response)
        keys = Lita.redis.keys('irkit:messages:*')

        Lita.redis.pipelined do
          keys.each do |key|
            Lita.redis.rename key, key.sub(/^irkit:messages:/, 'handlers:irkit:messages:')
          end
        end

        response.reply ":ok_woman: #{keys.size} keys are migrated."
      end

      def send_command(command)
        return false unless message = redis["messages:#{command}"]

        irkit_api.post('messages', clientkey: config.clientkey, deviceid: config.deviceid, message: message)
      end

    private

      def irkit_api
        @conn ||= Faraday.new(url: 'https://api.getirkit.com/1') do |faraday|
          faraday.request  :url_encoded             # form-encode POST params
          faraday.response :logger                  # log requests to STDOUT
          faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
        end
      end
    end

    Lita.register_handler(Irkit)
  end
end
