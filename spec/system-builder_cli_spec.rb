require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'system_builder/cli'

describe SystemBuilder::CLI, "execute" do

  class ExitException < Exception; end;

  before(:each) do
    SystemBuilder::CLI.stub!(:exit).and_raise(ExitException)
  end

  def system_builder(*arguments)
    @stdout_io = StringIO.new

    begin
      SystemBuilder::CLI.execute(@stdout_io, arguments.flatten)
    rescue ExitException

    end

    @stdout_io.rewind
    @stdout = @stdout_io.read
  end
  
  it "should print default output" do
    system_builder "--help"
    @stdout.should =~ /Usage: .* \[options\] image command/
  end
end
