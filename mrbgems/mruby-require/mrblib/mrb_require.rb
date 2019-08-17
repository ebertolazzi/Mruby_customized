
module Kernel
  def require_relative(file,path = nil)
    filename = nil
    unless path
      call_trace = caller
      if call_trace.empty?
        call_trace = __call_stack
      end
      filename = call_trace.first
	    while filename[-1] != ':'
	      filename.chop!
	    end
	    filename.chop!
	    filename = File.expand_path filename
    end
    filename ||= path
	  require File.expand_path(file,File.dirname(filename))
  end
private

  def __call_stack
    begin; raise ""; rescue => e; end
    backtrace = e.backtrace
    backtrace.shift
    backtrace
  end

end
