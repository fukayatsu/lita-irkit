require "spec_helper"

describe Lita::Handlers::Irkit, lita_handler: true do
  let(:irkit_api_stub) { Faraday::Adapter::Test::Stubs.new }

  before do
    conn = Faraday.new do |faraday|
      faraday.adapter :test, irkit_api_stub
    end

    allow_any_instance_of(described_class).to receive(:irkit_api).and_return(conn)
  end

  describe 'ir list' do
    before do
      Lita.redis['handlers:irkit:messages:foo'] = 'FOO'
      Lita.redis['handlers:irkit:messages:bar'] = 'BAR'
    end

    it 'list irkit command names' do
      send_message 'ir list'

      expect(replies.last).to eq('bar, foo')
    end
  end

  describe 'ir send' do
    before do
      Lita.redis['handlers:irkit:messages:foo'] = 'FOO'

      irkit_api_stub.post('messages', message: 'FOO', deviceid: nil, clientkey: nil) { [200, {}, ''] }
    end

    context 'happy case' do
      it 'send irkit command' do
        send_message 'ir send foo'

        expect(replies.last).to eq(':ok_woman:')
      end
    end

    context 'command not found' do
      it 'do nothing' do
        send_message 'ir send bar'

        expect(replies.last).to eq('ir data not found')
      end
    end
  end

  describe 'ir all off' do
    before do
      Lita.redis['handlers:irkit:messages:foo off'] = 'FOO'
      Lita.redis['handlers:irkit:messages:bar_off'] = 'BAR'
      Lita.redis['handlers:irkit:messages:baz']     = 'BAZ'

      expect_any_instance_of(described_class).to     receive(:send_command).with('foo off')
      expect_any_instance_of(described_class).to     receive(:send_command).with('bar_off')
      expect_any_instance_of(described_class).to_not receive(:send_command).with('baz')
    end

    it "send ir commands which end with 'off'" do
      send_message 'ir all off'
    end
  end

  describe 'ir register' do
    context 'happy case' do
      before do
        irkit_api_stub.get('messages') { [200, {}, {message: {foo: 'bar'}}.to_json] }
      end

      it 'register irkit command' do
        send_command 'ir register foo'

        expect(replies.last).to eq(':ok_woman:')
        expect(Lita.redis['handlers:irkit:messages:foo']).to eq({foo: 'bar'}.to_json)
      end
    end

    context 'timeout' do
      before do
        irkit_api_stub.get('messages') { [200, {}, ''] }
      end

      it 'say ng' do
        send_command 'ir register foo'

        expect(replies.last).to eq('ir data not found')
        expect(Lita.redis['handlers:irkit:messages:foo']).to be_nil
      end
    end
  end

  describe 'ir unregister' do
    before do
      Lita.redis['handlers:irkit:messages:foo'] = 'FOO'
    end

    it 'unregister irkit command' do
      send_command 'ir unregister foo'

      expect(replies.last).to eq(':ok_woman:')
      expect(Lita.redis['handlers:irkit:messages:foo']).to be_nil
    end
  end

  describe 'ir migrate' do
    before do
      Lita.redis['irkit:messages:foo'] = 'FOO'
      Lita.redis['irkit:messages:bar'] = 'BAR'
      Lita.redis['baz']                = 'BAZ'
    end

    it 'migrate to new namespace' do
      send_command 'ir migrate'

      expect(replies.last).to eq(':ok_woman: 2 keys are migrated.')

      expect(Lita.redis.keys('handlers:irkit:*')).to match_array([
        'handlers:irkit:messages:foo',
        'handlers:irkit:messages:bar'
      ])
    end
  end
end
