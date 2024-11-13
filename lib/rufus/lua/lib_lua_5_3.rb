# frozen_string_literal: true

module Rufus::Lua
  module Lib
    module Lua5_3
      def self.included(mod)
        mod.attach_function :lua_callk, [ :pointer, :int, :int, :int, :int ], :void

        mod.attach_function :lua_pcallk, [ :pointer, :int, :int, :int, :int, :int ], :int

        mod.attach_function :lua_tonumberx, [ :pointer, :int, :pointer ], :double

        mod.attach_function :lua_rawlen, [ :pointer, :int ], :int

        mod.attach_function :lua_rotate, [ :pointer, :int, :int ], :void

        mod.attach_function :luaL_loadbufferx, [ :pointer, :string, :int, :string, :pointer ], :int

        mod.attach_function :lua_rawlen, [ :pointer, :int ], :int

        mod.attach_function :lua_setglobal, [ :pointer, :string ], :void
        mod.attach_function :lua_getglobal, [ :pointer, :string ], :int
        mod.attach_function :luaL_requiref, [ :pointer, :string, :cfunction, :int ], :void

        mod.extend(ClassMethods)
      end

      module ClassMethods
        def lua_call(pointer, nargs, nresults)
          lua_callk(pointer, nargs, nresults, 0, 0)
        end

        def lua_pcall(pointer, nargs, nresults, msgh)
          lua_pcallk(pointer, nargs, nresults, msgh, 0, 0)
        end

        def lua_tonumber(pointer, index)
          lua_tonumberx(pointer, index, FFI::Pointer::NULL)
        end

        def lua_objlen(pointer, index)
          lua_rawlen(pointer, index)
        end

        def lua_remove(pointer, index)
          self.lua_rotate(pointer, index, -1)
          self.lua_settop(pointer, -2)
        end

        def luaL_loadbuffer(pointer, buffer, sz, name)
          luaL_loadbufferx(pointer, buffer, sz, name, FFI::Pointer::NULL)
        end

        def lua_objlen(pointer, index)
          lua_rawlen(pointer, index)
        end

        def open_library(libname, pointer)
          luaL_requiref(pointer, libname, lambda { |_ptr| send("luaopen_#{libname}", pointer) }, 1)
        end
      end

      LUA_REGISTRYINDEX = -1001000
    end
  end
end
