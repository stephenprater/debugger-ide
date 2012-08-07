module Debugger
  module IDE
    class State # :nodoc:
      attr_accessor :context, :file, :line, :binding
      attr_accessor :frame_pos, :previous_line
      attr_accessor :interface
      
      def initialize
        @frame_pos = 0
        @previous_line = nil
        @proceed = false
        yield self
      end
      
      def print(*args)
        @interface.print(*args)
      end
      
      def proceed?
        @proceed
      end
      
      def proceed
        @proceed = true
      end
    end
  end
end
