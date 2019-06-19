class Dir

  # class_method
  # delete
  # exist?
  # getwd
  # mkdir
  # _chdir
  # chroot
  #
  # methods
  # close
  # initialize
  # read
  # rewind
  # seek
  # tell

  def each(&block)
    while s = self.read
      block.call(s)
    end
    self
  end

  alias pos tell
  alias pos= seek

  def self.entries(path)
    a = []
    self.open(path) do |d|
      while s = d.read
        a << s
      end
    end
    a
  end

  def self.foreach(path, &block)
    if block
      self.open(path).each { |f| block.call(f) }
    else
      self.open(path).each
    end
  end

  def self.open(path, &block)
    if block
      d = self.new(path)
      begin
        block.call(d)
      ensure
        d.close
      end
    else
      self.new(path)
    end
  end

  def self.chdir(path, &block)
    my = self # workaround for https://github.com/mruby/mruby/issues/1579
    if block
      wd = self.getwd
      begin
        self._chdir(path)
        block.call(path)
      ensure
        my._chdir(wd)
      end
    else
      self._chdir(path)
    end
  end

  # Search for any entry in path that matches a regular expression, and yields
  # it to the passed block.
  # @example List only ruby files:
  #   Dir.find(/\.rb$/) do |item|
  #     puts item
  #   end
  # @param path [String] starting folder
  # @param rx   [RegExp] regular expression
  # @yield [name] block to be executed on name
  # @yieldparam [String] current filename
  def self.find( path, rx, &block )
    list = []
    self.foreach(path) do |e|
      name = "#{path}/#{e}"
      if (File.directory?(name) && ! /\.{1,2}$/.match(name) ) then
        list += self.find(name, rx, &block)
      end
      if rx.match e then
        block.call(name) if block
        list << name 
      end
    end
    return list
  end
  #
  # ---------------------------------------------------------------------------
  #
  def self.mkdir_p( dir )
    dirs = dir.split("/")
    path = ""
    dirs.each do |d|
      path += "#{d}"
      if not self.exist? path then
        begin
          self.mkdir(path)
        rescue
        end
      end
      path += "/"
    end
  end

  class << self
    alias exists? exist?
    alias pwd     getwd
    alias rmdir   delete
    alias unlink  delete
  end

end
