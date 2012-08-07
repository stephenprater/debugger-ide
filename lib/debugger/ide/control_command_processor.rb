module Debugger
  module IDE
    class ControlCommandProcessor < CommandProcessor
      def process_commands
        @printer.print_debug("Starting control thread")
        ctrl_cmd_classes = Command.commands.select{|cmd| cmd.control}
        state = ControlState.new(@interface)
        ctrl_cmds = ctrl_cmd_classes.map{|cmd| cmd.new(state, @printer)}
        
        while input = @interface.read_command
          # escape % since print_debug might use printf
          # sleep 0.3
          catch(:debug_error) do
            if cmd = ctrl_cmds.find { |c| c.match(input) }
              @printer.print_debug "Processing in control: #{input.gsub('%', '%%')}"
              cmd.execute
            else
              @interface.command_queue << input
            end
          end
        end
      rescue IOError, Errno::EPIPE
        @printer.print_error "INTERNAL ERROR!!! #{$!}\n" rescue nil
        @printer.print_error $!.backtrace.map{|l| "\t#{l}"}.join("\n") rescue nil
      rescue Exception
        @printer.print_error "INTERNAL ERROR!!! #{$!}\n" rescue nil
        @printer.print_error $!.backtrace.map{|l| "\t#{l}"}.join("\n") rescue nil
      ensure
        @interface.close
      end
    end
  end
end
