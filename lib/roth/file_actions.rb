require_relative 'action'
%w[ basic color ].each do |f|
  require_relative "shell/#{f}"
end
%w[ empty_directory create_file ].each do |f|
  require_relative "actions/#{f}"
end

class FileActions

  FileActionError   = Class.new(StandardError)
  FileNotFoundError = Class.new(FileActionError)
  
  attr_accessor :shell, :config
  
  def pretend?
    !!config[:pretend]
  end
  
  def revoke?
    !!config[:revoke]
  end
  
  def verbose?
    !!config[:verbose]
  end
  
  def root_destination
    destination_stack.first
  end
  
  def current_destination
    destination_stack.last
  end
  
  def current_relative_destination(remove_dot=true)
    if path = current_destination.gsub(root_destination, '.')
      remove_dot ? (path[2..-1] || '') : path
    else
      path
    end    
  end
  
  def default_shell
    Shell::Color
  end
  
  def initialize(dest=Dir.pwd, sources=[], config={})
    @destination_stack = [dest]
    @sources = Array(sources)
    self.shell   = config.delete(:shell) || default_shell.new
    self.config = config
  end

  def inside(dir, opts={})
    verbose = opts.fetch(:verbose, verbose?)
    shell.say_status :inside, dir, verbose
    shell.padding += 1 if verbose
    push_destination dir
    yield
  ensure
    shell.padding -= 1 if verbose
    pop_destination
  end
  
  def in_root(opts={})
    inside(root_destination, opts) { yield }
  end
  
  def add_source(dir)
    sources.push dir
  end
  
  def find_in_source_paths(file)                    
    sources.each do |source|
      source_file = File.expand_path(
                      file, 
                      File.join(source, current_relative_destination(false))
                    )
      return source_file if File.exists?(source_file)
    end

    message = ["Could not find #{file.inspect} in any of your source paths. "]

    if sources.empty?
      message << "Currently you have no source paths."
    else
      message << "Your current source paths are: \n#{sources.join("\n")}"
    end

    raise FileNotFoundError, message.join("\n")
  end
    
  #----- Actions
  
  def empty_directory(path, options={})
    instance = EmptyDirectory.new(self, path, options)
    action instance
  end
  
  def create_file(path, data=nil, options={}, &data_proc)
    data ||= data_proc
    instance = CreateFile.new(self, path, data, options)
    action instance
  end
  
  def action(a)
    if revoke? 
      a.revoke!
    else
      a.invoke!
    end
  end    
  
  private
  
  attr_reader :destination_stack, :sources
  
  def push_destination(dir='')
    destination_stack.push ::File.expand_path(dir, current_destination)
  end
  
  def pop_destination
    destination_stack.pop
  end
    
end
