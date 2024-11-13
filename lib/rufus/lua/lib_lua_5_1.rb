# frozen_string_literal: true

module Rufus::Lua
  module Lib
    module Lua5_1
      def self.included(mod)
        mod.attach_function :lua_call, [ :pointer, :int, :int ], :void

        mod.attach_function :lua_pcall, [ :pointer, :int, :int, :int ], :int

        mod.attach_function :lua_tonumber, [ :pointer, :int ], :double

        mod.attach_function :lua_remove, [ :pointer, :int ], :void

        mod.attach_function :luaL_loadbuffer, [ :pointer, :string, :int, :string ], :int

        mod.attach_function :lua_objlen, [ :pointer, :int ], :int
        mod.extend(ClassMethods)
      end

      LUA_REGISTRYINDEX = -10000
      LUA_GLOBALINDEX = -10002

      module ClassMethods
        def lua_setglobal(pointer, name)
          lua_setfield(pointer, LUA_GLOBALINDEX, name)
        end

        def lua_getglobal(pointer, name)
          lua_getfield(pointer, LUA_GLOBALINDEX, name)
        end


        # #open_library(libname) - load a lua library via lua_call().
        #
        # This is needed because is the Lua 5.1 Reference Manual Section 5
        # (http://www.lua.org/manual/5.1/manual.html#5) it says:
        #
        # "The luaopen_* functions (to open libraries) cannot be called
        # directly, like a regular C function. They must be called through
        # Lua, like a Lua function."
        #
        # "..you must call them like any other Lua C function, e.g., by using
        # lua_call."
        #
        # (by Matthew Nielsen - https://github.com/xunker)
        #
        def open_library(libname, pointer)
          lua_pushcclosure(
            pointer, lambda { |_ptr| send("luaopen_#{libname}", pointer) }, 0)
          lua_pushstring(
            pointer, (libname.to_s == "base" ? "" : libname.to_s))
          lua_call(
            pointer, 1, 0)
        end
      end
    end
  end
end
