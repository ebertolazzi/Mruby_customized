module Mechatronix

  # Data structure, as {Mechatronix::Container}
  @@content = nil

  # See the `mechatronix` function in top level namespace for a shortcut.
  # @param v [Mechatronix::Container]
  def self.content=(v)
    @@content = v
  end

  # See the `mechatronix` function in top level namespace for a shortcut.
  # @return [Mechatronix::Container]
  def self.content
    @@content
  end

  SET  = true
  FREE = false

  case RUBY_PLATFORM
  when /darwin/
    DYLIB_EXT = "dylib"
  when /mswin/
    DYLIB_EXT = "dll"
  when /linux/
    DYLIB_EXT = "so"
  end

  class Solver
    # Create a new solver instance.
    # @param dylib_path [String] path to the problem dynamic library
    # @param data [Mechatronix::Container] data structure (default to Mechatronix.content)
    # @param silent [Bool] suppress output
    def initialize(dylib_path, data=nil, silent=true)
      @silent = silent
      @dylib_path = (dylib_path.match(/^\.\//) ? '' : './') + dylib_path
      # raise ArgumentError, "Missing library #{lib_path}" unless File.exist? @dylib_path
      @model_name = File.basename(@dylib_path).match(/^(lib){0,1}(\w+)(\.\w+){0,1}$/)[2]
      @id         = self.__id__.to_s
      @data       = (data || Mechatronix.content)
      if File.exist? @dylib_path
        puts "load dynamic library: #{@dylib_path}"
        load @dylib_path
      else
        puts "missing dynamic library: #{@dylib_path}"
      end
    end
  end

  # Hook class for Optimal Control Problem solver
  class OCPSolver < Solver

    # data structure, a Hash
    attr_accessor :data
    # au univoque instance ID, automatically set
    attr_reader   :id
    # the model name, default to project name extracted by the problem dynamic library
    attr_reader :model_name
    # path of the problem dynamic library
    attr_reader :dylib_path


    # Object containing the whole solution (a Hash corresponding to the
    # internal GenericContainer)
    attr_reader :ocp_solution

    # Setup the solver and prepares for {OCPSolver#solve}.
    # @return [String|False] the setup output, or false in case of error
    # @!method setup()

    # Computes solution.
    # @return [Hash] returns the complete solution, also available in `@ocp_solution`
    # @!method solve()

    # Dump solution to file, directly using the underlying C++ method.
    # @note the {OCPSolver#write_ocp_solution} provides greater flexibility and its use
    #   is encouraged.
    # @param filename [String] path to the file to be created
    # @!method write(filename)

    # The length (number of points) of the returned solution.
    # @return [Fixnum] number of points in solution
    def length; @ocp_solution[:data][0].length; end

    # Returns a partial selection of the solution, according to an Array of
    # column names
    # @param ary [Array<Symbol>] an Array of column names (as Symbols)
    # @param sep [String] the column separator
    # @return [String] a partial solution table
    def partial_table(ary, sep=',')
      indexes = []
      res = ""
      ary.each_with_index do |field, i|
        idx = @ocp_solution[:headers].find_index(field)
        if idx then
          indexes << idx
        else
          ary.delete_at i
        end
      end
      res << ary.join(sep) + "\n"
      self.length.times do |i|
        res << indexes.inject([]) {|a,e| a << @ocp_solution[:data][e][i] }.join(sep) + "\n"
      end
      return res
    end

    # Writes the OCP solution to a file in YAML format.
    # @param filename [String] path of the output file to be written
    def save_solution(filename)
      raise ArgumentError, "Argument must be a file name" unless filename.kind_of? String
      File.open(filename, 'w') { |file| YAML.dump(@ocp_solution, file) }
    end

    # Loads a previously calculated OCP solution from a YAML file.
    # @param filename [String] path of the output file to be loaded
    def load_solution(filename)
      raise ArgumentError, "Argument must be a file name" unless filename.kind_of? String
      raise ArgumentError, "Only YAML format is supported" unless filename.match(/\.(yaml|yml)$/i)
      @ocp_solution = File.open(filename) { |file| YAML.load(file) }
    end
  end # class OCPSolver


  # Hook class for Dynamical Systems solver
  class DSSolver < Solver
    attr_reader :stationary_solution, :ode_solution

    # Setup the solver and prepares for {DSSolver#solve_stationary} or {DSSolver#solve_ODE}.
    # @return [String|False] the setup output, or false in case of error
    # @!method setup()

    # Computes solution.
    # @return [Hash] returns the complete stationary solution, also available in `@ds_solution`
    # @!method solve_stationary()

    # Initialize ODE solution.
    # @!method init_ODE()

    # Make a single step for the ODE solution
    # @!method step_ODE()

    # Solve the ODE problem
    # @!method solve_ODE()

    # Returns the initial condition as solution of the stationary problem.
    # @return [Hash] the solution
    # @!method get_initial_condition()

    # Writes the DS stationary solution to a file, as a space separated table
    # with column names in the first line. The file begins with an initial
    # comment line containing the present date and the library version.
    # @param filename [String] path of the output file to be written
    # @param desc [String] optional description appended to the initial comment
    def write_steady_state(filename, desc="")
      now = Time.now
      File.open(filename, 'w') do |f|
        f.puts "# #{@model_name} Eigenvalues synthetic analysis - #{now} - MX Version: #{MECHATRONIX[:description]}"
        f.puts comment(desc)
        @stationary_solution[:control_names].each { |name| f.print name+"\t" }
        @stationary_solution[:state_names].each { |name| f.print name+"\t" }
        f.puts
        @stationary_solution[:controls].each { |v| f.print "#{v}\t" }
        @stationary_solution[:states].each { |v| f.print "#{v}\t" }
        f.puts
      end
    end

    # Writes the DS eigenvalues to a file, as a space separated table
    # with column names in the first line. The file begins with an initial
    # comment line containing the present date and the library version.
    # @param filename [String] path of the output file to be written
    # @param desc [String] optional description appended to the initial comment
    def write_eigenvalues(filename, desc="")
      now = Time.now
      ssa = @stationary_solution[:steady_state_analysis]
      File.open(filename, 'w') do |f|
        f.puts "# #{@model_name} Eigenvalues synthetic analysis - #{now} - MX Version: #{MECHATRONIX[:description]}"
        f.puts comment(desc)
        f.puts "real\timag\tmag\tphase\n"
        ssa[:eigenvalues].each do |r|
          f.puts "#{r.real}\t#{r.imag}\t#{r.abs}\t#{r.phase}\n"
        end
      end
    end

    # Writes the DS igenvectors to a file, as a space separated table
    # with column names in the first line. The file begins with an initial
    # comment line containing the present date and the library version.
    # @param filename [String] path of the output file to be written
    # @param desc [String] optional description appended to the initial comment
    def write_left_eigenvectors(filename, desc="")
      now = Time.now
      ssa = @stationary_solution[:steady_state_analysis]
      n   = ssa[:eigenvectors_left].length
      File.open(filename, 'w') do |f|
        f.puts "# #{@model_name} Left Eigenvectors table - #{now} - MX Version: #{MECHATRONIX[:description]}"
        f.puts comment(desc)
        #-----------------------------------------------
        @stationary_solution[:state_names].each { |name| f.print "#{name}_real\t#{name}_imag\t" }
        f.puts
        ssa[:eigenvectors_left].each do |eig|
          eig.each do |v|
            f.print "#{v.real}\t#{v.imag}\t"
          end
          f.puts
        end
      end
    end

    # Writes the DS igenvectors to a file, as a space separated table
    # with column names in the first line. The file begins with an initial
    # comment line containing the present date and the library version.
    # @param filename [String] path of the output file to be written
    # @param desc [String] optional description appended to the initial comment
    def write_right_eigenvectors(filename, desc="")
      now = Time.now
      ssa = @stationary_solution[:steady_state_analysis]
      n   = ssa[:eigenvectors_right].length
      File.open(filename, 'w') do |f|
        f.puts "# #{@model_name} Right Eigenvectors table - #{now} - MX Version: #{MECHATRONIX[:description]}"
        f.puts comment(desc)
        #-----------------------------------------------
        @stationary_solution[:state_names].each { |name| f.print "#{name}_real\t#{name}_imag\t" }
        f.puts
        ssa[:eigenvectors_right].each do |eig|
          eig.each do |v|
            f.print "#{v.real}\t#{v.imag}\t"
          end
          f.puts
        end
      end
    end

    # Writes the DS ODE solution to a file, as a space separated table
    # with column names in the first line. The file begins with an initial
    # comment line containing the present date and the library version.
    # @param filename [String] path of the output file to be written
    # @param desc [String] optional description appended to the initial comment
    def write_ode_solution(filename, desc="")
      now=Time.now
      # Prepare headers
      comment = "# #{@model_name} forward integration analysis - #{now} - MX Version: #{MECHATRONIX[:description]}"
      File.open(filename, 'w') do |f|
        f.puts comment(desc)
        f.puts @ode_solution[:headers].join("\t")
        @ode_solution[:data][0].length.times do |r|
          f.puts @ode_solution[:data].inject([]) {|a,c| a << c[r]}.join("\t")
        end
      end

    end

    private
    def comment(desc="")
      ssa = @stationary_solution[:steady_state_analysis]
      if desc.length > 0 then
        comment = "# #{desc.chomp.gsub(/\n/, "\n# ")}"
      else
        comment = ""
      end
      comment << "# One-norm of balance matrix A: #{ssa[:one_norm_bal_matrix_A]}\n"
      comment << "# One-norm of balance matrix B: #{ssa[:one_norm_bal_matrix_B]}\n"
      %i| state_names states states_guess controls controls_guess |.each do |k|
        comment << "# #{k.to_s}: ".ljust(20)
        comment << @stationary_solution[k].join("\t") + "\n"
      end
      return comment
    end

  end #class DSSolver
end



# Convenience method for setting problem data into the `Mechatronix.content`
# instance of {Mechatronix::Container}.
# @example Simple example:
#   mechatronix("My Model") do |data|
#     data.LU_method = LU_automatic
#   end
# @example which is a shortcut to:
#   Mechatronix.content = Mechatronix::Container.new("My Model")
#   Mechatronix.content.LU_method = LU_automatic
# @param name [String] optional name of container
# @yield [data] a block
# @yieldparam [Mechatronix::Container] a pointer to the container
def self.mechatronix(name=nil, &block)
  unless (Mechatronix.content && Mechatronix.content.kind_of?(Mechatronix::Container)) then
    Mechatronix.content = Mechatronix::Container.new(name)
  end
  yield Mechatronix.content
end
