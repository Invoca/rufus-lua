
#
# Specifying rufus-lua
#
# Tue Jul 22 21:07:10 JST 2014
#

require 'spec_base'


describe 'State and error handler' do

  before do
    @s = Rufus::Lua::State.new
  end
  after do
    @s.close
  end

  describe '#set_error_handler(lua_code)' do
    let(:expected_message) do
      <<~STR.strip
        eval:pcall : 'mystuff.lua:77:3: in f
        stack traceback:
        \t[string "line"]:2: in function <[string "line"]:1>
        \t[C]: in function 'error'
        \tmystuff.lua:77:3: in function 'f'
        \tmymain.lua:88:1: in main chunk' (2 LUA_ERRRUN)
      STR
    end

    it 'registers a function as error handler' do

      le = nil

      @s.set_error_handler(%{
        function (e)
          return e .. '\\n' .. debug.traceback()
        end
      })

      @s.eval(%{
        function f ()
          error("in f")
        end
      }, nil, 'mystuff.lua', 77)
      begin
        @s.eval('f()', nil, 'mymain.lua', 88)
      rescue Rufus::Lua::LuaError => le
      end

      expect(le.message).to eq(expected_message)

      expect(@s.send(:stack_top)).to eq(1)
    end

    it 'sets the error handler in a permanent way' do

      le = nil

      @s.set_error_handler(%{
        function (e)
          return 'something went wrong: ' .. string.gmatch(e, ": (.+)$")()
        end
      })

      begin
        @s.eval('error("a")')
      rescue Rufus::Lua::LuaError => le
      end

      expect(le.msg).to eq('something went wrong: a')

      begin
        @s.eval('error("b")')
      rescue Rufus::Lua::LuaError => le
      end

      expect(le.msg).to eq('something went wrong: b')
    end

    context 'CallbackState' do

      # Setting an error handler on the calling state or even directly
      # on the CallbackState doesn't have any effect.
      # Any error handler seems bypassed.

      it 'has no effect' do

        e = nil

        @s.set_error_handler(%{
          function (e) return 'bad: ' .. string.gmatch(e, ": (.+)$")() end
        })
        f = @s.function(:do_fail) { fail('in style') }
        begin
          @s.eval('do_fail()')
        rescue Exception => e
        end

        expect(e.class).to eq(RuntimeError)
      end
    end
  end

  describe '#set_error_handler(:traceback)' do
    let(:expected_message) do
      <<~STR.strip
        eval:pcall : 'mystuff.lua:77:3: in f
        stack traceback:
        \t[C]: in function 'error'
        \tmystuff.lua:77:3: in function 'f'
        \tmymain.lua:88:1: in main chunk' (2 LUA_ERRRUN)
      STR
    end
    it 'sets a vanilla debug.traceback() error handler' do

      le = nil

      @s.set_error_handler(:traceback)

      @s.eval(%{
        function f ()
          error("in f")
        end
      }, nil, 'mystuff.lua', 77)
      begin
        @s.eval('f()', nil, 'mymain.lua', 88)
      rescue Rufus::Lua::LuaError => le
      end

      expect(le.message).to eq(expected_message)
    end
  end

  describe '#set_error_handler(:backtrace)' do

    it 'sets a special handler that provides a merged Ruby then Lua backtrace'
      # does it make any sense?
  end

  describe '#set_error_handler(&ruby_block)' do

    it 'sets a Ruby callback as handler' do

      le = nil

      @s.set_error_handler do |msg|
        ([ msg.split.last ] * 3).join(' ')
      end

      begin
        @s.eval('error("tora")')
      rescue Rufus::Lua::LuaError => le
      end

      expect(le.msg).to eq('tora tora tora')
    end
  end

  describe '#set_error_handler(nil)' do

    it 'unsets the current error handler' do

      le = nil

      # set

      @s.set_error_handler(%{
        function (e)
          return 'something went wrong: ' .. string.gmatch(e, ": (.+)$")()
        end
      })

      begin
        @s.eval('error("a")')
      rescue Rufus::Lua::LuaError => le
      end

      expect(le.msg).to eq('something went wrong: a')

      # unset

      @s.set_error_handler(nil)

      begin
        @s.eval('error("b")')
      rescue Rufus::Lua::LuaError => le
      end

      expect(le.msg).to eq('[string "line"]:1: b')
      expect(@s.send(:stack_top)).to eq(0)
    end
  end

  describe '#set_error_handler(x)' do

    it 'pops the previous handler from the stack' do

      le = nil

      expect(@s.send(:stack_top)).to eq(0)

      @s.set_error_handler(%{ function (e) return "a" end })
      #@s.set_error_handler(:traceback)
      #@s.set_error_handler do |msg| return msg * 2; end

      #@s.send(:print_stack)

      expect(@s.send(:stack_top)).to eq(1)

      @s.set_error_handler(%{ function (e) return "b" end })

      #@s.send(:print_stack)

      expect(@s.send(:stack_top)).to eq(1)

      begin
        @s.eval('error("Z")')
      rescue Rufus::Lua::LuaError => le
      end

      expect(le.msg).to eq('b')
    end
  end
end

