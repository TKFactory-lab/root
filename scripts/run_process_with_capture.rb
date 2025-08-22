#!/usr/bin/env ruby
# scripts/run_process_with_capture.rb
# Wrapper to run process_rfps.rb inside Rails and capture stdout/stderr to files in /tmp
require 'json'

out = []
begin
  out << "RUN_AT: #{Time.now}"
  script = File.expand_path('process_rfps.rb', __dir__)
  out << "LOADING: #{script}"
  # Prepare capture files
  stdout_path = '/tmp/process_wrapper_stdout.txt'
  stderr_path = '/tmp/process_wrapper_stderr.txt'
  File.open(stdout_path, 'w') {} unless File.exist?(stdout_path)
  File.open(stderr_path, 'w') {} unless File.exist?(stderr_path)

  File.open(stdout_path, 'w') do |sout|
    File.open(stderr_path, 'w') do |serr|
      orig_stdout = $stdout.dup
      orig_stderr = $stderr.dup
      $stdout.reopen(sout)
      $stderr.reopen(serr)
      $stdout.sync = true
      $stderr.sync = true
      begin
        load script
        out << 'LOAD_OK'
      rescue => e
        out << "EXCEPTION: #{e.class}: #{e.message}"
        out.concat e.backtrace
      ensure
        $stdout.reopen(orig_stdout)
        $stderr.reopen(orig_stderr)
      end
    end
  end
rescue => e
  out << "WRAPPER_ERROR: #{e.class}: #{e.message}"
  out.concat e.backtrace
end

File.write('/tmp/process_wrapper_log.txt', out.join("\n"))
puts out.join("\n")
