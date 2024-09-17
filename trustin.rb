require "json"
require "net/http"
require "logger"

class TrustIn
  def initialize(evaluations, clients_apis = {siren: SirenApiClient})
    @evaluations = evaluations
    @clients_apis = clients_apis
  end

  def update_score()
    @evaluations.each do |evaluation|
      case evaluation.type
      when "SIREN" then update_siren_evaluation(evaluation)
      end
    end
  end

  private

  def update_siren_evaluation(evaluation)
    if evaluation.unfavorable?
      # When the state is unfavorable, the company evaluation's score does not decrease (a closed company will never open again)
      return
    elsif evaluation.score == 0 || evaluation.unconfirmed? && evaluation.ongoing_database_update?
      # A new evaluation is done when:
      # - the state is unconfirmed for an ongoing api database update;
      # - the current score is equal to 0;
      evaluation.reset(@clients_apis[:siren].call(evaluation.value))

    elsif evaluation.favorable?
      # When the state is favorable, the company evaluation's score decreases of 1 point (on the contrary, a company can close so an evaluation should be challenged again after some time)
      evaluation.decrease_score(1)
    elsif evaluation.unconfirmed? && evaluation.unable_to_reach_api?
      # When the state is unconfirmed because the api is unreachable:
      # - If the current score is equal or greater than 50, the Siren evaluation's score decreases of 5 points;
      # - If the current score is lower than 50, the Siren evaluation's score decreases of 1 point;
      evaluation.decrease_score(evaluation.score >= 50 ? 5 : 1)
    end
  end
end

class Evaluation
  UNFAVORABLE = "unfavorable"
  FAVORABLE = "favorable"
  UNCONFIRMED = "unconfirmed"
  ONGOING_DATABASE_UPDATE = "ongoing_database_update"
  UNABLE_TO_REACH_API = "unable_to_reach_api"

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

  def unfavorable?
    @state == UNFAVORABLE
  end

  def favorable?
    @state == FAVORABLE
  end

  def unconfirmed?
    @state == UNCONFIRMED
  end

  def ongoing_database_update?
    @reason == ONGOING_DATABASE_UPDATE
  end

  def unable_to_reach_api?
    @reason == UNABLE_TO_REACH_API
  end

  def decrease_score(value)
    # The score cannot go below 0
    @score -= value
    @score = 0 if @score < 0
  end

  def reset(data)
    @score = data[:score]
    @state = data[:state]
    @reason = data[:reason]
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
      @@logger.debug("Company #{@siren} is actif")
      {
        state: Evaluation::FAVORABLE,
        reason: "company_opened",
        score: 100
      }
    else
      @@logger.debug("Company #{@siren} is not actif")
      {
        state: Evaluation::UNFAVORABLE,
        reason: "company_closed",
        score: 100
      }
    end
  rescue => error
    @@logger.error("Error in SirenApiClient: #{error.message}")
    {
      state: Evaluation::UNCONFIRMED,
      reason: Evaluation::UNABLE_TO_REACH_API,
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
