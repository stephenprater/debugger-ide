module Kernel
  #
  # Stops the current thread after a number of _steps_ made.
  #
  def debugger(steps = 1)
    Debugger.current_context.stop_next = steps
  end

  def listen_for_ide(*args)
    Debugger::IDE.start_ide_control(*args)
  end
  #
  # Returns a binding of n-th call frame
  #
  def binding_n(n = 0)
    Debugger.current_context.frame_binding[n+1]
  end
end

