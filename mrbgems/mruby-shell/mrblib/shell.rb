# Runs a command in shell and returns the result as a String.
# This command is portable and should work on Mac, Linux, and Windows (but the
# must be supported by the OS!)
# @example List the current directory (on Max or Linux):
#   shell("ls #{dir}") #=> a String containing the list of files in `dir`
# @example List the current directory (on Windows):
#   shell("dir #{dir}") #=> a String containing the list of files in `dir`
# @param cmd [String] the command to be executed
# @param input [String] the standard input to be passed to cmd.
# @return [String] if input=nil, an Array with the command output and the command exit code, otherwise a Fixnum representing the command exit code
# @!method shell(cmd, input=nil)
# @author Bosetti
