class MarketMetrics < Influxer::Metrics # :nodoc:

  measurement :market
  retention :monthly
  precision :ns

  tag :symbol, default: 'USDRUR'
  tag :exchange_id, type: :integer, default: 1234
  tags :market_id, :site_id, type: :integer

  fields :price, :price_high, :price_low, type: :float
  field :price_delta, type: :float, default: 0

  attributes :volume, :ask, :bid

  # validates_presence_of :exchange_id, :market_id, :volume

  # before_write -> { self.timestamp = Time.now }

  # scope :calc, ->(method, *args) { send(method, *args) }
end
