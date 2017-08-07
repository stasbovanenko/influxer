module Influxer
  module Attributes

    extend ActiveSupport::Concern

    included do

      def series
        self.class.quoted_series(self.class.series, self)
      end

      def time_precision
        self.class.time_precision || Influxer.config.time_precision
      end

      def retention_policy
        self.class.retention_policy
      end

      # Returns hash with metrics values
      def values
        @attributes.reject { |k, _| tag_names.include?(k.to_s) }
      end

      # Returns hash with metrics tags
      def tags
        @attributes.select { |k, _| tag_names.include?(k.to_s) }
      end

      def tag_names
        self.class.tag_names
      end

    end

    class_methods do

      attr_reader :series, :retention_policy, :time_precision
      attr_accessor :tag_names

      def attributes(*attrs)
        attrs.each do |name|
          define_method("#{name}=") do |val|
            @attributes[name] = val
          end

          define_method(name.to_s) do
            @attributes[name]
          end
        end
      end

      def tags(*attrs)
        attributes(*attrs)
        self.tag_names ||= []
        self.tag_names += attrs.map(&:to_s)
      end

      def tag?(name)
        tag_names.include?(name.to_s)
      end

      def set_retention_policy(policy_name)
        @retention_policy = policy_name
      end

      def set_time_precision(t)
        @time_precision = t
      end

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def set_series(*args)
        if args.empty?
          matches = to_s.match(/^(.*)Metrics$/)
          if matches.nil?
            @series = superclass.respond_to?(:series) ? superclass.series : to_s.underscore
          else
            @series = matches[1].split("::").join("_").underscore
          end
        elsif args.first.is_a?(Proc)
          @series = args.first
        else
          @series = args
        end
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize
    end

  end
end
