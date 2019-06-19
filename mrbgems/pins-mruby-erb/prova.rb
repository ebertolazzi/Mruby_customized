require './mrblib/erb.rb'

str               = IO.read( 'prova.tmpl' );
template          = ERB.new( str, nil, '-' )
template.filename = File.basename('prova.tmpl')
res               = template.result()
puts res
