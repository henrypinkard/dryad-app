require 'spec_helper'

module Stash
  module Wrapper
    describe Size do
      describe '#initialize' do
        attr_accessor :params

        before(:each) do
          @params = { bytes: 12_345 }
        end

        it 'sets fields from parameters' do
          size = Size.new(params)
          expect(size.size).to eq(12_345)
          expect(size.unit).to eq(SizeUnit::BYTE)
        end

        it 'rejects a nil bytes' do
          params.delete(:bytes)
          expect { Size.new(params) }.to raise_error(ArgumentError)
        end

        it 'rejects a non-integer bytes' do
          params[:bytes] = 1.1
          expect { Size.new(params) }.to raise_error(ArgumentError)
        end

        it 'rejects a non-numeric bytes' do
          params[:bytes] = '1'
          expect { Size.new(params) }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
