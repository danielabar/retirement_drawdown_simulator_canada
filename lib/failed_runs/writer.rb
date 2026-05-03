# frozen_string_literal: true

require "fileutils"

module FailedRuns
  # Orchestrates the capture of failed runs in success_rate mode:
  #   - prepare!: wipe prior run_*.yml + index.md from the directory
  #   - offer:    build a payload from a single failed run, feed it through
  #               the reservoir sampler (cap = CAPACITY)
  #   - flush!:   write the kept payloads as run_NNNN.yml files, plus index.md
  class Writer
    CAPACITY = 50
    DEFAULT_DIR = "failed_runs"

    def initialize(app_config, output_dir: DEFAULT_DIR, capacity: CAPACITY,
                   rng: Random.new, clock: -> { Time.now.utc })
      @app_config = app_config
      @output_dir = output_dir
      @capacity = capacity
      @clock = clock
      @sampler = ReservoirSampler.new(capacity, rng: rng)
      @max_age = app_config["max_age"]
      @inputs_digest = InputsDigest.for(app_config)
    end

    def prepare!
      FileUtils.mkdir_p(@output_dir)
      FileUtils.rm_f(Dir.glob(File.join(@output_dir, "run_*.yml")))
      FileUtils.rm_f(File.join(@output_dir, FailedRuns::Manifest::FILENAME))
      puts "Clearing #{@output_dir}/ from previous success_rate run."
    end

    def offer(simulation_output, evaluator_results)
      return if evaluator_results[:success]

      payload = build_payload(simulation_output, evaluator_results)
      @sampler.offer(payload)
    end

    def flush!
      kept = @sampler.to_a
      entries = write_payloads(kept)
      FailedRuns::Manifest.write(@output_dir, entries,
                                 captured_at: @clock.call,
                                 inputs_digest: @inputs_digest)
      puts "Saved #{kept.size} failed runs to #{@output_dir}/ " \
           "(#{kept.size}/#{@sampler.seen_count} failures kept; " \
           "see #{@output_dir}/#{FailedRuns::Manifest::FILENAME})."
    end

    private

    def write_payloads(payloads)
      payloads.each_with_index.map do |payload, idx|
        filename = filename_for(idx)
        payload["id"] = File.basename(filename, ".yml")
        FailedRuns::Serializer.write(File.join(@output_dir, filename), payload)
        { filename: filename, summary: payload.dig("outcome", "summary") }
      end
    end

    def filename_for(index)
      format("run_%04d.yml", index + 1)
    end

    def build_payload(simulation_output, evaluator_results)
      yearly = simulation_output[:yearly_results]
      last = yearly.last
      {
        "id" => nil,
        "captured_at" => @clock.call,
        "inputs_digest" => @inputs_digest,
        "outcome" => {
          "success" => false,
          "summary" => build_summary(last),
          "final_age" => last[:age],
          "final_balance" => last[:total_balance],
          "withdrawal_rate" => evaluator_results[:withdrawal_rate]
        },
        "return_sequence" => stringify_return_sequence(simulation_output[:return_sequence])
      }
    end

    def build_summary(last_row)
      balance = format_currency(last_row[:total_balance])
      return "ran out at age #{last_row[:age]}, final balance #{balance}" if last_row[:age] < @max_age

      threshold = @app_config["success_factor"] * @app_config["desired_spending"]
      "reached max_age #{@max_age} with #{balance} (below threshold #{format_currency(threshold)})"
    end

    def format_currency(amount)
      "$#{format('%.0f', amount)}"
    end

    def stringify_return_sequence(map)
      map.each_with_object({}) { |(age, rate), h| h[age.to_i] = rate.to_f }
    end
  end
end
