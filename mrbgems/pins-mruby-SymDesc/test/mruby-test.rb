class Float
	alias :to_r :to_f
end
#class Integer
#	alias :to_r :to_f
#end

require_relative "../lib/SymDesc.rb", __FILE__

Test = MTest
include SymDesc
%w| ./test-Int.rb
    ./test-Neg.rb
    ./test-Sum.rb|.each { |f| require_relative f, __FILE__ }
MTest::Unit.new.run