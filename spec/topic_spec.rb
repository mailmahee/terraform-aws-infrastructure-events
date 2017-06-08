require 'spec_helper'
require 'json'
require 'pp'

describe 'Topic' do
  include_context :terraform

  let(:topic_name_prefix) {RSpec.configuration.topic_name_prefix}
  let(:bucket_name_prefix) {RSpec.configuration.bucket_name_prefix}
  let(:region) {RSpec.configuration.region}
  let(:deployment_identifier) {RSpec.configuration.deployment_identifier}

  let(:topics) do
    sns_client.list_topics.data[:topics].map do |topic|
      sns_client.get_topic_attributes(topic_arn: topic[:topic_arn])
    end
  end

  let(:bucket) do
    s3_bucket("#{bucket_name_prefix}-#{region}-#{deployment_identifier}")
  end

  subject do
    topics.find do |topic|
      topic.attributes['DisplayName'] ==
          "#{topic_name_prefix}-#{region}-#{deployment_identifier}"
    end
  end

  it { should_not be_nil }

  it 'allows publishing from the infrastructure events bucket' do
    policy = JSON.parse(subject.attributes['Policy'])
    statement = policy['Statement'][0]

    expect(statement['Effect']).to eq('Allow')
    expect(statement['Principal']['Service']).to eq('s3.amazonaws.com')
    expect(statement['Action']).to eq('SNS:Publish')
    expect(statement['Resource']).to eq(subject.attributes['TopicArn'])
    expect(statement['Condition']['ArnLike']['aws:SourceArn'])
        .to(eq("arn:aws:s3:::#{bucket.name}"))
  end
end