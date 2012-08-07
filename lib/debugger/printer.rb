require 'monitor'

module Debugger
  class Printer
    @@monitor = Monitor.new
    attr_accessor :interface

    def initialize interface, formatter = Debugger::Formatters.const_get(self.class.to_s)
      @interface = interface
      @formatter = formatter.new(self)
    end

    def method_missing meth, *args, &block
      if meth =~ /^print_(.+?)$/
        @@monitor.syncronize do
          @formatter.send $1, *args, &block
        end
      end
    end
  end
end
