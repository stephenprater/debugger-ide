module Debugger
  module IDE
    class ControlState # :nodoc:
      def initialize(interface)
        @interface = interface
      end
      
      def proceed
      end
      
      def print(*args)
        @interface.print(*args)
      end
      
      def context
        nil
      end
      
      def file
        print "ERROR: No filename given.\n"
        throw :debug_error
      end
    end
  end
end
