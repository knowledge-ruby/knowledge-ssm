# frozen_string_literal: true

require 'knowledge/ssm/version'

module Knowledge
  class SsmError < Error; end

  #
  # === Description ===
  #
  # SSM Adapter for Knowledge gem
  #
  # === Usage ===
  #
  # @example:
  #   require 'knowledge/ssm'
  #
  #   knowledge = Knowledge::Learner.new
  #   knowledge.variables = { ssm: { my_secret: 'path/to/secret' } }
  #
  #   knowledge.use(name: :ssm)
  #   knowledge.add_adapter_params(adapter: :ssm, params: { root_path: '/project' })
  #
  #   knowledge.gather!
  #
  #   Knowledge::Configuration.my_secret # "Secret value"
  #
  module Ssm; end
end

require 'knowledge/adapters/ssm'
