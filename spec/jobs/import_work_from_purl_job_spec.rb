RSpec.describe ImportWorkFromPurlJob do
  let(:user) { create(:user) }
  let(:log) { Hyrax::Operation.create!(user: user, operation_type: "Import Purl Metadata") }
  let(:druid) { 'bc390xk2647' }
  before do
    stub_request(:get, "https://purl.stanford.edu/bc390xk2647.xml")
      .to_return(status: 200, body: purl_xml)
    ActiveFedora::Base.find(druid).destroy(eradicate: true) if ActiveFedora::Base.exists? druid
    Hyrax::PermissionTemplate.create!(source_id: AdminSet::DEFAULT_ID)
    # Don't call load_workflows until the PermissionTemplate has been created
    Hyrax::Workflow::WorkflowImporter.load_workflows
  end
  let(:purl_xml) do
    <<~EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <publicObject id="druid:bc390xk2647" published="2016-11-16T20:44:34Z" publishVersion="dor-services/5.11.0">
        <identityMetadata>
          <sourceId source="Stanford Historical Photograph Collection">12415</sourceId>
          <objectId>druid:bc390xk2647</objectId>
          <objectCreator>DOR</objectCreator>
          <objectLabel>Lake Lagunita</objectLabel>
          <objectType>item</objectType>
          <adminPolicy>druid:kz949yf0754</adminPolicy>
          <otherId name="uuid">29164b40-9b88-11e2-bae9-0050569b52d5</otherId>
          <tag>Project : Stanford Historical Photograph Collection</tag>
          <tag>Remediated By : 5.10.1</tag>
        </identityMetadata>
        <contentMetadata type="image" objectId="bc390xk2647">
          <resource type="image" sequence="1" id="bc390xk2647_1">
            <label>Image 1</label>
            <file id="00007845_005.jp2" mimetype="image/jp2" size="4487344">
              <imageData width="4916" height="6209"/>
            </file>
          </resource>
          <resource type="image" sequence="2" id="bc390xk2647_2">
            <label>Image 2</label>
            <file id="00007845_MASTER_005.jp2" mimetype="image/jp2" size="5356683">
              <imageData width="5082" height="7015"/>
            </file>
          </resource>
        </contentMetadata>
        <rightsMetadata objectId="druid:kz949yf0754">
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <world/>
            </machine>
          </access>
          <use>
            <human type="useAndReproduction">Property rights reside with the repository. Literary rights reside with the creators of the documents or their heirs. To obtain permission to publish or reproduce, please contact the Special Collections Public Services Librarian at speccollref@stanford.edu.</human>
          </use>
        </rightsMetadata>
        <rdf:RDF xmlns:fedora="info:fedora/fedora-system:def/relations-external#" xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:hydra="http://projecthydra.org/ns/relations#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <rdf:Description rdf:about="info:fedora/druid:bc390xk2647">
            <fedora:isMemberOf rdf:resource="info:fedora/druid:kx532cb7981"/>
            <fedora:isMemberOfCollection rdf:resource="info:fedora/druid:kx532cb7981"/>
          </rdf:Description>
        </rdf:RDF>
        <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:srw_dc="info:srw/schema/1/dc-schema" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
          <dc:type>StillImage</dc:type>
          <dc:title>Lake Lagunita</dc:title>
          <dc:type>photographic prints</dc:type>
          <dc:date>1887-1996</dc:date>
          <dc:format>1 photograph; 4 in. x 6 in.</dc:format>
          <dc:format>black and white photographic print</dc:format>
          <dc:format>image/jpeg</dc:format>
          <dc:language>eng</dc:language>
          <dc:description>Digitized by Stanford University Libraries.</dc:description>
          <dc:subject>Lakes</dc:subject>
          <dc:subject>Lake Lagunita (Calif.)</dc:subject>
          <dc:subject>College campuses</dc:subject>
          <dc:identifier>9650</dc:identifier>
          <dc:relation type="repository">Stanford University. Libraries. Department of Special Collections and University Archives Series: General Photographs, Box: 25, Folder: Lake Lagunita -- #3 SC1071</dc:relation>
          <dc:relation type="collection">Stanford historical photograph collection, 1887-circa 1996 (inclusive)</dc:relation>
        </oai_dc:dc>
        <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.5" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd">
          <typeOfResource>still image</typeOfResource>
          <titleInfo>
            <title>Lake Lagunita</title>
          </titleInfo>
          <genre authority="aat" valueURI="http://vocab.getty.edu/aat/300127104">photographic prints</genre>
          <originInfo>
            <dateCreated keyDate="yes" encoding="w3cdtf" qualifier="approximate" point="start">1887</dateCreated>
            <dateCreated encoding="w3cdtf" qualifier="approximate" point="end">1996</dateCreated>
          </originInfo>
          <physicalDescription>
            <form>black and white photographic print</form>
            <extent>1 photograph; 4 in. x 6 in.</extent>
            <internetMediaType>image/jpeg</internetMediaType>
            <digitalOrigin>reformatted digital</digitalOrigin>
          </physicalDescription>
          <language>
            <languageTerm type="code" authority="iso639-2b">eng</languageTerm>
          </language>
          <note>Digitized by Stanford University Libraries.</note>
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh85074030">
            <topic>Lakes</topic>
          </subject>
          <subject authority="local">
            <topic>Lake Lagunita (Calif.)</topic>
          </subject>
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh2006002824">
            <topic>College campuses</topic>
          </subject>
          <identifier type="local" displayLabel="SHPC Photo ID">9650</identifier>
          <location>
            <physicalLocation type="repository" authority="naf" authorityURI="http://id.loc.gov/authorities/names" valueURI="http://id.loc.gov/authorities/names/no2014019980">Stanford University. Libraries. Department of Special Collections and University Archives</physicalLocation>
            <physicalLocation type="location">Series: General Photographs, Box: 25, Folder: Lake Lagunita -- #3</physicalLocation>
            <shelfLocator>SC1071</shelfLocator>
          </location>
          <relatedItem type="host" displayLabel="Series">
            <titleInfo>
              <title>General Photographs</title>
            </titleInfo>
          </relatedItem>
          <recordInfo>
            <recordContentSource authority="marcorg">CSt</recordContentSource>
            <recordOrigin>Transformed from legacy Luna Insight data, Luna Object ID 12415</recordOrigin>
            <languageOfCataloging>
              <languageTerm authority="iso639-2b">eng</languageTerm>
            </languageOfCataloging>
          </recordInfo>
          <relatedItem type="host">
            <titleInfo>
              <title>Stanford historical photograph collection, 1887-circa 1996 (inclusive)</title>
            </titleInfo>
            <location>
              <url>https://purl.stanford.edu/kx532cb7981</url>
            </location>
            <typeOfResource collection="yes"/>
          </relatedItem>
          <accessCondition type="useAndReproduction">Property rights reside with the repository. Literary rights reside with the creators of the documents or their heirs. To obtain permission to publish or reproduce, please contact the Special Collections Public Services Librarian at speccollref@stanford.edu.</accessCondition>
        </mods>
        <releaseData>
          <release to="Searchworks">true</release>
        </releaseData>
        <thumb>bc390xk2647/00007845_005.jp2</thumb>
      </publicObject>
EOF
  end

  it "works" do
    expect(CreateWorkJob).to receive(:perform_later)
    described_class.perform_now(user, druid, log)
  end
end
