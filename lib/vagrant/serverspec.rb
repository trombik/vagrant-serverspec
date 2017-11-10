module Vagrant
  # Class to run serverspec on a host in a group
  class Serverspec
    @file = ""

    # Creates instance of Rspec::Serverspec
    #
    # @param file [String] path to inventory file
    def initialize(file)
      @file = file
    end

    # Runs serverspec for a group on a host
    #
    # @param group [String] name of group
    # @param hostname [String] name of host
    #
    def run(group:, hostname:)
      sudo_password = ENV["SUDO_PASSWORD"]
      Bundler.with_clean_env do
        configure_env(
          "TARGET_HOST" => hostname,
          "SUDO_PASSWORD" => sudo_password
        )
        system "bundle exec rspec spec/serverspec/#{group}/*_spec.rb"
        raise "Failed to run rspec" if $CHILD_STATUS.exitstatus != 0
      end
    end

    # Runs `.run` method in a forked process.
    #
    # This method is supposed to be faster than `.run` when running tests on
    # multiple remote system with `rspec -m` (in theory, not confirmed yet).
    #
    # you need to call Process.waitall in the calling task
    #
    # @param group [String] name of group
    # @param hostname [String] name of host
    #
    def run_with_fork(group:, hostname:)
      fork do
        run(group: group, hostname: hostname)
      end
    end

    # Sets necessary environment variables for serverspec test
    #
    # @param env [HASH] hash of environment variable name and its value
    def configure_env(env)
      env.each do |k, v|
        ENV[k] = v unless v.nil?
      end
    end
  end
end
