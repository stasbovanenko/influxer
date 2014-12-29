module Influxer
  module Scoping
    module Default
      extend ActiveSupport::Concern

      included do
        class_attribute :default_scopes
        self.default_scopes = []
      end

      module ClassMethods
        def default_scope(scope)
          default_scopes << scope unless scope.nil?
        end

        def unscoped
          Relation.new self
        end

        def default_scoped
          default_scopes.inject(Relation.new(self)) do |rel, scope| 
            rel.merge!(rel.scoping{ scope.call })
          end
        end
      end
    end
  end
end