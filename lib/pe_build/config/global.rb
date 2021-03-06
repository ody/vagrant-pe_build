require 'pe_build/config_default'
require 'pe_build/transfer'

require 'uri'

class PEBuild::Config::Global < Vagrant.plugin('2', :config)

  # @todo This value should be discovered based on what versions of the
  #       installer are cached.
  #DEFAULT_PE_VERSION = '2.7.2'

  # @!attribute download_root
  attr_accessor :download_root

  # @!attribute version
  attr_accessor :version

  # @!attribute suffix
  attr_accessor :suffix

  # Allow our filename default to use @version and @suffix variables. This
  # approach will not break the merging mechanism since the merging directly
  # accesses the instance variables of the configuration objects.
  def filename
    if @filename == UNSET_VALUE
      "puppet-enterprise-#{version}-#{suffix}.tar.gz"
    else
      @filename
    end
  end

  # @!attribute filename
  attr_writer :filename

  def initialize
    @download_root = UNSET_VALUE
    @version       = UNSET_VALUE
    @suffix        = UNSET_VALUE
    @filename      = UNSET_VALUE
  end

  include PEBuild::ConfigDefault

  def finalize!
    set_default :@suffix, :detect

    #set_default :@version,  DEFAULT_PE_VERSION

    set_default :@download_root, nil
  end

  # @todo Convert error strings to I18n
  def validate(machine)
    errors = []

    validate_version(errors)
    validate_download_root(errors)

    {"PE build global config" => errors}
  end

  private

  def validate_version(version)

    errmsg = I18n.t(
      'pebuild.config.global.errors.malformed_version',
      :version       => @version,
      :version_class => @version.class
    )

    # Allow Global version to be unset, rendering it essentially optional. If it is
    # discovered to be unset by a configuration on the next level up who cannot provide a
    # value, it is that configuration's job to take action.
    if @version.kind_of? String and !(@version.match /\d+\.\d+(\.\d+)?/)
      errors << errmsg
    elsif @version != UNSET_VALUE
      errors << errmsg
    end
  end

  def validate_download_root(errors)
    if @download_root and @download_root != UNSET_VALUE
      begin
        uri = URI.parse(@download_root)

        if PEBuild::Transfer::IMPLEMENTATIONS[uri.scheme].nil?
          errors << I18n.t(
            'pebuild.config.global.errors.unhandled_download_root_scheme',
            :download_root => @download_root,
            :scheme        => uri.scheme,
            :supported     => PEBuild::Transfer::IMPLEMENTATIONS.keys
          )
        end
      rescue URI::InvalidURIError
        errors << I18n.t('pebuild.config.global.errors.invalid_download_root_uri')
      end
    end
  end
end
