# require the debugger gem, and all that that entails
require 'debugger'

require "debugger/ide/version"
require "debugger/formatters"
require "debugger/exception"
require "debugger/context"
require "debugger/ide"

require "debugger/kernel"

module Debugger
  class << self
    # we need to get at these internal variables, so add accessors
    attr_accessor :event_processor, :cli_debug, :xml_debug
    attr_accessor :control_thread
  end
end


Debugger.cli_debug = true
listen_for_ide('127.0.0.1',1234)
