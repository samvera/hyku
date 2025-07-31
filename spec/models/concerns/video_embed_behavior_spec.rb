# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VideoEmbedBehavior do
  describe '#responds_to_video_embed?' do
    context 'when the object responds to video_embed' do
      let(:instance) do
        Class.new do
          def self.properties
            @properties ||= {}
          end

          def self.property(name, **options)
            properties[name] = OpenStruct.new(options)
          end

          include ActiveModel::Model
          include ActiveModel::Validations
          include VideoEmbedBehavior
          attr_accessor :video_embed
        end.new
      end

      it 'returns true' do
        expect(instance.respond_to?(:video_embed)).to be true
        expect(instance.send(:responds_to_video_embed?)).to be true
      end
    end

    context 'when the object does not respond to video_embed' do
      let(:instance) do
        Class.new do
          def self.properties
            @properties ||= {}
          end

          def self.property(name, **options)
            properties[name] = OpenStruct.new(options)
          end

          include ActiveModel::Model
          include ActiveModel::Validations
          include VideoEmbedBehavior

          def method_missing(method_name, *args, &block)
            raise NoMethodError, "undefined method `#{method_name}' for #{self}" if method_name == :video_embed
            super
          end

          def respond_to_missing?(method_name, include_private = false)
            if method_name == :video_embed
              false
            else
              super
            end
          end
        end.new
      end

      it 'returns false' do
        expect(instance.respond_to?(:video_embed)).to be false
        expect(instance.send(:responds_to_video_embed?)).to be false
      end
    end
  end
end
