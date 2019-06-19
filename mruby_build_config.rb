# encoding: utf-8
# dumpbin -linkermember:1 yaml.lib
# dumpbin -linkermember:1 pcre.lib

require File.expand_path('../Rakefile_get_os', __FILE__)
require File.expand_path('../VS_flags', __FILE__)

begin
  if ENV['DEBUG'] == "yes" then
    VSFLAGS     = VSFLAGS_DEBUG + %w(/D_CRT_SECURE_NO_WARNINGS)
    CLANG_FLAGS = CLANG_DEBUG
    GCC_FLAGS   = GCC_DEBUG
  else
    VSFLAGS     = VSFLAGS_RELEASE + %w(/D_CRT_SECURE_NO_WARNINGS)
    CLANG_FLAGS = CLANG_RELEASE + %w(-Wno-comma -Wno-cast-align -Wno-bad-function-cast -Wno-missing-field-initializers -Wno-missing-braces -Wno-format-pedantic -Wno-covered-switch-default -Wno-unused-function -Wno-format-nonliteral -Wno-shadow -Wno-incompatible-pointer-types-discards-qualifiers -Wno-gnu-label-as-value -Wno-cast-qual -Wno-unused-macros -Wno-unreachable-code -Wno-unreachable-code-break -Wno-unused-variable -Wno-missing-noreturn -Wno-unreachable-code-return -Wno-class-varargs -Wno-switch-enum -Wno-conversion -Wno-missing-variable-declarations -Wno-documentation -Wno-documentation-unknown-command -Wno-unused-parameter -Wno-missing-prototypes -Wno-conditional-uninitialized -Wno-double-promotion)
    GCC_FLAGS   = GCC_RELEASE
  end
rescue
  VSFLAGS     = VSFLAGS_RELEASE
  CLANG_FLAGS = CLANG_RELEASE
  GCC_FLAGS   = GCC_RELEASE
end

