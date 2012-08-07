# require the debugger gem, and all that that entails
require 'debugger'

require "debugger/ide/version"
require "debugger/exception"
require "debugger/context"
require "debugger/ide"

require "debugger/kernel"

Debugger::IDE.cli_debug = true
listen_for_remote_debugger('127.0.0.1',1234)
