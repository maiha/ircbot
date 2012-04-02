require 'rubygems'
require 'rspec'
require 'pathname'
require 'tempfile'
require 'engines'

module RSpec
  module Core
    module SharedExampleGroup
      def summary(url, &block)
        describe "(#{url})" do
          subject { Engines.create(url) }
          instance_eval(&block)
        end
      end
    end
  end
end

