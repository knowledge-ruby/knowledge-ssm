# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Knowledge::Learner do
  describe '#use' do
    context 'given name is aws_ssm or ssm' do
      %i[aws_ssm ssm].each do |name|
        it 'registers and enables the Knowledge::Adapters::Ssm adapter' do
          subject.use(name: name)

          expect(subject.available_adapters).to have_key name
          expect(subject.enabled_adapters).to have_key name
          expect(subject.available_adapters[name]).to eq Knowledge::Adapters::Ssm
          expect(subject.enabled_adapters[name]).to eq Knowledge::Adapters::Ssm
        end
      end
    end
  end
end
