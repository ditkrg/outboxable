# frozen_string_literal: true
require 'sidekiq/testing' 

RSpec.describe Outboxable do
  it "has a version number" do
    expect(Outboxable::VERSION).not_to be nil
  end

  context 'polling publisher sidekiq worker' do
    it "should be able to perform" do
      expect {
        Outboxable::PollingPublisherWorker.perform_async
      }.to change(Outboxable::PollingPublisherWorker.jobs, :size).by(1)
    end
  end
end
