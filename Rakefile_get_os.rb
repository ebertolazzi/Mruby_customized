#  __  __    _    ____ _____ _____ ____    ____       _         __ _ _
# |  \/  |  / \  / ___|_   _| ____|  _ \  |  _ \ __ _| | _____ / _(_) | ___
# | |\/| | / _ \ \___ \ | | |  _| | |_) | | |_) / _` | |/ / _ \ |_| | |/ _ \
# | |  | |/ ___ \ ___) || | | |___|  _ <  |  _ < (_| |   <  __/  _| | |  __/
# |_|  |_/_/   \_\____/ |_| |_____|_| \_\ |_| \_\__,_|_|\_\___|_| |_|_|\___|
#

# constanti legate al sistema operativo e al compilatore
case RUBY_PLATFORM

when /darwin/

  OS         = :mac
  WHICH_CMD  = 'which'
  DYL_EXT    = 'dylib'
  PREFIX     = ''
  VS_VERSION = ''
  VS_ARCH    = ''
  LIBCC      = '-std=c++11 -stdlib=libc++ -lc++'

when /linux/

  OS         = :linux
  WHICH_CMD  = 'which'
  DYL_EXT    = 'so'
  PREFIX     = '/usr/local'
  VS_VERSION = ''
  VS_ARCH    = ''
  LIBCC      = '-std=c++11 -lc++'

when /mingw|mswin/

  OS        = :win
  WHICH_CMD = 'where'
  DYL_EXT   = 'dll'
  PREFIX    = '/usr/local'

  # in windows use visual studio compiler, check version
  tmp = `#{WHICH_CMD} cl.exe`.lines.first
  case tmp
  when /16\.0/
    VS_VERSION = '2017'
  when /2017/
    VS_VERSION = '2017'
  when /14\.0/
    VS_VERSION = '2015'
  when /12\.0/
    VS_VERSION = '2013'
  when /10\.0/
    VS_VERSION = '2010'
  else
    raise RuntimeError, "\n\nUnsupported VisualStudio version #{tmp}\n\n"
  end
  # check architecture
  case tmp
  when /Hostx64\\x64\\cl\.exe/
    VS_ARCH = 'x64'
  when /amd64\\cl\.exe/
    VS_ARCH = 'x64'
  when /bin\\cl\.exe/
    VS_ARCH = 'x86'
  else
    raise RuntimeError, "Cannot determine architecture for Visual Studio #{VS_VERSION}"
  end

  if ENV['DEBUG'] == "yes" then
    SUFFIX = "_vs#{VS_VERSION}_#{VS_ARCH}"
  else
    SUFFIX = "_vs#{VS_VERSION}_#{VS_ARCH}_debug"
  end

  FileUtils.copy_file( File.expand_path("../../../LibSources/os_win/lib/yaml#{SUFFIX}.lib", __FILE__),
                       File.expand_path("../dummy_libs/yaml.lib", __FILE__) )
  FileUtils.copy_file( File.expand_path("../../../LibSources/os_win/lib/pcre#{SUFFIX}.lib", __FILE__),
                       File.expand_path("../dummy_libs/pcre.lib", __FILE__) )
  FileUtils.copy_file( File.expand_path("../../../LibSources/os_win/lib/onig#{SUFFIX}.lib", __FILE__),
                       File.expand_path("../dummy_libs/onig.lib", __FILE__) )

else
  raise RuntimeError, "Unsupported OS: #{RUBY_PLATFORM}"
end
