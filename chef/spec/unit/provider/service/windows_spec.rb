#
# Author:: Nuo Yan <nuo@opscode.com>
# Copyright:: Copyright (c) 2010, Opscode, Inc
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))

describe Chef::Provider::Service::Windows, "load_current_resource" do
  before(:each) do
    @init_command = "sc"
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = Chef::Resource::Service.new("chef")
    @new_resource.stub!(:pattern).and_return("chef")
    @new_resource.stub!(:status_command).and_return(false)

    @current_resource = Chef::Resource::Service.new("chef")
    @provider = Chef::Provider::Service::Windows.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
    IO.stub!(:popen).with("#{@init_command} query #{@new_resource.service_name}").and_return(['','','','4'])
    IO.stub!(:popen).with("#{@init_command} qc #{@new_resource.service_name}").and_return(['','','','','2'])
  end

  it "should create a current resource with the name of the new resource" do
    Chef::Resource::Service.should_receive(:new).and_return(@current_resource)
    @provider.load_current_resource
  end

  it "should set the current resources service name to the new resources service name" do
    @current_resource.should_receive(:service_name).with(@new_resource.service_name)
    @provider.load_current_resource
  end

  it "should return the current resource" do
    @provider.load_current_resource.should eql(@current_resource)
  end

end

describe Chef::Provider::Service::Windows, "start_service" do
  before(:each) do
    @new_resource = Chef::Resource::Service.new("chef")
    @new_resource.start_command "sc start chef"

    @provider = Chef::Provider::Service::Windows.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should call the start command if one is specified" do
    @new_resource.stub!(:start_command).and_return("#{@new_resource.start_command}")
    IO.should_receive(:popen).with("#{@new_resource.start_command}").and_return(StringIO.new("foo\nbar\nbaz\n2 START_PENDING\n"))
    @provider.start_service()
  end
end

describe Chef::Provider::Service::Windows, "stop_service" do
  before(:each) do
    @init_command = "sc"
    @new_resource = Chef::Resource::Service.new("chef")
    @new_resource.stop_command "sc stop chef"

    @provider = Chef::Provider::Service::Windows.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should call the stop command if one is specified" do
    @new_resource.stub!(:stop_command).and_return("#{@new_resource.stop_command}")
    IO.should_receive(:popen).with("#{@new_resource.stop_command}").and_return(StringIO.new("foo\nbar\nbaz\n1 STOPPED\n"))
    @provider.stop_service().should be_true
  end

  it "should use the built-in command if no stop command is specified" do
    @new_resource.stub!(:stop_command).and_return(nil)
    IO.stub!(:popen).with("#{@init_command} stop #{@new_resource.service_name}").and_return(IO.new(2,'w'))
    IO.popen("#{@init_command} stop #{@new_resource.service_name}").stub!(:readlines).and_return(["foo\n","bar\n","baz\n","1 STOPPED\n"])
    @provider.stop_service().should be_true
  end
end

describe Chef::Provider::Service::Windows, "restart_service" do
  before(:each) do
    @init_command = "sc"
    @new_resource = Chef::Resource::Service.new("chef")

    @provider = Chef::Provider::Service::Windows.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should just call stop, then start when the resource doesn't support restart and no restart_command is specified" do
    IO.should_receive(:popen).with("#{@init_command} stop #{@new_resource.service_name}").and_return(StringIO.new("foo\nbar\nbaz\n1 STOPPED\n"))
    IO.should_receive(:popen).with("#{@init_command} start #{@new_resource.service_name}").and_return(StringIO.new("foo\nbar\nbaz\n2 START_PENDING\n"))
    @provider.restart_service()
  end
end

describe Chef::Provider::Service::Windows, "enable_service" do
  before(:each) do
    @init_command = "sc"
    @node = Chef::Node.new
    @new_resource = Chef::Resource::Service.new("chef")
    @new_resource.running  false
    @new_resource.enabled  false

    @provider = Chef::Provider::Service::Windows.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should enable service and set the startup type" do
    @new_resource.startup_type :automatic
    IO.should_receive(:popen).with("sc config chef start= auto").and_return(StringIO.new("SUCCESS"))
    @provider.enable_service().should be_true
  end
end

describe Chef::Provider::Service::Windows, "disable_service" do
  before(:each) do
    @node = Chef::Node.new
    @new_resource = Chef::Resource::Service.new("chef")

    @provider = Chef::Provider::Service::Windows.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should disable service" do
    IO.should_receive(:popen).with("sc config chef start= disabled").and_return(StringIO.new("SUCCESS"))
    @provider.disable_service().should be_true
  end
end

