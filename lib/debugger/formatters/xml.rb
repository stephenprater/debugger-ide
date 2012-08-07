require 'builder'
require 'singleton'

module Debugger
  module Formatters
    class Xml
      include Singleton

      def xml
        Builder::XmlMarkup.new indent: 2
      end

      def message msg, *args
        xml.message do 
          msg % args
        end
      end

      def debug msg, *args
        Debugger.print_debug msg, *args
        if Debugger.remote_debug
          xml.message debug: true do 
            msg % args
          end
        end
      end

      def error msg, *args
        xml.error do
          msg % args
        end
      end

      def frames context, current_frame_id
        xml.frames do |frames|
          (0 ... context.stack_size).each do |id|
            frame_attributes =  {
              no: id + 1,
              file: File.expand_path(context.frame_file(id)),
              line: context.frame_line(id)
            }
            frame_attributes[:current] = true if id == current_frame_id
            
            frames.frame frame_attributes
          end
        end
      end

      def contexts contexts
        xml.threads do |thr|
          contexts.each do |c|
            thread_attributes = {
              id: c.thnum,
              status: c.thread.status,
              pid: Process.pid
            }
            thread_attributes[:current] = true if context.thread == Thread.current
            thr.thread thread_attributes
          end
        end
      end

      def array array
        xml.variables do |vars|
          array.each_with_index do |item, idx|
            variable vars, "[#{i}]", item, 'instance'
          end
        end
      end

      def hash hash
        xml.variables do |vars|
          hash.each_pair do |k,v|
            name = k.acts_like_string? ? "'#{k}'" : k.to_s
            variable vars, name, v, 'instance'
          end
        end
      end

      def breakpoint(breakpts)
        xml.breakpoints do |bps|
          breakpts.sort_by { |b| b.id }.each do |b|
            bps.breakpoint n: b.id, file: b.source, line: b.pos
          end
        end
      end

      def breakpoint_added(b)
        xml.breakpointAdded no: b.id, location: "#{b.source}:#{b.pos}"
      end

      def breakpoint_deleted(b)
        xml.breakpointDeleted no: b.id
      end

      def breakpoint_enabled(b)
        xml.breakpointEnabled bp_id: b.id
      end

      def breakpoint_disabled(b)
        xml.breakpointDisabled bp_id: b.id
      end

      def condition_set bp_id
        xml.conditionSet bp_id: bp_id
      end

      def catchpoint_set exception_class_name
        xml.catchpointSet exception: exception_class_name
      end

      def expressions exps
        xml.expressions do
          expressions.each_with_index do |(exp, value), idx|
            xml.display name: exp, value: value, no: idx
          end
        end
      end

      def eval exp, value
        xml.eval expression: exp, value: value
      end

      def pp value
        value
      end

      def list b, e, file, line
        str = "[#{b}, #{e}] in #{file}"
        if lines = Debugger.source_for(file)
          b.upto(e) do |n|
            if n > 0 && lines[n-1]
              if n == line
                str += "=> #{n}  #{lines[n-1].chomp}"
              else
                str += "   #{n}  #{lines[n-1].chomp}"
              end
            end
          end
        else
          str = "No sourcefile available for #{file}"
        end
      end

      def methods methods
        xml.methods do |meths|
          methods.each do |method|
            meths.method name: method
          end
        end
      end

      def breakpoint n, breakpoint
        breakpoint_attributes = {
          file:       breakpoint.source,
          line:       breakpoint.pos,
          threadId:   Debugger.current_context.thnum
        }
        xml.breakpoint breakpoint_attributes
      end

      def catchpoint
        context = Debugger.current_context
        catchpoint_attributes = {
          file:       context.frame_file(0),
          line:       context.frame_line(0),
          type:       exception.class,
          message:    exception.message,
          threadId:   context.thnum
        }
        xml.exception catchpoint_attributes
      end

      def trace context, file, line
        trace_attributes = {
          file:       file,
          line:       line,
          threadId:   context.thnum
        }
        xml.trace trace_attributes
      end

      def at_line context, file, line
        suspend_attributes = {
          file:      File.expand_path(file),
          line:      line,
          context:   context.thnum,
          frames:    context.stack_size
        }
        xml.suspended suspend_attributes
      end

      def exception exception, binding
        variables("error", "exception") do |var|
          proxy = Debugger::ExceptionProxy.new(exception)
          InspectCommand.reference_result(proxy)
          proxy
        end
      rescue
        xml.processingException type: exception.class, message: exception.messages
      end

      def inspect eval_result
        xml.variables do |vars|
          variable vars, "eval_result", eval_results, "local"
        end
      end

      def load_results file, exception
        if exception
          xml.loadResult file: file, exceptionType: exception.class, exceptionMessage: exception.message
        else
          xml.loadResult file: file, status: "OK"
        end
      end

      def variables variables, kind
        xml.variables do |vars|
          if vars.include? 'self'
            variable vars, 'self', yield('self'), kind
          end

          vars.sort.each do |v|
            variable(vars, v, yield(v), kind) unless v == 'self'
          end
        end
      end

      private
      def variable builder, name, value, kind
        name = name.to_s
        has_children = false
        if value.nil?
          builder.variable name: name, kind: kind
          return
        end

        if value.is_a?(Array) || value.is_a?(Hash)
          unless value.empty?
            has_children = true
            value_str = "#{value.class} (#{value.size} elements(s))"
          else
            has_children = false
            value_str = "Empty #{value.class}"
          end
        else
          has_children = !value.instance_variables.empty? || !value.class.class_variables.empty?
          value_str = value.to_s || 'nil' rescue "<#to_s method raised exception ##{$!}>"
          unless value_str.acts_like_string?
            value_str = "ERROR: #{value.class}.to_s method returns #{value_str.class}. Should return String." 
          end
        end

        if value_str.andand.is_binary_data?
          value_str = "[Binary Data]"
        end
        variable_attributes = {
          name:          name,
          kind:          kind,
          value:         value_str,
          type:          value.class,
          hasChildren:   has_children,
          objectId:      value.andand.object_id || value.id
        }
        
        builder.variable variable_attributes
      end
    end
  end
end
