class EmptyDirectory

  attr_accessor :base, :config, :relative_destination

  def initialize(base, destination, config={})
    @base, @config = base, {:verbose => true}.merge(config)
    @relative_destination = destination
  end

  def invoke!
    ::FileUtils.mkdir_p(destination)
  end

  def revoke!
    ::FileUtils.rm_fr(destination) if exists?
  end

  def conflict?
    exists?
  end

  def exists?
    ::File.exists?(destination)
  end

  def handle_conflict(cancel=false)
    say_status :exist, :blue
  end
  
  def before_invoke
    say_status :create, :green
  end

  def destination
    ::File.expand_path(relative_destination, base.current_destination)
  end

  def verbose?
   !!config[:verbose]
  end

  private

  # demeter issue but does it matter enough?
  def say_status(status, color)
    base.shell.say_status(status, relative_destination, color) if verbose?
  end

end

