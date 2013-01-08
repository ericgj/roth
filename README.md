## Reimplementing Thor::Actions

### A work in progress

This library is an extraction _and reimplementation_ of Thor's file actions and
'shell' -- arguably the most useful functionality that Thor provides, most 
visibly in Rails generators.

### Why is this needed

The functionality provided by [Thor::Actions][thor] has no deep dependency on Thor.
There is no reason to have to subclass Thor (or even install thor at all) in 
order to use it. That was my first thought: given I don't want to use Thor, but 
want to do generator-y things, how simple would it be to just extract it?

As it turns out, it's not too hard. But then... one comes in close range of the
moldering cheese that is Thor::Actions. It's only so long you can leave it in
the back of the fridge, cutting off bits now and then to save it.

Thus, _reimplementation_. I summarize below the main problems.

But first, how to use it.

### How does the interface differ from Thor::Actions?

The main difference is that you compose the object that does the actions, 
instead of mixing in the action methods into your objects.  So

```ruby
class FooGenerator < Thor
  include Thor::Actions
  
  attr_accessor :source_root
  
  def do_it
    inside('app') do
      copy_file 'foo' if yes?('copy foo?')
    end
  end
end
```

becomes

```ruby
class FooGenerator

  attr_accessor :source_root
  
  def gen
    @gen ||= FileActions.from(source_root)
  end
  
  def do_it
    gen.inside('app') do
      gen.copy_file 'foo' if gen.yes?('copy foo?')
    end
  end
```

Of course, you can use delegation to give it the same syntax as before (but 
without the mixin headaches).


### Main problems with Thor::Actions as currently implemented

1. Action methods are dumped into your application classes (commands)
as mixins. Also, whether you use one of them or all 21 or so, you get them all
(how lucky!). This is on top of all the Shell methods which are dumped into
the Thor base class.

2. Worse yet, Thor::Actions itself brings with it a bunch of state (options, 
destination and source directories, etc.) and methods for dealing with that
state.

3. The shell keeps a reference to the command and also vice-versa, coupling them
unnecessarily tightly. 

4. The internal division of responsibilities between Thor::Actions and 
particular actions is not clear and it is leaking encapsulation juice in a number
of places. It's definitely a smell that both Thor::Actions and individual 
actions make filesystem changes. Archeologically speaking (and it's only 
speculation here, no I have not mined the depths of git history), it appears the 
old edifice was never torn down completely when certain improvements were 
introduced.

5. It makes a certain kind of sense to inherit other actions from EmptyDirectory,
the simplest case, but overall I think this is a mistake that leads to 
hard-to-follow code.


[thor]: https://github.com/wycats/thor/blob/master/lib/thor/actions.rb 