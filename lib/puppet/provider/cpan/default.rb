Puppet::Type.type(:cpan).provide( :default ) do
  @doc = "Manages cpan modules"

  commands :cpan     => 'cpan'
  commands :perl     => 'perl'
  commands :yes      => 'yes'
  confine  :osfamily => [:Debian, :RedHat, :Windows]
  ENV['PERL_MM_USE_DEFAULT'] = '1'

  def install
  end

  def force
  end

  def latest?
    if resource[:local_lib]
      ll = "-Mlocal::lib=#{resource[:local_lib]}"
    end
    current_version=`perl #{ll} -M#{resource[:name]} -e 'print $#{resource[:name]}::VERSION'`
    cpan_str=`perl #{ll} -e 'use CPAN; my $mod=CPAN::Shell->expand("Module","#{resource[:name]}"); printf("%s", $mod->cpan_version eq "undef" || !defined($mod->cpan_version) ? "-" : $mod->cpan_version);'`
    latest_version=cpan_str.match(/^[0-9]+.?[0-9]*$/)[0]
    current_version.chomp
    latest_version.chomp
    if current_version < latest_version
    return false else return true end
  end

  def create
    Puppet.info("Installing cpan module #{resource[:name]}")
    if resource[:local_lib]
      ll = "-Mlocal::lib=#{resource[:local_lib]}"
    end

    Puppet.debug("cpan #{resource[:name]}")
    if resource.force?
      Puppet.info("Forcing install for #{resource[:name]}")
      execute("#{command(:yes)} | #{command(:perl)} #{ll} -MCPAN -e 'CPAN::force CPAN::install #{resource[:name]}'")
    else
      execute("#{command(:yes)} | #{command(:perl)} #{ll} -MCPAN -e 'CPAN::install #{resource[:name]}'")
    end

    # cpan doesn't always provide the right exit code, so we double check
    # execute will throw a Puppet::ExecutionFailure if the command doesn't return 0
    execute("#{command(:perl)} #{ll} -M#{resource[:name]} -e1")
  end

  def destroy
  end
  
  def update
    Puppet.info("Upgrading cpan module #{resource[:name]}")
    Puppet.debug("cpan #{resource[:name]}")
    if resource[:local_lib]
      ll = "-Mlocal::lib=#{resource[:local_lib]}"
    end
    if resource.force?
      Puppet.info("Forcing upgrade for #{resource[:name]}")
      execute("#{command(:yes)} | #{command(:perl)} #{ll} -MCPAN -e 'CPAN::force CPAN::install #{resource[:name]}'")
    else
      execute("#{command(:yes)} | #{command(:perl)} #{ll} -MCPAN -e 'CPAN::install #{resource[:name]}'")
    end
  end

  def exists?
    if resource[:local_lib]
      ll = "-Mlocal::lib=#{resource[:local_lib]}"
    end
    output = execute("#{command(:perl)} #{ll} -M#{resource[:name]} -e1", :failonfail => false, :combine => true)
    case output.exitstatus
    when 0
      true
    when 2
      Puppet.debug("#{resource[:name]} not installed")
      false
    else
      raise Puppet::Error, "perl #{ll} -M#{resource[:name]} -e1 failed with error code #{output.exitstatus}: #{output}"
    end
  end

end