MRuby::Build.new do |conf|

  #enable_debug

  # Use mrbgems
  # conf.gem 'examples/mrbgems/ruby_extension_example'
  # conf.gem 'examples/mrbgems/c_extension_example' do |g|
  #   g.cc.flags << '-g' # append cflags in this gem
  # end
  # conf.gem 'examples/mrbgems/c_and_ruby_extension_example'
  # conf.gem :github => 'masuidrive/mrbgems-example', :branch => 'master'
  # conf.gem :git => 'git@github.com:masuidrive/mrbgems-example.git', :branch => 'master', :options => '-v'

  # include the default GEMs
  conf.gembox 'default'

  dir_mac   = "#{root}/../../../LibSources/os_mac"
  dir_linux = "#{root}/../../../LibSources/os_linux"
  dir_win   = "#{root}/../../../LibSources/os_win"

  # load specific toolchain settings
  case OS
  when :mac
    ENV['CFLAGS']   = CLANG_FLAGS.inject("") {|acc, e| acc + "#{e} "}
    ENV['CXXFLAGS'] = CLANG_CXX.inject(ENV['CFLAGS']) {|acc, e| acc + "#{e} "}
    toolchain :clang
    conf.cc do |cc|
      cc.flags         = CLANG_FLAGS + ["-Wno-sign-conversion", "-Wno-documentation"];
      cc.include_paths = ["#{root}/include",
                          "#{dir_mac}/include/MechatronixInterfaceMruby",
                          "#{dir_mac}/include/MechatronixCore",
                          "/usr/local/include"]
      cc.defines       = %w(ENABLE_READLINE)
    end
    conf.linker do |linker|
      linker.library_paths << "#{dir_mac}/lib"
      linker.library_paths << '/usr/local/lib'
      #linker.libraries     << ["yaml","pcre","onig"]
    end

  when :linux
    ENV['CFLAGS']   = GCC_FLAGS.inject("") {|acc, e| acc + "#{e} "}
    ENV['CXXFLAGS'] = GCC_CXX.inject(ENV['CFLAGS']) {|acc, e| acc + "#{e} "}
    toolchain :gcc
    conf.cc do |cc|
      cc.flags         = GCC_FLAGS
      cc.include_paths = ["#{root}/include",
                          "#{dir_linux}/include/MechatronixInterfaceMruby",
                          "#{dir_linux}/include/MechatronixCore",
                          "/usr/local/include"]
      cc.defines       = %w(ENABLE_READLINE)
    end
    conf.linker do |linker|
      linker.library_paths << "#{dir_linux}/lib"
      linker.library_paths << '/usr/local/lib'
      #linker.flags_before_libraries = []
      #linker.flags_after_libraries = []
      #linker.libraries = ["m"]
    end

  when :win
    ENV['CFLAGS']   = VSFLAGS.inject("") {|acc, e| acc + "#{e} "}
    ENV['CXXFLAGS'] = ENV['CFLAGS']
    toolchain :visualcpp
    conf.cc do |cc|
      cc.flags = VSFLAGS
      cc.flags << ["/c"]
      cc.include_paths = [
        "#{root}/include",
        "#{dir_win}/include/MechatronixInterfaceMruby",
        "#{dir_win}/include/MechatronixCore"
      ]
    end
    if ENV['DEBUG'] == "yes" then
      suffix = "_vs#{VS_VERSION}_#{VS_ARCH}"
    else
      suffix = "_vs#{VS_VERSION}_#{VS_ARCH}_debug"
    end
    conf.linker do |linker|
      linker.library_paths << "#{dir_win}/lib"
      linker.library_paths << "#{root}/../dummy_libs"
      linker.libraries     << [ "Ws2_32", "Shlwapi", "user32", "kernel32", "shell32", "advapi32",
                                "onig#{suffix}", 
                                #"pcre#{suffix}",
                                "yaml#{suffix}" ]
      if VS_VERSION == '2015' then
        linker.libraries << [ "legacy_stdio_definitions" ]
      end
    end
    conf.yacc do |yacc|
      yacc.command         = 'win_bison.exe'
      yacc.compile_options = '-o %{outfile} %{infile}'
    end
  else
    raise "Unknown platform"
  end

  # Custom gems for Mechatronix. WARNING: inclusion order matters!
  # Gems in mruby build dir (default gems)

  dir = "#{File.dirname(File.expand_path(__FILE__))}"

  conf.gem :core => "mruby-sprintf"
  conf.gem :core => "mruby-print"
  conf.gem :core => 'mruby-io'

  CORE_LIST = [
    "array-ext", "class-ext", "compar-ext", "compiler", "enum-ext", "enum-lazy",
    "enumerator", "error", "eval", "exit", "fiber", "hash-ext", "inline-struct",
    "kernel-ext", "math", "metaprog", "method", "numeric-ext", "object-ext",
    "objectspace", "pack", "proc-ext", "random", "range-ext", "sleep",
    "string-ext", "struct", "symbol-ext", "time", "toplevel-ext"
  ]

  CORE_LIST.each do |g| conf.gem :core => "mruby-"+g end

  conf.gem "#{dir}/mrbgems/pins-mruby-errno"
  conf.gem "#{dir}/mrbgems/pins-mruby-complex"
  conf.gem "#{dir}/mrbgems/pins-mruby-env"
  conf.gem "#{dir}/mrbgems/pins-mruby-tempfile"

  conf.gem "#{dir}/mrbgems/pins-mruby-onig-regexp"
  #conf.gem "#{dir}/mrbgems/pins-mruby-pcre-regexp" # bacata
  conf.gem "#{dir}/mrbgems/pins-mruby-dir"
  conf.gem "#{dir}/mrbgems/pins-mruby-erb"
  conf.gem "#{dir}/mrbgems/pins-mruby-yaml"

  # Gems on local source (in mrbgems)
  conf.gem "#{dir}/mrbgems/mruby-shell"
  conf.gem "#{dir}/mrbgems/mruby-mechatronix"

  # GEMS INCLUDED AFTER mruby-emb-require WILL BE COMPILED AS SEPARATE object
  # AND MUST BE LOADED AS require 'mruby-hs-regexp'
  conf.gem "#{dir}/mrbgems/pins-mruby-require"

end

# Define cross build settings
# MRuby::CrossBuild.new('32bit') do |conf|
#   toolchain :gcc
#
#   conf.cc.flags << "-m32"
#   conf.linker.flags << "-m32"
#
#   conf.build_mrbtest_lib_only
#
#   conf.gem 'examples/mrbgems/c_and_ruby_extension_example'
#
#   conf.test_runner.command = 'env'
#
# end
