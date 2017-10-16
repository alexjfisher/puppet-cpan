require 'spec_helper'

provider_class = Puppet::Type.type(:cpan).provider(:default)

describe provider_class do
  let(:name)     { 'Foo::Bar' }
  let(:resource) { Puppet::Type.type(:cpan).new(resource_properties) }
  let(:provider) { provider_class.new(resource) }
  before :each do
    provider.class.stubs(:command).with(:yes).returns('/bin/yes')
    provider.class.stubs(:command).with(:perl).returns('/bin/perl')
    provider.class.stubs(:command).with(:cpan).returns('/bin/cpan')
  end

  describe '#create' do
    context 'with default parameters' do
      let(:resource_properties) do
        {
          name: name,
          ensure: 'present'
        }
      end
      it 'force option is not used' do
        provider.expects(:execute).with('/bin/yes | /bin/perl  -MCPAN -e \'CPAN::install Foo::Bar\'')
        provider.expects(:execute).with('/bin/perl  -MFoo::Bar -e1 > /dev/null 2>&1')
        expect(provider.create)
      end
    end
    context 'with false => true' do
      let(:resource_properties) do
        {
          name: name,
          ensure: 'present',
          force: true
        }
      end
      it 'CPAN command includes CPAN::force' do
        provider.expects(:execute).with('/bin/yes | /bin/perl  -MCPAN -e \'CPAN::force CPAN::install Foo::Bar\'')
        provider.expects(:execute).with('/bin/perl  -MFoo::Bar -e1 > /dev/null 2>&1')
        expect(provider.create)
      end
    end
  end
end
