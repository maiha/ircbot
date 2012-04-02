require 'rubygems'
require 'rspec'
require 'pathname'
require 'tempfile'

module RSpec
  module Core
    module SharedExampleGroup
      def summary(url, &block)
        describe "(#{url})" do
          subject { Summarizers.create(url) }
          instance_eval(&block)
        end
      end
    end
  end
end

