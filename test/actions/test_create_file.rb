require_relative '../test_helper'
require_relative '../../lib/roth/file_actions'

require 'stringio'

describe Actions::CreateFile do
  include TestHelpers
  
  def reset
    ::FileUtils.rm_rf(destination_root)
  end

  def create_file(destination=nil, config={}, options={})
    @base = FileActions.new(destination_root, [], 
                            {:shell => Shell::Basic.new}.merge(options)
                           )
    @action = Actions::CreateFile.new(@base, destination, "SAMPLE DATA", config)
  end

  def invoke!
    capture(:stdout){ @action.invoke! }
  end

  def invoke_stderr!
    capture(:stderr){ @action.invoke! }
  end
  
  def revoke!
    capture(:stdout){ @action.revoke! }
  end
  
  describe "#invoke!" do
    before { reset }
    
    it "creates a file" do
      create_file("doc/config.rb")
      invoke!
      assert File.exists?(File.join(destination_root, "doc/config.rb"))
    end

    it "does not create a file if pretending" do
      create_file("doc/config.rb", {}, :pretend => true)
      invoke!
      refute File.exists?(File.join(destination_root, "doc/config.rb"))
    end

    it "shows created status to the user" do
      create_file("doc/config.rb")
      assert_equal "      create  doc/config.rb\n", invoke!
    end

    it "does not show any information if not verbose" do
      create_file("doc/config.rb", :verbose => false)
      assert_empty invoke!
    end

    describe "when file exists" do

      describe "and is identical" do
        before do
          reset
          create_file("doc/config.rb")
          invoke!
        end

        it "shows identical status" do
          create_file("doc/config.rb")
          invoke!
          assert_equal "   identical  doc/config.rb\n", invoke!
        end
      end

      describe "and is not identical" do
        before do
          reset
          create_file("doc/config.rb")
          invoke!          
          File.open(File.join(destination_root, 'doc/config.rb'), 'w') do |f| 
            f.write("FOO = 3")
          end
        end

        it "shows forced status to the user if force is given" do
          refute create_file("doc/config.rb", {}, :force => true).identical?
          assert_equal "       force  doc/config.rb\n", invoke!
        end

        it "shows skipped status to the user if skip is given" do
          refute create_file("doc/config.rb", {}, :skip => true).identical?
          assert_equal "        skip  doc/config.rb\n", invoke!
        end

        it "shows forced status to the user if force is configured" do
          refute create_file("doc/config.rb", :force => true).identical?
          assert_equal "       force  doc/config.rb\n", invoke!
        end

        it "shows skipped status to the user if skip is configured" do
          refute create_file("doc/config.rb", :skip => true).identical?
          assert_equal "        skip  doc/config.rb\n", invoke!
        end

        it "shows conflict status to the user" do
          refute create_file("doc/config.rb").identical?
          file = File.join(destination_root, 'doc/config.rb')
          content = nil
          $stdin.stub(:gets,'s') do
            content = invoke!
          end
          assert_match(/conflict  doc\/config\.rb/, content)
          assert_match(/Overwrite #{file}\? \(enter "h" for help\) \[Ynaqdh\]/, content)
          assert_match(/skip  doc\/config\.rb/, content)
        end

        it "creates the file if the file collision menu returns true" do
          create_file("doc/config.rb")
          $stdin.stub(:gets,'y') do
            assert_match(/force  doc\/config\.rb/, invoke!)
          end
        end

        it "skips the file if the file collision menu returns false" do
          create_file("doc/config.rb")
          $stdin.stub(:gets,'n') do
            assert_match(/skip  doc\/config\.rb/, invoke!)
          end
        end

# Not sure how to do this without more flexible stubbing.... 
# it's a crappy test anyway
#        it "executes the block given to show file content" do
#          create_file("doc/config.rb")
#          $stdin.should_receive(:gets).and_return('d')
#          $stdin.should_receive(:gets).and_return('n')
#          @base.shell.should_receive(:system).with(/diff -u/)
#          invoke!
#        end

        # note no assertion, just output
        it "shows diff if user requested" do
          create_file("doc/config.rb")
          @base.shell.stub(:stdin, StringIO.new("d\nn\n")) do
            invoke!
          end
        end
      end

    end
  end  
  
  describe "#revoke!" do
    before { reset }
    
    it "removes the destination file" do
      create_file("doc/config.rb")
      invoke!
      revoke!
      refute File.exists?(@action.destination)
    end

    it "does not raise an error if the file does not exist" do
      create_file("doc/config.rb")
      revoke!
      refute File.exists?(@action.destination)
    end
  end

  describe "#exists?" do
    before { reset }
    it "returns true if the destination file exists" do
      create_file("doc/config.rb")
      refute @action.exists?
      invoke!
      assert @action.exists?
    end
  end

  describe "#identical?" do
    before { reset }
    it "returns true if the destination file and is identical" do
      create_file("doc/config.rb")
      refute @action.identical?
      invoke!
      assert @action.identical?
    end
  end
end
