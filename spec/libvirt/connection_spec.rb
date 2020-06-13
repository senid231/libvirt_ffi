# frozen_string_literal: true

RSpec.describe Libvirt::Connection do
  let(:connection) { described_class.new(connection_uri) }
  let(:connection_uri) { 'test:///default?rspec=1' }

  describe '#uri' do
    subject { connection.uri }

    it { is_expected.to eq(connection_uri) }
  end

  describe '#open' do
    subject { connection.open }

    it 'virConnectGetURI responds with correct uri' do
      subject
      actual_uri = Libvirt::FFI::Host.virConnectGetURI(connection.to_ptr)
      expect(actual_uri).to eq(connection.uri)
    end
  end

  describe '.load_ref' do
  end
end
