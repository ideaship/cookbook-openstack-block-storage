# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::volume' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'
    include_examples 'common-logging'
    include_examples 'creates_cinder_conf', 'service[cinder-volume]', 'cinder', 'cinder'

    it 'upgrades cinder volume packages' do
      expect(chef_run).to upgrade_package 'cinder-volume'
    end

    it 'upgrades qemu utils package' do
      expect(chef_run).to upgrade_package 'qemu-utils'
    end

    it 'upgrades thin provisioning tools package' do
      expect(chef_run).to upgrade_package 'thin-provisioning-tools'
    end

    it 'starts cinder volume' do
      expect(chef_run).to start_service 'cinder-volume'
    end

    it 'starts cinder volume on boot' do
      expect(chef_run).to enable_service 'cinder-volume'
    end

    it 'starts iscsi target on boot' do
      expect(chef_run).to enable_service 'iscsitarget'
    end

    it 'upgrades mysql python packages by default' do
      expect(chef_run).to upgrade_package 'python-mysqldb'
    end

    it 'upgrades cinder iscsi package' do
      expect(chef_run).to upgrade_package 'targetcli'
    end
  end
end
