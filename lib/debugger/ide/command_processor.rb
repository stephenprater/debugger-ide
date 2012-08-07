module Debugger
  module IDE
    class CommandProcessor
      def initialize(interface = nil)
        @interface = interface
        @printer = Debugger::Printer.new(@interface, Debugger::Formatters::Xml)
      end

      def print(*args)
        @interface.print(*args)
      end

      def process_commands
        unless Debugger.event_processor.at_line?
          @printer.print_error "There is no thread suspended at the time and therefore no context to execute '#{input.gsub('%', '%%')}'"
          return
        end
        context = Debugger.event_processor.context
        file = Debugger.event_processor.file
        line = Debugger.event_processor.line
        state = State.new do |s|
          s.context = context
          s.file    = file
          s.line    = line
          s.binding = context.frame_binding(0)
          s.interface = @interface
        end
        event_cmds = Command.commands.map{|cmd| cmd.new(state, @printer) }
        while !state.proceed? do
          inp = @interface.command_queue.pop
          catch(:debug_error) do
            splitter[inp].each do |input|
              # escape % since print_debug might use printf
              @printer.print_debug "Processing in context: #{input.gsub('%', '%%')}"
              if cmd = event_cmds.find { |c| c.match(input) }
                if context.dead? && cmd.class.need_context
                  @printer.print_msg "Command is unavailable\n"
                else
                  cmd.execute
                end
              else
                @printer.print_msg "Unknown command: #{input}"
              end
            end
          end
        end
      rescue IOError, Errno::EPIPE
        @printer.print_error "INTERNAL ERROR!!! #{$!}\n" rescue nil
        @printer.print_error $!.backtrace.map{|l| "\t#{l}"}.join("\n") rescue nil
      rescue Exception
        @printer.print_error "INTERNAL ERROR!!! #{$!}\n" rescue nil
        @printer.print_error $!.backtrace.map{|l| "\t#{l}"}.join("\n") rescue nil
      end

      def splitter
        lambda do |str|
          str.split(/;/).inject([]) do |m, v|
            if m.empty?
              m << v
            else
              if m.last[-1] == ?\\
                m.last[-1,1] = ''
                m.last << ';' << v
              else
                m << v
              end
            end
            m
          end
        end
      end    
    end
  end
end
