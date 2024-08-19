# frozen_string_literal:true

RSpec.describe Sushi do
  describe '#coerce_to_date' do
    subject { described_class.coerce_to_date(given_date) }

    context 'with 2023-02-01' do
      let(:given_date) { '2023-02-01' }

      it { is_expected.to eq(Date.new(2023, 2, 1)) }
    end
    context 'with 2023-05' do
      let(:given_date) { '2023-05' }

      it { is_expected.to eq(Date.new(2023, 5, 1)) }
    end
    context 'with 2023' do
      let(:given_date) { '2023' }

      it 'will raise an error' do
        expect { subject }.to raise_exception(Sushi::Error::InvalidDateArgumentError)
      end
    end
  end

  describe '.first_month_available' do
    subject { described_class.first_month_available }

    let(:entry) do
      Hyrax::CounterMetric.create(
        worktype: 'GenericWork',
        resource_type: 'Book',
        work_id: '12345',
        date: entry_date,
        total_item_investigations: 1,
        total_item_requests: 10
      )
    end

    context 'when first entry date is middle of the month and current date is end of this month' do
      let(:current_date) { Time.zone.today.end_of_month }
      let(:entry_date) { 10.days.ago(current_date) }

      before { entry }

      it 'raises an error' do
        expect { subject }.to raise_error(Sushi::Error::UsageNotReadyForRequestedDatesError)
      end
    end

    context 'when first entry is the middle of two months ago and current date is middle of this month' do
      let(:current_date) { 10.days.ago(Time.zone.today.end_of_month) }
      let(:entry_date) { 10.days.ago(2.months.ago(Time.zone.today.end_of_month)) }

      before { entry }

      it 'will return the beginning of the month of the earliest entry' do
        expect(subject).to eq(entry_date.beginning_of_month)
      end
    end

    context 'when there are no entries' do
      it 'raises an error' do
        expect { subject }.to raise_error(Sushi::Error::UsageNotReadyForRequestedDatesError)
      end
    end
  end

  describe '.last_month_available' do
    subject { described_class.last_month_available }

    let(:entry) do
      Hyrax::CounterMetric.create(
        worktype: 'GenericWork',
        resource_type: 'Book',
        work_id: '12345',
        date: entry_date,
        total_item_investigations: 1,
        total_item_requests: 10
      )
    end
    let(:create_older_entry) do
      # Because sometimes we nee
      Hyrax::CounterMetric.create(
        worktype: 'GenericWork',
        resource_type: 'Book',
        work_id: '12345',
        date: 2.years.ago,
        total_item_investigations: 1,
        total_item_requests: 10
      )
    end

    context 'when we have one month of data and the current date is within that month' do
      let(:current_date) { Time.zone.today.end_of_month }
      let(:entry_date) { 5.days.ago(Time.zone.today.end_of_month) }

      before { entry }

      it 'raises an error' do
        expect { subject }.to raise_error(Sushi::Error::UsageNotReadyForRequestedDatesError)
      end
    end

    context 'when last entry date is middle of the month and current date is end of this month' do
      let(:current_date) { Time.zone.today.end_of_month }
      let(:entry_date) { 10.days.ago(current_date) }

      before do
        create_older_entry
        entry
      end
      it 'will use the end of the previous current month' do
        expect(subject).to eq(1.month.ago(current_date).end_of_month)
      end
    end

    context 'when last entry is the middle of two months ago and current date is middle of this month' do
      let(:current_date) { 10.days.ago(Time.zone.today.end_of_month) }
      let(:entry_date) { 10.days.ago(2.months.ago(Time.zone.today.end_of_month)) }

      before do
        create_older_entry
        entry
      end

      it 'will return the end of the month of the last entry' do
        expect(subject).to eq(entry_date.end_of_month)
      end
    end

    context 'when last entry date is beginning of the month and current entry date is beginning of the month' do
      let(:current_date) { Time.zone.today.beginning_of_month }
      let(:entry_date) { Time.zone.today.beginning_of_month }

      before do
        create_older_entry
        entry
      end

      it 'will return the end of the month prior to the last entry' do
        expect(subject).to eq(1.month.ago(current_date).end_of_month)
      end
    end

    context 'when there are no entries' do
      it 'raises an error' do
        expect { subject }.to raise_error(Sushi::Error::UsageNotReadyForRequestedDatesError)
      end
    end
  end

  describe '#validate_date_format' do
    context 'when the begin_date or end_date are in MM-YYYY format' do
      let(:dates) { ['06-2023', '08-2023'] }

      it 'raises an error' do
        expect { subject.validate_date_format(dates) }.to raise_error(Sushi::Error::InvalidDateArgumentError)
      end
    end

    context 'when the begin_date or end_date are in YYYY-MM-DD format' do
      let(:dates) { ['2023-06-05', '2023-08-09'] }

      before { Sushi.info = [] }

      it 'stores the exception' do
        expect(Sushi.info).to be_empty
        subject.validate_date_format(dates)
        expect(Sushi.info).not_to be_empty
        expect(Sushi.info.first).to be_a(Hash)
      end
    end
  end

  describe "AuthorCoercion" do
    describe '.deserialize' do
      subject { Sushi::AuthorCoercion.deserialize(string) }

      [
        ["|Hello|World|", ["Hello", "World"]],
        ["|Hello|", ["Hello"]],
        ["||", []],
        ["", []],
        [nil, []]
      ].each do |given_authors, expected_array|
        context "with #{given_authors.inspect}" do
          let(:string) { given_authors }

          it { is_expected.to match_array(expected_array) }
        end
      end
    end

    describe '.serialize' do
      subject { Sushi::AuthorCoercion.serialize(array) }

      [
        [["Hello", "World"], "|Hello|World|"],
        [["Hello"], "|Hello|"],
        [[], nil]
      ].each do |given_authors, expected|
        context "with #{given_authors.inspect}" do
          let(:array) { given_authors }

          it { is_expected.to eq(expected) }
        end
      end
    end

    describe '#coerce_author' do
      let(:klass) do
        Class.new do
          include Sushi::AuthorCoercion
          def initialize(params = {})
            coerce_author(params)
          end
        end
      end

      it "raises a 3060 error when given a #{Sushi::AuthorCoercion::DELIMITER} character" do
        expect { klass.new(author: "Hello#{Sushi::AuthorCoercion::DELIMITER}World") }.to raise_error(Sushi::Error::InvalidReportFilterValueError)
      end
    end
  end

  describe "YearOfPublicationCoercion" do
    subject(:instance) { klass.new(params) }

    let(:klass) do
      Class.new do
        include Sushi::YearOfPublicationCoercion
        def initialize(params = {})
          coerce_yop(params)
        end
      end
    end

    let(:params) { {} }

    it { is_expected.to respond_to(:yop_as_where_parameters) }

    context 'when no :yop is provided' do
      its(:yop_as_where_parameters) { is_expected.to be_falsey }
    end

    # rubocop:disable Layout/LineLength
    [
      ['2003', ["((year_of_publication = ?))", 2003]],
      ['2003-2005', ["((year_of_publication >= ? AND year_of_publication <= ?))", 2003, 2005]],
      ['2003a-2005', Sushi::Error::InvalidDateArgumentError],
      ['-1', ["((year_of_publication = ?))", -1]],
      ['a-1', Sushi::Error::InvalidDateArgumentError],
      ['a1', Sushi::Error::InvalidDateArgumentError],
      ['1-2 3', Sushi::Error::InvalidDateArgumentError],
      ['1 2', Sushi::Error::InvalidDateArgumentError],
      ['1996-1994', ["((year_of_publication >= ? AND year_of_publication <= ?))", 1996, 1994]],
      ['1996-1994 | 1999-2003|9a', Sushi::Error::InvalidDateArgumentError],
      ['1996-1994 | 1299-2003|9-12', ["((year_of_publication >= ? AND year_of_publication <= ?) OR (year_of_publication >= ? AND year_of_publication <= ?) OR (year_of_publication >= ? AND year_of_publication <= ?))", 1996, 1994, 1299, 2003, 9, 12]],
      ['1994-1996 | 1989', ["((year_of_publication >= ? AND year_of_publication <= ?) OR (year_of_publication = ?))", 1994, 1996, 1989]]
    ].each do |given_yop, expected|
      context "when given :yop parameter is #{given_yop.inspect}" do
        let(:params) { { yop: given_yop } }

        if expected.is_a?(Array)
          its(:yop) { is_expected.to eq(given_yop) }
          its(:yop_as_where_parameters) { is_expected.to match_array(expected) }
        else
          it "raises an #{expected}" do
            expect { subject }.to raise_error(expected)
          end
        end
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end
