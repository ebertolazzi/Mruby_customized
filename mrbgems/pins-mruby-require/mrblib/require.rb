class LoadError < ScriptError; end

module Kernel

  def ___file_search( path, exts )

    raise TypeError unless path.class == String

    filenames = [path]
    if not ( exts.include? File.extname(path) ) then
      exts.each do |e| filenames << path+e end
    end

    path0 = nil
    if ['/', '.'].include? path[0] or ( path =~ /^[A-Za-z]+:/ ) or not $LOAD_PATH
      path0 = filenames.find do |fname| File.file? fname end
    else
      found = false
      path0 = filenames.find do |fname| File.file? fname end
      if path0 then
        found = true
      else
        filenames.find do |fname|
          $LOAD_PATH.each do |dir0|
            path0 = File.join dir0, fname
            found = File.file? path0
            break if found
          end
          break if found
        end
      end
      unless found
        raise LoadError, "cannot load such file (file not found) -- #{path} (in dirs #{filenames}')"
      end
    end

    unless path0
      raise LoadError, "cannot load such file (bad path) -- #{path} (resolved in '#{path0}')"
    end

    unless File.file?(path0)
      raise LoadError, "cannot load such file (file not found) -- #{path} (resolved in '#{path0}')"
    end

    return File.realpath(path0)
  end

  def load(path)
    raise TypeError unless path.class == String

    # require method can load .rb, .mrb or without-ext filename only.
    realpath = ___file_search( path,  [ ".rb", ".mrb", ".so", ".dylib", ".dll"] )

    if File.extname(realpath) == ".mrb"
      ___load_mrb_file realpath
    elsif File.extname(realpath) == ".rb"
      ___load_rb_str File.open(realpath).read.to_s, realpath
    else
      ___load_shared_file realpath
    end

    true
  end

  def require(path)
    raise TypeError unless path.class == String

    # require method can load .rb, .mrb or without-ext filename only.
    realpath = ___file_search( path,  [".rb", ".mrb"] )

    # already required
    return false if ($" + $__mruby_loading_files__).include?(realpath)

    $__mruby_loading_files__ << realpath
    if File.extname(realpath) == ".mrb"
      ___load_mrb_file realpath
    else
      ___load_rb_str File.open(realpath).read.to_s, realpath
    end
    $" << realpath
    $__mruby_loading_files__.delete realpath

    true
  end

  # Require a ruby script at the given path, which is relative to
  # the caller file.
  # @example Require a file in this same directory:
  #   require_relative("to_be_loaded.rb", __FILE__)
  # @param rel_path [String] Relative path of file to be loaded
  # @param file [String] File or path defining the search start. Default to ".".
  # @return [Bool] Result of the underlying call to `require`
  def require_relative( rel_path, file )
    require File.expand_path(File.dirname(file)).gsub(/[\\\/]+$/, '') + "/" + rel_path
  end

end

$LOAD_PATH ||= []
$LOAD_PATH << '.'
if Object.const_defined?(:ENV)
  $LOAD_PATH.unshift(*ENV['MRBLIB'].split(':')) unless ENV['MRBLIB'].nil?
end
$LOAD_PATH.uniq!

$"                       ||= []
$__mruby_loading_files__ ||= []
