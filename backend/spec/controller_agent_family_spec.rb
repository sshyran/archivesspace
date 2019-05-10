require 'spec_helper'

describe 'Family agent controller' do

  def create_family(opts = {})
    create(:json_agent_family, opts)
  end


  it "lets you create a family and get them back" do
    opts = {:names => [build(:json_name_family)],
            :agent_contacts => [build(:json_agent_contact)]
            }

    id = create_family(opts).id
    expect(JSONModel(:agent_family).find(id).names.first['family_name']).to eq(opts[:names][0]['family_name'])
  end


  it "lets you update a family" do
    id = create_family(:agent_contacts => nil).id

    family = JSONModel(:agent_family).find(id)
    [0,1].each do |n|

      opts = {:name => generate(:generic_name)}
      family.agent_contacts << build(:json_agent_contact, opts)

      family.save

      expect(JSONModel(:agent_family).find(id).agent_contacts[n]['name']).to eq(opts[:name])
    end
  end

  it "sets the sort name if one is provided" do
    opts = {:names => [build(:json_name_family, :sort_name => "Custom Sort Name", :sort_name_auto_generate => false)]}

    id = create_family(opts).id
    expect(JSONModel(:agent_family).find(id).names.first['sort_name']).to eq(opts[:names][0]['sort_name'])
  end


  it "auto-generates the sort name if one is not provided" do
    id = create_family({:names => [build(:json_name_family,
                                         {:family_name => "Hendrix", :sort_name_auto_generate => true})]}).id

    agent = JSONModel(:agent_family).find(id)

    expect(agent.names.first['sort_name']).to match(/\AHendrix/)

    agent.names.first['qualifier'] = "FACT123"
    agent.save

    expect(JSONModel(:agent_family).find(id).names.first['sort_name']).to match(/\AHendrix.*\(FACT123\)/)
  end


  it "can give a list of family agents" do
    uris = (1...4).map {|_| create_family.uri}
    results = JSONModel(:agent_family).all(:page => 1)['results'].map {|rec| rec['uri']}

    expect((uris - results).length).to eq(0)
  end

  it "creates agent subrecords if appropriate" do
    agent_with_subrecs = build(:json_agent_family_full_subrec)  

    url = URI("#{JSONModel::HTTP.backend_url}/agents/families")
    response = JSONModel::HTTP.post_json(url, agent_with_subrecs.to_json)

    json_response = ASUtils.json_parse(response.body)

    expect(json_response["status"]).to eq("Created")
    agent_id = json_response["id"]

    expect(AgentRecordControl.where(:agent_family_id => agent_id).count).to eq(1)
    expect(AgentAlternateSet.where(:agent_family_id => agent_id).count).to eq(1)
    expect(AgentConventionsDeclaration.where(:agent_family_id => agent_id).count).to eq(1)
    expect(AgentSources.where(:agent_family_id => agent_id).count).to eq(1)
    expect(AgentOtherAgencyCodes.where(:agent_family_id => agent_id).count).to eq(1)
    expect(AgentMaintenanceHistory.where(:agent_family_id => agent_id).count).to eq(1)
    expect(AgentRecordIdentifier.where(:agent_family_id => agent_id).count).to eq(1)
  end


end
