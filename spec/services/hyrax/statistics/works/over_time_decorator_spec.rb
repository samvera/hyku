# frozen_string_literal: true

RSpec.describe Hyrax::Statistics::Works::OverTime, type: :decorator do
  describe "#points" do
    let(:x_min) { Time.zone.parse("2026-03-01 00:00:00") }
    let(:x_max) { x_min + 1.day }
    let(:subject_instance) do
      described_class.new(
        delta_x: 1,
        x_min: x_min,
        x_max: x_max,
        x_output: ->(x) { x.to_date.to_s }
      )
    end

    it "is being decorated" do
      expect(subject_instance.method(:points).source_location.first).to end_with("over_time_decorator.rb")
    end

    context "when running valkyrie without wings" do
      let(:query_service) { instance_double(Hyrax::Statistics::ValkyrieQueryService) }

      before do
        allow(subject_instance).to receive(:query_service).and_return(query_service)
        allow(Hyrax.config).to receive(:use_valkyrie?).and_return(true)
        allow(Hyrax.config).to receive(:disable_wings).and_return(true)
        allow(query_service).to receive(:find_by_date_created).with(x_min, x_min).and_return([:w1, :w2])
        allow(query_service).to receive(:find_by_date_created).with(x_min, x_max).and_return([:w1, :w2, :w3, :w4])
      end

      it "counts growth using date-scoped query service results" do
        expect(subject_instance.points.to_a).to eq(
          [
            [x_min.to_date.to_s, 2],
            [x_max.to_date.to_s, 4]
          ]
        )
      end
    end
  end
end
