
require 'ffi'
require_relative 'lib_lua_5_1'
require_relative 'lib_lua_5_3'

module Rufus
module Lua

  module Lib
    extend FFI::Library

    def self.attempt_to_load_lua(version)
      lua_lib = "liblua#{version}"
      begin
        ffi_lib(lua_lib)
      rescue LoadError
        paths = ["/usr/lib/*/#{lua_lib}.*so*"].inject([]) { |a, e| a.concat(Dir.glob(e)) }
        begin
          # second attempt
          ffi_lib(paths)
          true
        rescue LoadError
          false
        end
      end
    end

    #
    # locate the dynamic library
    ffi_lib_flags(:lazy, :global)
    LUA_VERSION = if ENV['LUA_LIB']
                    ffi_lib(ENV['LUA_LIB'])
                    case ENV['LUA_LIB']
                    when /5.1/
                      "5.1"
                    when /5.3/
                      "5.3"
                    when /5.4/
                      "5.4"
                    else
                      raise "Unsupported Lua version: #{ENV['LUA_LIB']}, only 5.4, 5.3, and 5.1 are supported"
                    end
                  elsif attempt_to_load_lua("5.4")
                    "5.4"
                  elsif attempt_to_load_lua("5.3")
                    "5.3"
                  elsif attempt_to_load_lua("5.1")
                    "5.1"
                  else
                    raise "Didn't find the Lua dynamic library for liblua for version 5.4, 5.3, and 5.1 on your system. " +
                          "Set LUA_LIB in your environment if have that library"
                  end

    lua_version_specific_funcs = case LUA_VERSION
                                 when "5.1"
                                   Lua5_1
                                 when "5.3"
                                   Lua5_3
                                 when "5.4"
                                   Lua5_3 # No changes seem to be needed for 5.4
                                 else
                                   raise "Unsupported Lua version: #{LUA_VERSION}, only 5.4, 5.3, and 5.1 are supported"
                                 end

    # Rufus::Lua::Lib.path returns the path to the library used.
    #
    def self.path

      f = ffi_libraries.first

      f ? f.name : nil
    end
    #
    # attach functions

    attach_function :lua_close, [ :pointer ], :void

    %w[ base package string table math io os debug ].each do |libname|
      attach_function "luaopen_#{libname}", [ :pointer ], :int
    end

    attach_function :luaL_openlibs, [ :pointer ], :void

    #attach_function :lua_resume, [ :pointer, :int ], :int

    attach_function :lua_toboolean, [ :pointer, :int ], :int
    attach_function :lua_tolstring, [ :pointer, :int, :pointer ], :pointer

    attach_function :lua_type, [ :pointer, :int ], :int
    attach_function :lua_typename, [ :pointer, :int ], :string

    attach_function :lua_gettop, [ :pointer ], :int
    attach_function :lua_settop, [ :pointer, :int ], :void

    attach_function :lua_getfield, [ :pointer, :int, :string ], :pointer
    attach_function :lua_gettable, [ :pointer, :int ], :void

    attach_function :lua_createtable, [ :pointer, :int, :int ], :void
    #attach_function :lua_newtable, [ :pointer ], :void
    attach_function :lua_settable, [ :pointer, :int ], :void

    attach_function :lua_next, [ :pointer, :int ], :int

    attach_function :lua_pushnil, [ :pointer ], :pointer
    attach_function :lua_pushboolean, [ :pointer, :int ], :pointer
    attach_function :lua_pushinteger, [ :pointer, :int ], :pointer
    attach_function :lua_pushnumber, [ :pointer, :double ], :pointer
    attach_function :lua_pushstring, [ :pointer, :string ], :pointer
    attach_function :lua_pushlstring, [ :pointer, :pointer, :int ], :pointer
    attach_function :lua_pushvalue, [:pointer, :int], :void

      # removes the value at the given stack index, shifting down all elts above

    #attach_function :lua_pushvalue, [ :pointer, :int ], :void
      # pushes a copy of the value at the given index to the top of the stack
    #attach_function :lua_insert, [ :pointer, :int ], :void
      # moves the top elt to the given index, shifting up all elts above
    #attach_function :lua_replace, [ :pointer, :int ], :void
      # pops the top elt and override the elt at given index with it

    attach_function :lua_rawgeti, [ :pointer, :int, :int ], :void

    attach_function :luaL_newstate, [], :pointer
    attach_function :luaL_ref, [ :pointer, :int ], :int
    attach_function :luaL_unref, [ :pointer, :int, :int ], :void

    attach_function :lua_gc, [ :pointer, :int, :int ], :int

    callback :cfunction, [ :pointer ], :int
    attach_function :lua_pushcclosure, [ :pointer, :cfunction, :int ], :void
    attach_function :lua_setfield, [ :pointer, :int, :string ], :void

    include lua_version_specific_funcs

    LUA_REGISTRY_INDEX = lua_version_specific_funcs::LUA_REGISTRYINDEX
  end
end
end

