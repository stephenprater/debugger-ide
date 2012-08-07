module Debugger
  class Printers
    class ExceptionProxy < BasicObject
      def initialize(exception)
        @exception = exception
        @message = exception.message
        @backtrace = Debugger.cleanup_backtrace(exception.backtrace)
      end

      private 
      def method_missing(called, *args, &block) 
        @exception.__send__(called, *args, &block) 
      end
    end
  end
end
