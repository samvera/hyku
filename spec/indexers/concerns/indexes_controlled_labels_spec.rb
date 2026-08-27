# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IndexesControlledLabels do
  let(:indexer) { Class.new { include IndexesControlledLabels }.new }
  let(:profile) do
    { 'properties' => {
      'rights_statement' => {
        'controlled_values' => { 'sources' => ['rights_statements'] },
        'indexing' => ['rights_statement_sim', 'rights_statement_tesim', 'facetable']
      },
      'title' => { 'indexing' => ['title_tesim'] }
    } }
  end

  before do
    allow(Hyrax.config).to receive(:flexible?).and_return(true)
    allow(Hyrax::FlexibleSchema).to receive(:order).with('created_at asc')
                                                   .and_return([instance_double(Hyrax::FlexibleSchema, profile: profile)])
  end

  def unbacked_service
    Module.new do
      def self.authority
        Qa::Authorities::Local.subauthority_for('does_not_exist')
      end

      def self.label(id, &block)
        authority.find(id).fetch('term', &block)
      end
    end
  end

  def relabel(doc)
    indexer.send(:relabel_controlled_values, doc)
  end

  it 'replaces a schemeless term id with its authority label' do
    Qa::LocalAuthorityEntry.create!(local_authority: Qa::LocalAuthority.find_or_create_by!(name: 'rights_statements'),
                                    uri: 'local_auth_123', label: 'Opaque Term', active: true)

    doc = relabel('rights_statement_tesim' => ['local_auth_123'])

    expect(doc['rights_statement_tesim']).to eq(['Opaque Term'])
  end

  it 'leaves an http uri alone so machine consumers still read it' do
    doc = relabel('rights_statement_tesim' => ['http://rightsstatements.org/vocab/InC/1.0/'])

    expect(doc['rights_statement_tesim']).to eq(['http://rightsstatements.org/vocab/InC/1.0/'])
  end

  it 'leaves a non-url uri alone' do
    doc = relabel('rights_statement_tesim' => ['info:lc/authorities/subjects/sh85021262'])

    expect(doc['rights_statement_tesim']).to eq(['info:lc/authorities/subjects/sh85021262'])
  end

  it 'keeps a value the authority does not know' do
    doc = relabel('rights_statement_tesim' => ['Ask the library'])

    expect(doc['rights_statement_tesim']).to eq(['Ask the library'])
  end

  it 'ignores indexing hints that are not solr fields' do
    expect { relabel('rights_statement_tesim' => ['Ask the library']) }.not_to raise_error
  end

  it 'leaves uncontrolled properties alone' do
    doc = relabel('title_tesim' => ['local_auth_123'])

    expect(doc['title_tesim']).to eq(['local_auth_123'])
  end

  it 'keeps the value when no authority backs the profile source' do
    allow(ApplicationController.helpers).to receive(:controlled_vocabulary_service_for)
      .with('rights_statements').and_return(unbacked_service)

    doc = relabel('rights_statement_tesim' => ['local_auth_123'])

    expect(doc['rights_statement_tesim']).to eq(['local_auth_123'])
  end

  it 'relabels a key shared by two properties once, using whichever authority knows the value' do
    profile['properties']['rights_statement_optional'] = {
      'controlled_values' => { 'sources' => ['flex_subjects'] },
      'indexing' => ['rights_statement_tesim']
    }
    Qa::LocalAuthorityEntry.create!(local_authority: Qa::LocalAuthority.find_or_create_by!(name: 'flex_subjects'),
                                    uri: 'other_auth_9', label: 'Other Term', active: true)

    doc = relabel('rights_statement_tesim' => ['other_auth_9'])

    expect(doc['rights_statement_tesim']).to eq(['Other Term'])
  end

  it 'does nothing when flexible metadata is off' do
    allow(Hyrax.config).to receive(:flexible?).and_return(false)

    doc = relabel('rights_statement_tesim' => ['local_auth_123'])

    expect(doc['rights_statement_tesim']).to eq(['local_auth_123'])
  end
end
