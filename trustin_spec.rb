# frozen_string_literal: true

require 'vcr'
require 'webmock/rspec'

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = false
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

require File.join(File.dirname(__FILE__), "trustin")

RSpec.describe TrustIn do
  describe "#update_score()" do
    let(:clients_apis) { {} }
    subject! { described_class.new(evaluations, **clients_apis).update_score() }

    context "when the evaluation type is 'SIREN'" do
      context "with a <score> greater or equal to 50 AND the <state> is unconfirmed and the <reason> is 'unable_to_reach_api'" do
        let(:evaluations) { [Evaluation.new(type: "SIREN", value: "123456789", score: 79, state: "unconfirmed", reason: "unable_to_reach_api")] }

        it "decreases the <score> of 5" do
          expect(evaluations.first.score).to eq(74)
        end
      end

      context "when the <state> is unconfirmed and the <reason> is 'unable_to_reach_api'" do
        let(:evaluations) { [Evaluation.new(type: "SIREN", value: "123456789", score: 37, state: "unconfirmed", reason: "unable_to_reach_api")] }

        it "decreases the <score> of 1" do
          expect(evaluations.first.score).to eq(36)
        end
      end

      context "when the <state> is favorable" do
        let(:evaluations) { [Evaluation.new(type: "SIREN", value: "123456789", score: 28, state: "favorable", reason: "company_opened")] }

        it "decreases the <score> of 1" do
          expect(evaluations.first.score).to eq(27)
        end
      end

      context "when the <state> is 'unconfirmed' AND the <reason> is 'ongoing_database_update'" do
        let(:clients_apis) do
          api = Class.new do
            def self.call(value)
              {state: "favorable", reason: "company_opened", score: 100}
            end
          end
          {siren: api}
        end
        let(:evaluations) { [Evaluation.new(type: "SIREN", value: "832940670", score: 42, state: "unconfirmed", reason: "ongoing_database_update")] }

        it "assigns a <state> and a <reason> to the evaluation based on the API response and a <score> to 100" do
          expect(evaluations.first.state).to eq("favorable")
          expect(evaluations.first.reason).to eq("company_opened")
          expect(evaluations.first.score).to eq(100)
        end
      end

      context "with a <score> equal to 0" do
        let(:clients_apis) do
          api = Class.new do
            def self.call(value)
              {state: "unfavorable", reason: "company_closed", score: 100}
            end
          end
          {siren: api}
        end
        let(:evaluations) { [Evaluation.new(type: "SIREN", value: "320878499", score: 0, state: "favorable", reason: "company_opened")] }

        it "assigns a <state> and a <reason> to the evaluation based on the API response and a <score> to 100" do
          expect(evaluations.first.state).to eq("unfavorable")
          expect(evaluations.first.reason).to eq("company_closed")
          expect(evaluations.first.score).to eq(100)
        end
      end

      context "with a <state> 'unfavorable'" do
        let(:evaluations) { [Evaluation.new(type: "SIREN", value: "123456789", score: 52, state: "unfavorable", reason: "company_closed")] }

        it "does not decrease its <score>" do
          expect { subject }.not_to change { evaluations.first.score }
        end
      end

      context "with a <state>'unfavorable' AND a <score> equal to 0" do
        let(:clients_apis) do
          api = Class.new do
            def self.call(value)
              {state: "unfavorable", reason: "company_closed", score: 100}
            end
          end
          {siren: api}
        end
        let(:evaluations) { [Evaluation.new(type: "SIREN", value: "123456789", score: 0, state: "unfavorable", reason: "company_closed")] }

        it "does not call the API" do
          expect(evaluations.first.score).not_to eq(100)
        end
      end
    end

    context "when the evaluation type is 'VAT'" do
      context "with a <state> 'unfavorable'" do
        let(:evaluations) { [Evaluation.new(type: "VAT", value: "123456789", score: 52, state: "unfavorable", reason: "company_closed")] }

        it "does not decrease its <score>" do
          expect(evaluations.first.score).to eq(52)
        end
      end

      context "with a <state>'unfavorable' AND a <score> equal to 0" do
        let(:clients_apis) do
          api = Class.new do
            def self.call(value)
              {state: "unfavorable", reason: "company_closed", score: 100}
            end
          end
          {vat: api}
        end
        let(:evaluations) { [Evaluation.new(type: "VAT", value: "123456789", score: 0, state: "unfavorable", reason: "company_closed")] }

        it "does not call the API" do
          expect(evaluations.first.score).not_to eq(100)
        end
      end

      context "with a <state> 'unconfirmed' AND a <reason> 'ongoing_database_update'" do
        let(:clients_apis) do
          api = Class.new do
            def self.call(value)
              {state: "favorable", reason: "company_opened", score: 100}
            end
          end
          {vat: api}
        end
        let(:evaluations) { [Evaluation.new(type: "VAT", value: "123456789", score: 23, state: "unconfirmed", reason: "ongoing_database_update")] }

        it "assigns a <state> and a <reason> to the evaluation based on the API response and a <score> to 100" do
          expect(evaluations.first.state).to eq("favorable")
          expect(evaluations.first.reason).to eq("company_opened")
          expect(evaluations.first.score).to eq(100)
        end
      end

      context "with a <score> of 0" do
        let(:clients_apis) do
          api = Class.new do
            def self.call(value)
              {state: "unfavorable", reason: "company_closed", score: 100}
            end
          end
          {vat: api}
        end
        let(:evaluations) { [Evaluation.new(type: "VAT", value: "123456789", score: 0, state: "favorable", reason: "company_opened")] }

        it "assigns a <state> and a <reason> to the evaluation based on the API response and a <score> to 100" do
          expect(evaluations.first.state).to eq("unfavorable")
          expect(evaluations.first.reason).to eq("company_closed")
          expect(evaluations.first.score).to eq(100)
        end
      end

      context "with a <score> greater or equal to 50 AND the <state> is unconfirmed and the <reason> is 'unable_to_reach_api'" do
        let(:evaluations) { [Evaluation.new(type: "VAT", value: "123456789", score: 79, state: "unconfirmed", reason: "unable_to_reach_api")] }

        it "decreases the <score> of 1" do
          expect(evaluations.first.score).to eq(78)
        end
      end

      context "with a <score> lower than 50 AND the <state> is unconfirmed and the <reason> is 'unable_to_reach_api'" do
        let(:evaluations) { [Evaluation.new(type: "VAT", value: "123456789", score: 42, state: "unconfirmed", reason: "unable_to_reach_api")] }

        it "decreases the <score> of 3" do
          expect(evaluations.first.score).to eq(39)
        end
      end
      

    end
  end
end

RSpec.describe SirenApiClient do
  around do |example|
    VCR.use_cassette(vcr_cassette_name) do
      example.run
    end
  end

  subject { described_class.call(siren) }

  context "when the company state is 'Actif'" do
    let(:vcr_cassette_name) { "siren_api_client/actif" }

    let(:siren) { "832940670" }

    it { is_expected.to eq({state: "favorable", reason: "company_opened", score: 100}) }
  end

  context "when the company state is not 'Actif'" do
    let(:vcr_cassette_name) { "siren_api_client/inactif" }
    let(:siren) { "320878499" }

    it { is_expected.to eq({state: "unfavorable", reason: "company_closed", score: 100}) }
  end

  context "when the API is down" do
    let(:vcr_cassette_name) { "siren_api_client/down" }
    let(:siren) { "123456789" }

    it { is_expected.to eq({state: "unconfirmed", reason: "unable_to_reach_api", score: 100}) }
  end
end