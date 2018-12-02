# frozen_string_literal: true

require 'aws-sdk-ssm'

module Knowledge
  module Adapters
    #
    # === Description ===
    #
    # This adapter takes some vars in your SSM parameters and set it in your project's config.
    #
    # === Usage ===
    #
    # @example:
    #   adapter = Knowledge::Adapters::Ssm.new(params: { root_path: '/path', setter: MySetter, variables: my_vars)
    #
    #   adapter.run
    #
    # === Attributes ===
    #
    # @attr_reader [Boolean] raise_not_found
    # @attr_reader [String] root_path
    # @attr_reader [Class] setter
    # @attr_reader [Array<Aws::SSM::Types::Parameter>] ssm_parameters
    # @attr_reader [Hash] variables
    #
    class Ssm < Base
      # == Attributes ==================================================================================================
      attr_reader :raise_not_found, :root_path, :ssm_parameters

      # == Constructor =================================================================================================
      #
      # @param [Hash] :params
      # @option params [Aws::SSM::Client] :client
      # @option params [Boolean] :raise_on_parameter_not_found
      # @option params [String] :root_path
      # @param [Hash] :variables
      # @param [Class] :setter
      #
      def initialize(params: {}, setter:, variables:)
        super

        @client = params[:client] || params['client']
        @raise_not_found = params[:raise_on_parameter_not_found] || params['raise_on_parameter_not_found'] || false
        @root_path = params[:root_path] || params['root_path']
        @ssm_parameters = @root_path ? fetch_recursive_parameters : fetch_parameters
      end

      # == Instance Methods ============================================================================================
      #
      # === Description ===
      #
      # Runs the actual adapter.
      #
      def run
        variables.each do |name, path|
          base_path = root_path[0..-2] if root_path&.end_with?('/')
          path = "/#{path.sub('/', '')}"
          value = Array(@ssm_parameters).detect { |p| p.name == "#{base_path}#{path}" }&.value

          setter.set(name: name, value: value)
        end
      end

      protected

      #
      # === Description ===
      #
      # Credentials for AWS should be loaded from the ENV vars by the client itself.
      # Authorization is done automatically according to the current AWS policies.
      #
      # === Errors ===
      #
      # @raise [Aws::SSM::Errors::UnrecognozedClientException]
      # @raise [Aws::SSM::AccessDeniedException]
      #
      # === Parameters ===
      #
      # @return [Aws::SSM::Client]
      #
      def client
        @client ||= ::Aws::SSM::Client.new
      end

      #
      # === Description ===
      #
      # Fetches parameters one by one on SSM according to their specific path
      #
      # === Parameters ===
      #
      # @return [Array<Aws::SSM::Types::Parameter>]
      #
      def fetch_parameters
        variables.map { |_name, path| fetch_parameter(path: path) }.compact
      end

      #
      # === Description ===
      #
      # Recursively fetches parameters on SSM according to the given path
      #
      # === Errors ===
      #
      # @raise [Knowledge::SsmError]
      #
      # === Parameters ===
      #
      # @return [Array<Aws::SSM::Types::Parameter>]
      #
      def fetch_recursive_parameters
        parameters = []
        next_token = nil
        first_page = true

        while next_token || first_page
          first_page = false
          result = client.get_parameters_by_path(
            next_token: next_token,
            path: root_path,
            recursive: true,
            with_decryption: true
          )
          parameters += result.parameters
          next_token = result.next_token
        end

        parameters
      rescue ::Aws::SSM::Errors::AccessDeniedException, ::Aws::SSM::Errors::UnrecognozedClientException => e
        raise ::Knowledge::SsmError, "[#{e.class}]: #{e.message}"
      end

      #
      # === Description ===
      #
      # Fetches a parameter by its path on SSM
      #
      # === Error ===
      #
      # @raise [Knowledge::SsmError]
      #
      # === Parameters ===
      #
      # @param [String] :path
      #
      # @return [Aws::SSM::Types::Parameter]
      #
      def fetch_parameter(path:)
        client.get_parameter(name: path, with_decryption: true).parameter
      rescue ::Aws::SSM::Errors::AccessDeniedException, ::Aws::SSM::Errors::UnrecognozedClientException => e
        raise ::Knowledge::SsmError, "[#{e.class}]: #{e.message}"
      rescue ::Aws::SSM::Errors::ParameterNotFound => e
        raise ::Knowledge::SsmError, "[#{e.class}]: #{e.message}" if raise_not_found
      end
    end
  end
end

::Knowledge::Learner.register_default_adapter(
  klass: ::Knowledge::Adapters::Ssm,
  names: %i[aws_ssm ssm]
)
