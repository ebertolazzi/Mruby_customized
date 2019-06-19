##
# Mechatronix Test

assert("Mechatronix::OCPSolver\#new") do
  s = Mechatronix::OCPSolver.new(__FILE__, nil, true)
  assert_equal(s.model_name.dup, s.solve)
end


##
# Classes extensions
assert("Array\#[] (Range +)") do
  a = (0..10).to_a
  assert_equal(a[0..3], [0,1,2,3])
end

assert("Array\#[] (Range -)") do
  a = (0..10).to_a
  assert_equal(a[0..-1], a)
end

assert("Array\#[] (slice)") do
  a = (0..10).to_a
  assert_equal(a[0,3], [0,1,2])
end

assert("String\#ljust") do
  assert_equal("10 chars".ljust(10), "10 chars  ")
end

