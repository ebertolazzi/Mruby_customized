#  __  __    _    ____ _____ _____ ____    ____       _         __ _ _
# |  \/  |  / \  / ___|_   _| ____|  _ \  |  _ \ __ _| | _____ / _(_) | ___
# | |\/| | / _ \ \___ \ | | |  _| | |_) | | |_) / _` | |/ / _ \ |_| | |/ _ \
# | |  | |/ ___ \ ___) || | | |___|  _ <  |  _ < (_| |   <  __/  _| | |  __/
# |_|  |_/_/   \_\____/ |_| |_____|_| \_\ |_| \_\__,_|_|\_\___|_| |_|_|\___|
#
# encoding: utf-8
#
require "./common.rb"

class RetryAfterUpdateError < Exception; end

#########
# GLOBALS
#########
ROOT_DIR      = File.expand_path('../', __FILE__)
MRUBY_DOC_DIR = "mruby_doc"

############
# FILE LISTS
############
#CLEAN.include   []
#CLOBBER.include [MRUBY_DOC_DIR]

require File.expand_path('../Rakefile_get_os', __FILE__)

#    _ __ ___   ___  ___ ___  __ _  __ _  ___
#   | '_ ` _ \ / _ \/ __/ __|/ _` |/ _` |/ _ \
#   | | | | | |  __/\__ \__ \ (_| | (_| |  __/
#   |_| |_| |_|\___||___/___/\__,_|\__, |\___|
#                                  |___/
def message(msg, ok=true)
  puts
  if ok then
    puts "> #{msg}".green
  else
    n = msg.length + 2
    s = "> Bummer! something gone wrong!"
    l = '-' * [s.length, 80].min
    warn "#{l}\n#{s}\n#{l}\n".red
  end
end

verbose(false)

#  __  __            _
# |  \/  |_ __ _   _| |__  _   _
# | |\/| | '__| | | | '_ \| | | |
# | |  | | |  | |_| | |_) | |_| |
# |_|  |_|_|   \__,_|_.__/ \__, |
#                          |___/
#
desc "Build the mruby library from clean state"
task :mruby  => 'mruby:make' # default action

task :cleanup_submodules do
  branches = YAML.load_file("./sub_branches.yaml")
  sh "git submodule init"
  sh "git submodule sync"
  sh "git submodule update"
  branches.each do |dir, branch|
    puts "\n\nChecking out branch #{branch} in #{dir}".bold.yellow
    sh "(cd #{dir} && git reset --hard && git checkout #{branch})"
  end
  #sh "git pull --recurse-submodules"
end

