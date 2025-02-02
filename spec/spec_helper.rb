# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require 'chefspec'
require 'chefspec/berkshelf'

ChefSpec::Coverage.start! { add_filter 'openstack-block-storage' }

require 'chef/application'

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
  config.log_level = :fatal
end

REDHAT_OPTS = {
  platform: 'redhat',
  version: '7.4',
}.freeze
UBUNTU_OPTS = {
  platform: 'ubuntu',
  version: '16.04',
}.freeze

shared_context 'block-storage-stubs' do
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:rabbit_servers)
      .and_return('1.1.1.1:5672,2.2.2.2:5672')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', anything)
      .and_return('')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('db', anything)
      .and_return('')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('token', 'openstack_vmware_secret_name')
      .and_return 'vmware_secret_name'
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'guest')
      .and_return('mq-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'netapp')
      .and_return 'netapp-pass'
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-block-storage')
      .and_return('cinder-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'admin')
      .and_return('emc_test_pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'ibmnas_admin')
      .and_return('test_pass')
    allow_any_instance_of(Chef::Recipe).to receive(:rabbit_transport_url)
      .with('block_storage')
      .and_return('rabbit://guest:mypass@127.0.0.1:5672')
    stub_command('/usr/sbin/httpd -t').and_return(true)
    stub_command('/usr/sbin/apache2 -t').and_return(true)
    allow(Chef::Application).to receive(:fatal!)
  end
end

shared_examples 'common-logging' do
  context 'when syslog.use is true' do
    before do
      node.override['openstack']['block-storage']['syslog']['use'] = true
    end

    it 'runs logging recipe if node attributes say to' do
      expect(chef_run).to include_recipe 'openstack-common::logging'
    end
  end

  context 'when syslog.use is false' do
    before do
      node.override['openstack']['block-storage']['syslog']['use'] = false
    end

    it 'runs logging recipe if node attributes say to' do
      expect(chef_run).to_not include_recipe 'openstack-common::logging'
    end
  end
end

def expect_runs_openstack_common_logging_recipe
  it 'runs logging recipe if node attributes say to' do
    expect(chef_run).to include_recipe 'openstack-common::logging'
  end
end

shared_examples 'creates_cinder_conf' do |service, user, group, action = :restart|
  describe 'cinder.conf' do
    let(:file) { chef_run.template('/etc/cinder/cinder.conf') }

    it 'creates the /etc/cinder/cinder.conf file' do
      expect(chef_run).to create_template(file.name).with(
        user: user,
        group: group,
        mode: 0o640
      )
    end

    it 'notifies service restart' do
      expect(file).to notify(service).to(action)
    end

    it do
      [
        /^auth_type = password$/,
        /^region_name = RegionOne$/,
        /^username = cinder/,
        /^project_name = service$/,
        /^user_domain_name = Default/,
        /^project_domain_name = Default/,
        %r{^auth_url = http://127.0.0.1:5000/v3$},
        /^password = cinder-pass$/,
      ].each do |line|
        expect(chef_run).to render_config_file(file.name)
          .with_section_content('keystone_authtoken', line)
      end
    end

    it 'has oslo_messaging_notifications conf values' do
      [
        /^driver = cinder.openstack.common.notifier.rpc_notifier$/,
      ].each do |line|
        expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_notifications', line)
      end
    end
  end
end
