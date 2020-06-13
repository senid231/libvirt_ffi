# frozen_string_literal: true

RSpec.describe Libvirt, '::VERSION' do
  subject { Libvirt::VERSION }

  it { is_expected.to_not be_nil }
end
