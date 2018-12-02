# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Knowledge::Adapters::Ssm do
  let(:parameters) { [] }
  let(:params) { {} }
  let(:setter) { Knowledge::Setter.new }
  let(:variables) { {} }

  subject do
    allow_any_instance_of(described_class).to receive(:fetch_parameters).and_return(parameters)
    allow_any_instance_of(described_class).to receive(:fetch_recursive_parameters).and_return(parameters)

    s = described_class.new(params: params, setter: setter, variables: variables)

    allow_any_instance_of(described_class).to receive(:fetch_parameters).and_call_original
    allow_any_instance_of(described_class).to receive(:fetch_recursive_parameters).and_call_original

    s
  end

  describe '#initialize' do
    context 'with client in params' do
      let(:client) { double }

      context 'string key' do
        let(:params) { { 'client' => client } }

        it 'sets the client' do
          expect(subject.send(:client)).to eq client
        end
      end

      context 'sym key' do
        let(:params) { { client: client } }

        it 'sets the client' do
          expect(subject.send(:client)).to eq client
        end
      end
    end

    context 'with root_path in params' do
      let(:root_path) { '/root/path' }

      context 'string key' do
        let(:params) { { 'root_path' => root_path } }

        it 'sets the root_path' do
          expect(subject.root_path).to eq root_path
        end
      end

      context 'sym key' do
        let(:params) { { root_path: root_path } }

        it 'sets the root_path' do
          expect(subject.root_path).to eq root_path
        end
      end
    end

    context 'with raise_on_parameter_not_found in params' do
      let(:raise_on_parameter_not_found) { true }

      context 'string key' do
        let(:params) { { 'raise_on_parameter_not_found' => raise_on_parameter_not_found } }

        it 'sets the raise_not_found' do
          expect(subject.raise_not_found).to eq raise_on_parameter_not_found
        end
      end

      context 'sym key' do
        let(:params) { { raise_on_parameter_not_found: raise_on_parameter_not_found } }

        it 'sets the raise_not_found' do
          expect(subject.raise_not_found).to eq raise_on_parameter_not_found
        end
      end
    end

    it 'sets @ssm_parameters' do
      expect(subject.ssm_parameters).to eq []
    end
  end

  describe '#run' do
    context 'with root_path' do
      let(:param_name) { '/path/to/variable' }
      let(:var_name) { :var_name }
      let(:value) { :foo }
      let(:root_path) { '/root' }
      let(:params) { { root_path: root_path } }
      let(:variables) { { var_name.to_sym => param_name } }
      let(:parameters) { [OpenStruct.new(name: param_name, value: value)] }

      it 'sets the variables' do
        expect(setter).to receive(:set).with(name: var_name, value: value)

        subject.run
      end
    end

    context 'without root_path' do
      let(:param_name) { '/path/to/variable' }
      let(:var_name) { :var_name }
      let(:value) { :foo }
      let(:variables) { { var_name.to_sym => param_name } }
      let(:parameters) { [OpenStruct.new(name: param_name, value: value)] }

      it 'sets the variables' do
        expect(setter).to receive(:set).with(name: var_name, value: value)

        subject.run
      end
    end
  end

  describe '#client' do
    it { expect(subject.send(:client)).to be_a Aws::SSM::Client }
  end

  describe '#fetch_parameters' do
    let(:param_name) { '/path/to/variable' }
    let(:var_name) { :var_name }
    let(:variables) { { var_name.to_sym => param_name } }

    it 'relies on fetch_parameter' do
      expect(subject).to receive(:fetch_parameter).with(path: param_name)

      subject.send(:fetch_parameters)
    end
  end

  describe '#fetch_recursive_parameters' do
    let(:result) { double }

    context 'working case' do
      before do
        expect(result).to receive(:next_token).and_return(nil)
        expect(result).to receive(:parameters).and_return([])
      end

      it 'relies on client#get_parameters_by_path' do
        expect(subject.send(:client)).to receive(:get_parameters_by_path).and_return(result)

        subject.send(:fetch_recursive_parameters)
      end
    end

    context 'on Aws::SSM::Errors::AccessDeniedException' do
      it 'relies on client#get_parameters_by_path' do
        expect(subject.send(:client)).to receive(:get_parameters_by_path).and_raise(
          Aws::SSM::Errors::AccessDeniedException.new('', '')
        )

        expect { subject.send(:fetch_recursive_parameters) }.to raise_error Knowledge::SsmError
      end
    end

    context 'on Aws::SSM::Errors::UnrecognozedClientException' do
      it 'relies on client#get_parameters_by_path' do
        expect(subject.send(:client)).to receive(:get_parameters_by_path).and_raise(
          Aws::SSM::Errors::UnrecognozedClientException.new('', '')
        )

        expect { subject.send(:fetch_recursive_parameters) }.to raise_error Knowledge::SsmError
      end
    end
  end

  describe '#fetch_parameter' do
    let(:path) { '/path/to/var' }

    context 'working case' do
      let(:result) { double }

      it 'relies on client#get_parameter' do
        expect(result).to receive(:parameter).and_return :parameter
        expect(subject.send(:client)).to receive(:get_parameter).and_return(result)

        expect(subject.send(:fetch_parameter, path: path)).to eq :parameter
      end
    end

    context 'on Aws::SSM::Errors::AccessDeniedException' do
      it 'raises a Knowledge::SsmError' do
        expect(subject.send(:client)).to receive(:get_parameter).and_raise(
          Aws::SSM::Errors::AccessDeniedException.new('', '')
        )

        expect { subject.send(:fetch_parameter, path: path) }.to raise_error Knowledge::SsmError
      end
    end

    context 'on Aws::SSM::Errors::UnrecognozedClientException' do
      it 'raises a Knowledge::SsmError' do
        expect(subject.send(:client)).to receive(:get_parameter).and_raise(
          Aws::SSM::Errors::UnrecognozedClientException.new('', '')
        )

        expect { subject.send(:fetch_parameter, path: path) }.to raise_error Knowledge::SsmError
      end
    end

    context 'on Aws::SSM::Errors::ParameterNotFound' do
      context 'raise activated' do
        let(:params) { { raise_on_parameter_not_found: true } }

        it 'raises a Knowledge::SsmError' do
          expect(subject.send(:client)).to receive(:get_parameter).and_raise(
            Aws::SSM::Errors::ParameterNotFound.new('', '')
          )

          expect { subject.send(:fetch_parameter, path: path) }.to raise_error Knowledge::SsmError
        end
      end

      context 'raise deactivated' do
        let(:params) { { raise_on_parameter_not_found: false } }

        it 'raises a Knowledge::SsmError' do
          expect(subject.send(:client)).to receive(:get_parameter).and_raise(
            Aws::SSM::Errors::ParameterNotFound.new('', '')
          )

          expect { subject.send(:fetch_parameter, path: path) }.not_to raise_error Knowledge::SsmError
        end
      end
    end
  end
end
