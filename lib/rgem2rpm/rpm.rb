# -*- encoding : utf-8 -*-
require 'erb'

class RGem2Rpm::Rpm
  attr_accessor :name, :version, :release, :license, :summary, :group, :packager, :description, :installdir

  def initialize(args)
    @template = args[:template] || File.dirname(__FILE__) + '/../../conf/template.spec'
    @name = args[:installname]
    @rpmname = args[:rpmname] || args[:installname]
    @gemname = args[:name]
    @version = args[:version]
    @release = args[:release] || '1'
    @license = "See #{args[:homepage]}"
    @summary = args[:summary]
    @packager = args[:packager] || 'rgem2rpm'
    @group = args[:group] || 'System Environment/Libraries'
    @osuser = args[:osuser] || 'root'
    @osgroup = args[:osgroup] || 'root'
    @description = process_description(args[:description])
    @installdir = args[:installdir] || '/usr/share/gems'
    @arch = args[:architecture]
    @files = args[:files]
    @rubygem = args[:rubygem]
    @dependencies = args[:dependencies]
  end

  def create
    # create spec
    spec
    # build rpm
    build
  end

  def installlist
    install_str = StringIO.new
    install_str << "rm -rf %{buildroot}\n"
    # get directories
    @files[:directories].each {|directory|
      escaped_str = directory.gsub(/%/, '%%')
      install_str << "install -d \"#{escaped_str}\" %{buildroot}%{prefix}/\"#{escaped_str}\"\n"
    }
    # get files
    @files[:files].each {|file|
      escaped_str = file.gsub(/%/, '%%')
      install_str << "install -m 644 \"#{escaped_str}\" %{buildroot}%{prefix}/\"#{escaped_str}\"\n"
    }
    # get specification
    escaped_str = @files[:specification].gsub(/%/, '%%')
    install_str << "install -m 644 \"#{escaped_str}\" %{buildroot}%{prefix}/\"#{escaped_str}\"\n"
    # get executables
    @files[:executables].each {|executable|
      escaped_str = executable.gsub(/%/, '%%')
      install_str << "install -m 0755 \"#{escaped_str}\" %{buildroot}%{prefix}/\"#{escaped_str}\"\n"
    }

    #Extensions file get build into extensions/<ARCH>-linux/<Ruby Version>/GEM-VERSION/
    # We need to install this into /usr/lib64/gems/ruby/GEM-VERSION/
    # Ex. extensions/x86_64-linux/2.5.0/ffi-1.10.0/gem.build_complete => /usr/lib64/gems/ruby/ffi-1.10.0/gem.build_complete
    @files[:extensions].each {|extensions|
      #remove preceding chars until gem name-version is found (non greedy way)
      # ex. "extensions/x86_64-linux/2.5.0/ffi-1.10.0/gem.build_complete".sub(/.*?(?=ffi-1.10.0)/,"")
      suffix = extensions.sub(/.*?(?=#{@gemname}-#{@version})/, "")
      install_str << "install -D \"#{extensions}\" %{buildroot}%{_libdir}/gems/ruby/\"#{suffix}\"\n"
    }

    # return install string
    install_str.string
  end

  def filelist
    files_str = StringIO.new
    files_str << "%defattr(0644,#{@osuser},#{@osgroup},0755)\n"

    files_str << "%dir %{prefix}\n"
    @files[:directories].each {|file|
      escaped_str = file.gsub(/%/, '?')
      files_str << "%dir \"%{prefix}/#{escaped_str}\"\n"
    }

    files_str << "%{prefix}/#{@files[:specification]}\n"
    @files[:files].each {|file|
      escaped_str = file.gsub(/%/, '?')
      files_str << "\"%{prefix}/#{escaped_str}\"\n"
    }

    # get executables
    @files[:executables].each {|executable|
      files_str << "%attr(0755,#{@osuser},#{@osgroup}) %{prefix}/#{executable}\n"
    }

    @files[:extensions].each {|file|
      suffix = file.sub(/.*?(?=#{@gemname}-#{@version})/, "")
      escaped_str = suffix.gsub(/%/, '?')
      files_str << "\"%{_libdir}/gems/ruby/#{escaped_str}\"\n"
    }

    # return file string
    files_str.string
  end

  def buildarch
    @arch == 'all' ? 'noarch' : nil
  end

  def requires
    req_str = StringIO.new
    # set rubygems dependency
    unless @rubygem.nil?
      req_str << "rubygems"
      req_str << " #{@rubygem}" unless @rubygem == '>= 0'
    end
    # set runtime dependencies
    @dependencies.each {|d|
      d.requirement.requirements.each {|v|
        req_str << ', ' unless req_str.size == 0
        req_str << "rubygem(#{d.name})"
        req_str << " #{v[0].gsub('~>', '>=')} #{v[1].to_s}" unless v[0] =~ /!=/
        if v[0] =~ /~>/
          version = v[1].to_s.strip.split('.')
          version[version.size - 1] = "0"
          version[version.size - 2] = (version[version.size - 2].to_i + 1).to_s
          req_str << ", rubygem(#{d.name}) < #{version.join('.')}"
        end
      }
    }
    # return string with dependencies
    req_str.string
  end

  def conflicts
    conflict_str = StringIO.new
    # set conflicts
    @dependencies.each {|d|
      d.requirement.requirements.each {|v|
        conflict_str << ', ' unless conflict_str.size == 0
        conflict_str << "rubygem(#{d.name}) #{v[0].gsub('!=', '=')} #{v[1].to_s}" if v[0] =~ /!=/
      }
    }
    # returns string with conflicts
    conflict_str.string
  end

# return gem provides clause
  def provides
    prv_str = StringIO.new
    prv_str << "rubygem(#{@gemname}) = #{@version}"
    prv_str.string
  end

# return changelog information
  def changelog
    change_str = StringIO.new
    change_str << "* #{Time.now.strftime('%a %b %d %Y')} rgem2rpm <https://github.com/ptinovacao/rgem2rpm> #{@version}-#{@release}\n"
    change_str << "- Create rpm package\n"
    change_str.string
  end

# clean temporary files
  def clean
    FileUtils.rm_rf "#{@name}-#{@version}.spec"
    FileUtils.rm_rf "./rpmtemp"
  end

  private

  def spec
    template = ERB.new(File.read(@template))
    # write rpm spec file file
    File.open("#{@name}-#{@version}.spec", 'w') {|f|
      f.write(template.result(binding))
    }
  end

  def process_description(description)
    res = []
    str = description
    while str != nil
      res << "#{str[0, 80]}"
      str = str[80, str.size]
    end
    res.join "\n"
  end

  def build
    create_rpm_env
    # move to rpmbuild path
    FileUtils.mv "#{@name}-#{@version}.spec", "rpmtemp/rpmbuild/SPECS"
    # move sources to rpmbuild
    FileUtils.mv "#{@name}-#{@version}.tar.gz", "rpmtemp/rpmbuild/SOURCES"
    # define rpm build args
    options = "-bb --rmspec --rmsource"
    define = "--define \"_topdir #{Dir.pwd}/rpmtemp/rpmbuild\" --define \"_tmppath #{Dir.pwd}/rpmtemp/rpmbuild/tmp\""
    specfile = "#{Dir.pwd}/rpmtemp/rpmbuild/SPECS/#{@name}-#{@version}.spec"
    # create rpm
    res = system "rpmbuild #{options} #{define} #{specfile}"
    # check errors
    raise "Error creating rpm" unless res
    # clean temporary files
    Dir.glob("rpmtemp/rpmbuild/RPMS/**/*.rpm") do |file|
      FileUtils.mv file, "./"
    end
    clean
  end

  def create_rpm_env
    FileUtils.mkdir_p "rpmtemp/rpmbuild/SPECS"
    FileUtils.mkdir_p "rpmtemp/rpmbuild/BUILD"
    FileUtils.mkdir_p "rpmtemp/rpmbuild/RPMS"
    FileUtils.mkdir_p "rpmtemp/rpmbuild/SRPMS"
    FileUtils.mkdir_p "rpmtemp/rpmbuild/SOURCES"
    FileUtils.mkdir_p "rpmtemp/rpmbuild/tmp"
  end

end
