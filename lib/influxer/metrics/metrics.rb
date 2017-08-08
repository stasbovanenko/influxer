require 'influxer/metrics/relation'
require 'influxer/metrics/scoping'
require 'influxer/metrics/attributes'
require 'influxer/metrics/active_model3/model'

module Influxer
  class MetricsError < StandardError; end
  class MetricsInvalid < MetricsError; end

  # Base class for InfluxDB querying and writing
  # rubocop:disable Metrics/ClassLength
  class Metrics
    TIME_FACTOR = 1_000_000_000

    if Influxer.active_model3?
      include Influxer::ActiveModel3::Model
    else
      include ActiveModel::Model
    end

    extend  ActiveModel::Callbacks

    include Influxer::Attributes
    include Influxer::Scoping

    include ActiveModel::Validations

    define_model_callbacks :write

    class << self
      # delegate query functions to all
      delegate(
        *(
          [
            :write, :write!, :select, :where,
            :group, :time, :past, :since,
            :limit, :offset, :fill, :delete_all, :epoch
          ] + Influxer::Calculations::CALCULATION_METHODS
        ),
        to: :all
      )

      def inherited(subclass)
        subclass.set_series
        subclass.tag_names = tag_names.nil? ? [] : tag_names.dup
      end

      def all
        if current_scope
          current_scope.clone
        else
          default_scoped
        end
      end

      # rubocop:disable Metrics/MethodLength
      def quoted_series(val = @series, instance = nil)
        case val
        when Regexp
          val.inspect
        when Proc
          quoted_series(val.call(instance))
        when Array
          if val.length > 1
            "merge(#{val.map { |s| quoted_series(s) }.join(',')})"
          else
            quoted_series(val.first)
          end
        else
          if retention_policy.present?
            [quote(retention_policy), quote(val)].join('.')
          else
            quote(val)
          end
        end
      end

      def quote(name)
        '"' + name.to_s.gsub(/\"/) { '\"' } + '"'
      end

      # rubocop:enable Metrics/MethodLength
    end

    attr_accessor :timestamp

    def initialize(params = {})
      @attributes={}
      @persisted = false
      @attributes.update(defaults) unless defaults.empty?
      super
    end

    def write
      cast_types
      raise MetricsError if persisted?

      return false if invalid?

      run_callbacks :write do
        write_point
      end
      self
    end

    def write!
      raise MetricsInvalid if invalid?
      write
    end

    def write_point
      client.write_point unquote(series), {tags: tags, values: values}, time_precision, retention_policy
      @persisted = true
    end

    def persisted?
      @persisted
    end

    def client
      Influxer.client
    end

    def dup
      self.class.new(@attributes)
    end

    private

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def parsed_timestamp
      return @timestamp unless client.time_precision == 'ns'

      case @timestamp
      when Numeric
        @timestamp.to_i.to_s.ljust(19, '0').to_i
      when String
        (Time.parse(@timestamp).to_r * TIME_FACTOR).to_i
      when Date
        (@timestamp.to_time.to_r * TIME_FACTOR).to_i
      when Time
        (@timestamp.to_r * TIME_FACTOR).to_i
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    def unquote(name)
      name.gsub(/(\A['"]|['"]\z)/, '')
    end
  end
end
