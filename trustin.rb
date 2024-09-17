require "json"
require "net/http"
require "logger"

class TrustIn
  def initialize(evaluations)
    @evaluations = evaluations
  end

  def update_score()
    @evaluations.each do |evaluation|
      if evaluation.type == "SIREN"
        if evaluation.score > 0 && evaluation.state == "unconfirmed" && evaluation.reason == "ongoing_database_update"
          data = SirenApiClient.call(evaluation.value)
          evaluation.state = data[:state]
          evaluation.reason = data[:reason]
          evaluation.score = data[:score]
        elsif evaluation.score >= 50
          if evaluation.state == "unconfirmed" && evaluation.reason == "unable_to_reach_api"
            evaluation.score = evaluation.score - 5
          elsif evaluation.state == "favorable"
            evaluation.score = evaluation.score - 1
          end
        elsif evaluation.score <= 50 && evaluation.score > 0
          if evaluation.state == "unconfirmed" && evaluation.reason == "unable_to_reach_api" || evaluation.state == "favorable"
            evaluation.score = evaluation.score - 1
          end
        else
          if evaluation.state == "favorable" || evaluation.state == "unconfirmed"
            data = SirenApiClient.call(evaluation.value)
            evaluation.state = data[:state]
            evaluation.reason = data[:reason]
            evaluation.score = data[:score]
          end
        end
      end
    end
  end
end

class Evaluation
  attr_accessor :type, :value, :score, :state, :reason

  def initialize(type:, value:, score:, state:, reason:)
    @type = type
    @value = value
    @score = score
    @state = state
    @reason = reason
  end

  def to_s
    "#{@type}, #{@value}, #{@score}, #{@state}, #{@reason}"
  end
end

class SirenApiClient
  BASE_URL = "https://public.opendatasoft.com/api/records/1.0/search/"
  ACTIF_COMPANY_STATE = "Actif"

  @@logger = Logger.new(STDOUT)

  def self.call(siren)
    new(siren).call
  end

  def call
    if company_state_actif?(JSON.parse(fetch_company_state))
      {
        state: "favorable",
        reason: "company_opened",
        score: 100
      }
    else
      {
        state: "unfavorable",
        reason: "company_closed",
        score: 100
      }
    end
  rescue => error
    @@logger.error("Error in SirenApiClient: #{error.message}")
    {
      state: "unconfirmed",
      reason: "unable_to_reach_api",
      score: 100
    }
  end

  def initialize(siren)
    @siren = siren
  end

  private

  def fetch_company_state
    uri = URI("#{BASE_URL}?dataset=economicref-france-sirene-v3" \
              "&q=#{URI.encode_www_form_component(@siren)}" \
              "&sort=datederniertraitementetablissement" \
              "&refine.etablissementsiege=oui")
    Net::HTTP.get(uri)
  end

  def company_state_actif?(payload)
    payload["records"].first["fields"]["etatadministratifetablissement"] == ACTIF_COMPANY_STATE
  end
end
