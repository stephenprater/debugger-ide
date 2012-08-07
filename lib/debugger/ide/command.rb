require 'forwardable'

module Debugger
  module IDE
    class Command
      class << self
        def commands
          @commands ||= []
        end

        def options
          @options ||= {}
        end

        class_attribute :default_options
        self.default_options = {
            event: true,
            control: false,
            unknown: false,
            need_context: false
          }

        def const_missing sym
          require File.join(File.dirname(__FILE__) + 'commands', sym.underscore)
          # we no longer include the functions here, we expect the command
          # definition files to do it.
        end

        def method_missing meth, *args, &block
          if meth.to_s =~ /^(.+?)=$/
            @options[$1.intern] = args.first
          else
            @options.has_key?(meth) ? @options[meth] : super
          end
        end
      end

    class SubCommand
      attr_accessor :name, :min, :short_help, :long_help
    end

    extend Forwardable
    attr_accessor :printer, :state
    
    delegate :errmsg, :debug => :printer
    delegate :print => :state 

    def find subcmds, param
      param.downcase!
      #what?
    end
      
    def initialize state, printer
      @state, @printer = state, printer
    end

    def match input
      @match = regexp.match(input)
    end

    protected

    def method_missing(meth, *args, &block)
      if @printer.respond_to? meth
        @printer.send meth, *args, &block
      else
        super
      end
      
      # see Timeout::timeout, the difference is that we must use a DebugThread
      # because every other thread would be halted when the event hook is reached
      # in ruby-debug.c
      def timeout sec
        return yield if sec == nil or sec.zero?
        begin
          current_thread = Thread.current
          timeout_thread = DebugThread.start do
            sleep sec
            current_thread.raise StandardError, "Timeout: evaluation took longer than #{sec} seconds." if x.alive?
          end
          yield sec
        ensure
          timeout_thread.kill if timeout_thread and timeout_thread.alive?
        end
      end

      def debug_eval str, b = get_binding
        begin
          str = str.to_s
          @printer.print_debug "Evaluating #{str} with timeout after 10 seconds"
          timeout 10 do
            eval str.to_s.gsub(/\\n/,"\n", b)
          end
        rescue StandardError, ScriptError => e
          @printer.print_exception e, @state.binding
          throw :debug_error
        end
      end

      def get_binding
        binding = @state.context.frame_binding(@state.frame_pos)
        binding || hbinding(@state.context.frame_locals(@state.frame_pos))
      end

      def line_at(file, line)
        Debugger.line_at(file, line)
      end

      def get_context(thnum)
        Debugger.contexts.find { |c| c.thnum == thnum }
      end  

      private

      def hbinding hash
       code = hash.keys.map{|k| "#{k} = hash['#{k}']"}.join(';') + ';binding'
        if obj = @state.context.frame_self(@state.frame_pos)
          obj.instance_eval code
        else
          eval code
        end
      end
    end
  end
end
