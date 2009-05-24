module DataMapper
  module Filters
    Resource.append_inclusions self

    def self.included(base)
      base.extend ClassMethods
      base.class_eval <<-EOS
        register_class_hooks :all, :first
      EOS
    end

    module ClassMethods
      def has_filter(name, options={})
        ['all','first'].each do |verb|
          class_eval <<-EOS, __FILE__, __LINE__
            class << self
              def #{verb}_with_#{name}_filter(query={})
                catch(:halt) do
                  filter = query.delete("#{name}".to_sym)
                  query = #{name}_filter(query, filter) if filter
                  #{verb}_sans_#{name}_filter query
                end
              end

              alias_method :#{verb}_sans_#{name}_filter, :#{verb}
              alias_method :#{verb}, :#{verb}_with_#{name}_filter
            end
          EOS
        end
      end
    end
  end
end
