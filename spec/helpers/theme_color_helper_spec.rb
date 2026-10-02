# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThemeColorHelper, type: :helper do
  let(:white) { '#ffffff' }
  let(:hero_ground) { '#2c2b29' }
  let(:light_plate_worst) { helper.theme_mix('#000000', '#ffffff', 0.92) }
  let(:dark_plate_worst) { helper.theme_mix('#ffffff', '#141312', 0.78) }

  links = {
    'default' => '#2a6aa3',
    'red' => '#b3261e',
    'green' => '#2e7d32',
    'near-limit' => '#4274a8',
    'too light' => '#4f7cac',
    'dark' => '#1a1a1a'
  }

  describe '#theme_darken_until' do
    it 'darkens a color until it clears 4.5:1 on white, keeping its hue' do
      checked = helper.theme_darken_until('#4f7cac', white, 4.5)

      expect(helper.theme_contrast('#4f7cac', white)).to be < 4.5
      expect(helper.theme_contrast(checked, white)).to be >= 4.5
      expect(helper.theme_hue_shift(checked, '#4f7cac')).to be < 1
    end

    it 'keeps a color that already passes' do
      expect(helper.theme_darken_until('#2a6aa3', white, 4.5)).to eq('#2a6aa3')
    end
  end

  describe '#theme_lighten_until' do
    it 'gives the default on-dark link from the default admin link' do
      expect(helper.theme_lighten_until('#2a6aa3', dark_plate_worst, 5)).to eq('#9cc3e5')
    end

    it 'keeps the hue while lightening' do
      lifted = helper.theme_lighten_until('#b3261e', dark_plate_worst, 5)

      expect(helper.theme_hue_shift(lifted, '#b3261e')).to be < 2
      expect(helper.theme_contrast(lifted, dark_plate_worst)).to be >= 5
    end
  end

  describe '#theme_status_color' do
    links.each do |name, link|
      context "with a #{name} link color" do
        let(:checked) { helper.theme_darken_until(link, white, 4.5) }

        %i[danger success].each do |status|
          it "keeps #{status} within 20 degrees of its base hue and at 4.5:1 on white" do
            color = helper.theme_status_color(status, checked)
            base = ThemeColorHelper::THEME_STATUS_BASE.fetch(status)

            expect(helper.theme_hue_shift(color, base)).to be <= 20
            expect(helper.theme_contrast(color, white)).to be >= 4.5
          end

          it "keeps the on-dark #{status} at 4.5:1 on the hero ground" do
            color = helper.theme_on_dark(helper.theme_status_color(status, checked), hero_ground)

            expect(helper.theme_contrast(color, hero_ground)).to be >= 4.5
          end
        end
      end
    end

    it 'drops the blend for danger when the link is itself red' do
      expect(helper.theme_status_color(:danger, '#b3261e')).to eq(helper.theme_darken_until('#b4433c', white, 4.5))
    end

    it 'drops the blend for success when the link is itself green' do
      expect(helper.theme_status_color(:success, '#2e7d32')).to eq(helper.theme_darken_until('#3c763d', white, 4.5))
    end
  end

  describe '#theme_visited_color' do
    it 'gives the spec values for the default link' do
      visited = helper.theme_visited_color('#2a6aa3', light_plate_worst)

      expect(visited).to eq('#5b2aa3')
      expect(helper.theme_on_dark(visited, dark_plate_worst)).to eq('#c6b4df')
    end

    links.each do |name, link|
      it "never reads as red or green and clears both plates for a #{name} link" do
        visited = helper.theme_visited_color(helper.theme_darken_until(link, white, 4.5), light_plate_worst)
        on_dark = helper.theme_on_dark(visited, dark_plate_worst)

        expect(helper.theme_reddish?(visited) || helper.theme_greenish?(visited)).to be(false)
        expect(helper.theme_contrast(visited, light_plate_worst)).to be >= 4.5
        expect(helper.theme_contrast(on_dark, dark_plate_worst)).to be >= 4.5
      end
    end
  end
end
