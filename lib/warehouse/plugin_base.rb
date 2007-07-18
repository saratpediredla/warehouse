module Warehouse
  class PluginBase
    attr_reader :options

    def initialize
      @options = default_options.dup
      yield self if block_given?
    end

    class << self
      def plugin_name
        @plugin_name ||= underscore(demodulize(name))
      end
    
      def class_name_of(plugin_name)
        camelize plugin_name
      end

      plugin_property_source = %w(author version homepage notes).collect! do |property|
        <<-END
          def #{property}(value = nil)
            @#{property} = value if value
            @#{property}
          end
        END
      end
      eval plugin_property_source * "\n"

      def default_options
        @default_options ||= {}
      end
    
      def option(property, default = nil)
        class_eval <<-END, __FILE__, __LINE__
            def #{property}
              options[#{property.inspect}].blank? ? #{default.inspect} : options[#{property.inspect}]
            end
          
            def #{property}=(value)
              options[#{property.inspect}] = value
            end
          END
        default_options[property] = default
      end

      # see expiring_attr_reader plugin
      def expiring_attr_reader(method_name, value)
        var_name    = method_name.to_s.gsub(/\W/, '')
        class_eval(<<-EOS, __FILE__, __LINE__)
          def #{method_name}
            def self.#{method_name}; @#{var_name}; end
            @#{var_name} ||= eval(%(#{value}))
          end
        EOS
      end

    # assume activesupport is not available
    private
      def camelize(lower_case_and_underscored_word)
        lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
      end

      def demodulize(modulized)
        modulized.to_s.gsub(/^.+::/, '')
      end

      def underscore(camel_cased_word)
        camel_cased_word.to_s.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
      end
    end

    plugin_property_source = %w(author version homepage notes plugin_name plugin_path view_path default_options).collect! do |property|
      "def #{property}() self.class.#{property} end"
    end
    eval plugin_property_source * "\n"

    def logger
      RAILS_DEFAULT_LOGGER
    end
  end
end