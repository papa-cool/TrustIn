# frozen_string_literal: true

require File.join(File.dirname(__FILE__), "trustin")

RSpec.describe TrustIn do
  describe "#update_score()" do
    subject! { described_class.new(evaluations).update_score() }

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
        let(:evaluations) { [Evaluation.new(type: "SIREN", value: "832940670", score: 42, state: "unconfirmed", reason: "ongoing_database_update")] }

        it "assigns a <state> and a <reason> to the evaluation based on the API response and a <score> to 100" do
          expect(evaluations.first.state).to eq("favorable")
          expect(evaluations.first.reason).to eq("company_opened")
          expect(evaluations.first.score).to eq(100)
        end
      end

      context "with a <score> equal to 0" do
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
        let(:evaluations) { [Evaluation.new(type: "SIREN", value: "123456789", score: 0, state: "unfavorable", reason: "company_closed")] }

        it "does not call the API" do
          expect(Net::HTTP).not_to receive(:get)
        end
      end
    end
  end
end
