# frozen_string_literal: true

module Run
  class SimulationDetailed
    def initialize(app_config)
      @app_config = app_config
    end

    def run
      announce_replay_if_recorded
      summary = app_config.summary
      first_year_cash_flow_results = FirstYearCashFlow.new(app_config).calculate
      simulation_output = Simulation::Simulator.new(app_config).run
      evaluator_results = Simulation::SimulationEvaluator.new(simulation_output[:yearly_results], app_config).evaluate
      Output::ConsolePrinter.new(summary, simulation_output, first_year_cash_flow_results, evaluator_results).print_all
    end

    private

    attr_reader :app_config

    def announce_replay_if_recorded
      return unless app_config["return_sequence_type"] == "recorded"

      file_path = app_config["recorded_sequence_file"]
      sequence = ReturnSequences::RecordedSequence.new(
        app_config["retirement_age"], app_config["max_age"], file_path
      )
      label = sequence.summary || "from #{File.basename(file_path)}"
      puts "Replaying #{File.basename(file_path, '.yml')}: #{label}"
      warn_on_digest_mismatch(sequence)
    end

    def warn_on_digest_mismatch(sequence)
      stored = sequence.inputs_digest
      return if stored.nil? || stored == InputsDigest.for(app_config)

      puts "Note: inputs.yml has changed since this run was captured. " \
           "The original failure may not reproduce exactly."
    end
  end
end
