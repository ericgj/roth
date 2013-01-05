class CreateFile

  attr_accessor :base, :config, :relative_destination

  def initialize(base, destination, data, config={})
    @base, @config = base, {:verbose => true}.merge(base.options).merge(config)
    @relative_destination = destination
    @data = data
  end
  
  def invoke!
    ::FileUtils.mkdir_p(File.dirname(destination))
    ::File.open(destination, 'wb') { |f| f.write render }  
  end
  
  def revoke!
    ::FileUtils.rm_fr(destination) if exists?
  end
  
  def conflict?
    exists?
  end
  
  def identical?
    exists? && File.binread(destination) == render
  end
  
  def exists?
    ::File.exists?(destination)  
  end
  
  def handle_conflict(cancel=false)
    if identical?
      say_status :identical, :blue
      cancel = true
    else
      force_or_skip_or_prompt(force?, false, cancel)
    end
  end
  
  def destination
    ::File.expand_path(relative_destination, base.current_destination)
  end

  def verbose?
   !!config[:verbose]
  end

  def force?
    !!config[:force]
  end
  
  private

  # demeter issue but does it matter enough?
  def say_status(status, color)
    base.shell.say_status(status, relative_destination, color) if verbose?
  end
  
  def render
    @render ||= if data.respond_to?(:call)
      data.call
    else
      data
    end
  end  
  
  def force_or_skip_or_prompt(force, skip, cancel)
    if force
      say_status :force, :yellow
    elsif skip
      say_status :skip, :yellow
      cancel = true
    else
      say_status :conflict, :red
      force_or_skip_or_prompt(force_on_collision?, true, cancel)
    end      
  end
  
  # demeter
  # also, not clear what #file_collision intends to return
  def force_on_collision?
    base.shell.file_collision(destination){ render }
  end
  
end
