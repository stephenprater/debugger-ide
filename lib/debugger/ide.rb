require 'forwardable'

module Debugger
  module IDE
    autoload 'Interface',                 'debugger/ide/interface'
    autoload 'EventProcessor',            'debugger/ide/event_processor'
    autoload 'ControlCommandProcessor',   'debugger/ide/control_command_processor'
    autoload 'CommandProcessor',          'debugger/ide/command_processor'
    autoload 'State',                     'debugger/ide/state'
    autoload 'ControlState',              'debugger/ide/control_state'

    class << self
      def debug(*args)
        if cli_debug
          $stderr << "#{Process.pid}: " 
          $stderr.flush
        end
      end

      def start_ide_control(host = nil, ctrl_port = PORT + 1)
        raise "Debugger not started" unless Debugger.started?
        ( warn "control thread started multiple times" and return ) if control_thread
        
        return if control_thread

        control_thread = DebugThread.new do
          a_host ||= '127.0.0.1'
          $stdout.puts "Debugger::IDE (#{Debugger::IDE::VERSION}) on #{Debugger::VERSION} listening on #{a_host}:#{a_port}"
          server = TCPServer.new(a_host,a_port)
          while session = server.accept
            debug "Connected from #{session.addr[2]}"
            begin
              interface = Debugger::IDE::IDEInterface.new(session)
              event_processor = Debugger::IDE::EventProcessor.new(interface)
              Debugger::IDE::ControlCommandProcessor.new(Debugger.interface).process_commands
            rescue StandardError, ScriptError => ex
              debug "Exception in Debugger::IDE control thread", ex.message, ex.backtrace 
              exit 1
            end
          end
        end
        control_thread.abort_on_exception = true
      rescue Exception => ex
        binding.pry
        debug "Fatal exception in DebugThread loop", ex.message, ex.backtrace
        exit 2
      end
    end
  end
end