namespace :mruby do

  # mruby config file is here:
  build_config = File.expand_path("../mruby_build_config.rb", __FILE__)
  warn "Using mruby config in #{build_config}".bold.yellow

  case OS
  when :win
    destination = "../../LibSources/os_win/"
    base_cmd    = "set MRUBY_CONFIG=#{build_config} & ruby minirake "
  when :linux
    destination = "../../LibSources/os_linux/"
    base_cmd    = "export MRUBY_CONFIG=#{build_config}; ./minirake "
  when :mac
    destination = "../../LibSources/os_mac/"
    base_cmd    = "export MRUBY_CONFIG=#{build_config}; ./minirake "
  end

  desc "Deep clean the mruby library"
  task :deepclean do
    cd("mruby") do
      sh "#{base_cmd} deep_clean" do |ok|
        message "Successfully built mruby lib from clean state", ok
      end
    end
  end

  desc "Clean the mruby library"
  task :clean do
    cd("mruby") do
      sh "#{base_cmd} clean" do |ok|
        message "Successfully clean mruby", ok
      end
    end
  end

  desc "Clean the mruby library AND the gems sources"
  task :gemclean do
    cd("mruby") do
      rm_rf "build/mrbgems"
      sh "#{base_cmd} clean" do |ok|
        message "Successfully clean mruby and gems sources", ok
      end
    end
  end

  desc "Build the mruby library"
  task :make do
    cd("mruby") do
      sh "#{base_cmd}" do |ok|
        message "Successfully built mruby lib", ok
      end
    end
  end

  #
  # filtro per cambiare il cervellotico modo di accedere agli header di Matz
  #
  def copy_filter(to)
    puts "coping in #{to}mruby\n"
    begin
      Dir.mkdir(to+"mruby")
    rescue
    end
    file_names = Dir["mruby/include/mruby/*.h"]
    file_names.each do |file_name|
      text = File.read(file_name)
      text.gsub!(/#include \<mruby\/([^\>]+)\>/) { "#include \"#{$1}\"" }
      text.gsub!(/#include \<mruby.h\>/, '#include "../mruby.h"')
      # To write changes to the file, use:
      File.open(to+file_name[14..-1], "w") {|file| file.puts text }
    end
    file_names = Dir["mruby/include/*.h"]
    file_names.each do |file_name|
      text = File.read("mruby/include/mruby.h")
      text.gsub!(/#include \<mruby\/([^\>]+)\>/) { "#include \"mruby/#{$1}\"" }
      # To write changes to the file, use:
      File.open(to+file_name[14..-1], "w") {|file| file.puts text }
    end
  end

  desc "Copy the mruby headers"
  task :copyheaders do
    FileUtils.mkdir_p "#{destination}/include/MechatronixInterfaceMruby/"
    copy_filter("#{destination}/include/MechatronixInterfaceMruby/")
  end

  desc "Copy the mruby library"
  task :copylib do
    FileUtils.mkdir_p "#{destination}/bin"
    FileUtils.mkdir_p "#{destination}/lib"
    FileUtils.cp   Dir['mruby/build/host/lib/libmruby*.*'], "#{destination}/lib"
    FileUtils.cp_r Dir['mruby/build/host/bin/*'],           "#{destination}/bin"
  end

  desc "Copy the mruby library"
  task :copylib_win, [:year,:bits] do |t, args|
    args.with_defaults( :year => "2017", :bits => "x64" )

    FileUtils.mkdir_p "#{destination}/bin"
    FileUtils.mkdir_p "#{destination}/lib"

    # workaround?
    postfix = "vs#{args.year}_#{args.bits}"
    postfix += "_debug" if ENV['DEBUG'] == "yes"

    FileUtils.cp 'mruby/build/host/bin/mrbc.exe',          "#{destination}/bin/mrbc.exe"

    FileUtils.cp 'mruby/build/host/lib/libmruby.lib',      "#{destination}/lib/mruby_#{postfix}.lib"
    FileUtils.cp 'mruby/build/host/lib/libmruby_core.lib', "#{destination}/lib/mruby_core_#{postfix}.lib"

    FileUtils.cp 'mruby/build/host/bin/mirb.exe',          "#{destination}/bin/mirb_#{postfix}.exe"
    FileUtils.cp 'mruby/build/host/bin/mrbc.exe',          "#{destination}/bin/mrbc_#{postfix}.exe"
    FileUtils.cp 'mruby/build/host/bin/mruby.exe',         "#{destination}/bin/mruby_#{postfix}.exe"
    FileUtils.cp 'mruby/build/host/bin/mruby-strip.exe',   "#{destination}/bin/mruby-strip_#{postfix}.exe"
  end

  desc "Build mruby documentation in mruby_doc"
  YARD::Rake::YardocTask.new do |t|
    puts "Generating docs in mruby_doc".green
    t.files = [
      "mrblib/*.rb",
      "mrbgems/**/mrblib/*.rb",
      "-", # Extra files hereafter,
      "DATA_FILES.md"
    ]
    t.options  = %w|--no-cache --no-private --markup markdown|
    t.options << "--query=@api.text != 'private'"
    t.options << "--output-dir=mruby_doc"
    t.options << "--readme=README.md"
    if OS == :mac
      t.after = Proc.new { sh "open mruby_doc/index.html" }
    end
  end

end

##############
# DEFAULT TASK
##############
task :default => [:mruby]
