#
#
#
%w(rake/clean colorize fileutils yard yaml pathname rubygems/package net/http zip zlib uri openssl).each do |gem|
  begin
    require gem
  rescue LoadError
    warn "Install the #{gem} gem:\n $ (sudo) gem install #{gem}".magenta
    exit 1
  end
end

#
# https://stackoverflow.com/questions/6934185/ruby-net-http-following-redirects/6934503
#
def url_resolve( uri_str,
                 agent        = 'curl/7.43.0',
                 max_attempts = 10,
                 timeout      = 10 )
  attempts = 0
  cookie   = nil

  until attempts >= max_attempts
    attempts += 1

    url  = URI.parse(uri_str)
    http = Net::HTTP.new(url.host, url.port)
    http.open_timeout = timeout
    http.read_timeout = timeout
    path = url.path
    path = '/' if path == ''
    path += '?' + url.query unless url.query.nil?

    params = { 'User-Agent' => agent, 'Accept' => '*/*' }
    params['Cookie'] = cookie unless cookie.nil?
    request = Net::HTTP::Get.new(path, params)

    if url.instance_of?(URI::HTTPS)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    response = http.request(request)

    case response
    when Net::HTTPSuccess then
      break
    when Net::HTTPRedirection then
      location = response['Location']
      cookie   = response['Set-Cookie']
      new_uri  = URI.parse(location)
      uri_str  = if new_uri.relative? then url + location else new_uri.to_s end
    else
      raise 'Unexpected response: ' + response.inspect
    end
  end
  raise 'Too many http redirects' if attempts == max_attempts
  uri_str
  # response.body
end

def url_download( url_address, filename )
  if File.exist?(filename)
    puts "file: `#{filename}` already downloaded"
  else
    puts "downloading: `#{filename}`..."
    uri_str = url_resolve(url_address)
    uri     = URI( uri_str )
    File.binwrite( filename, Net::HTTP.get(uri) )
    puts "done"
  end
end

#
# https://stackoverflow.com/questions/856891/unzip-zip-tar-tag-gz-files-with-ruby
#
TAR_LONGLINK = '././@LongLink'
def extract_tgz( tar_gz_archive, destination = '.' )
  puts "extracton of tgz file: `#{tar_gz_archive}` ..."
  Gem::Package::TarReader.new( Zlib::GzipReader.open tar_gz_archive ) do |tar|
    dest = nil
    tar.each do |entry|
      if entry.full_name == TAR_LONGLINK
        dest = File.join destination, entry.read.strip
        next
      end
      dest ||= File.join destination, entry.full_name
      if entry.directory?
        File.delete dest if File.file? dest
        FileUtils.mkdir_p dest, :mode => entry.header.mode, :verbose => false
      elsif entry.file?
        FileUtils.rm_rf dest if File.directory? dest
        FileUtils.mkdir_p File.dirname(dest), :mode => 0777, :verbose => false
        File.open dest, "wb" do |f|
          f.print entry.read
        end
        FileUtils.chmod entry.header.mode, dest, :verbose => false
      elsif entry.header.typeflag == '2' #Symlink!
        File.symlink entry.header.linkname, dest
      end
      dest = nil
    end
  end
  puts "done"
end

#
# https://stackoverflow.com/questions/19754883/how-to-unzip-a-zip-file-containing-folders-and-files-in-rails-while-keeping-the
#
def extract_zip( filename, destination_path='.' )
  puts "extracton of zip file: `#{filename}`..."
  Zip::ZipFile.open(filename) do |zip_file|
    zip_file.each do |f|
      f_path=File.join(destination_path, f.name)
      FileUtils.mkdir_p(File.dirname(f_path))
      zip_file.extract(f, f_path) unless File.exist?(f_path)
    end
  end
  puts "done"
end

def ChangeOnFile(file, text_to_replace, text_to_put_in_place)
  text= File.read file
  File.open(file, 'w+'){|f| f << text.gsub(text_to_replace, text_to_put_in_place)}
end

def cmake_build( year, bits, lib_dir, src_dir )
  dir = "vs_#{year}_#{bits}"
  FileUtils.rm_rf dir
  FileUtils.mkdir dir
  FileUtils.cd    dir
  tmp = ' -DCMAKE_INSTALL_PREFIX:PATH=' + lib_dir + '  ' + src_dir

  win32_64 = ''
  case bits
  when /x64/
    win32_64 = ' Win64'
  end

  case year
  when "2010"
    sh 'cmake -G "Visual Studio 10 2010' + win32_64 +'" ' + tmp
  when "2012"
    sh 'cmake -G "Visual Studio 11 2012' + win32_64 +'" ' + tmp
  when "2013"
    sh 'cmake -G "Visual Studio 12 2013' + win32_64 +'" ' + tmp
  when "2015"
    sh 'cmake -G "Visual Studio 14 2015' + win32_64 +'" ' + tmp
  when "2017"
    sh 'cmake -G "Visual Studio 15 2017' + win32_64 +'" ' + tmp
  else
    puts "Visual Studio year #{year} not supported!\n";
  end
  sh 'cmake --build . --config Debug --target install'
  FileUtils.rm_rf lib_dir+'_debug'
  FileUtils.mv    lib_dir, lib_dir+'_debug'
  FileUtils.rm_rf lib_dir
  sh 'cmake --build . --config Release  --target install'
  FileUtils.cd '..'
end
