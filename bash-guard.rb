#!/usr/bin/env ruby
# frozen_string_literal: true

require 'file_discard'
require 'listen'
require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'null_logger'
require 'terminal-notifier'

Listen.logger = NullLogger.new

def notify(message)
  TerminalNotifier.notify(
    message,
    title: 'Bash Guard'
  )
  sleep 2
end

def judge(options)
  watch_directory(options.directory) do |file_path|
    next unless shell_file?(file_path)

    file_length(file_path) do |length|
      case length
        when 0..options.snark
          next
        when (options.snark + 1)..options.passive
          notify('hey there')
          notify('see you\'re writing a shell script')
          notify('not how i\'d do it but it will work')
          notify('...')
          notify('i guess :|')
        when (options.passive + 1)..options.just
          notify('still at it, i see')
          notify('maybe you meant to write this in ruby or python?')
          notify('i\'ll fix that for you')
          notify('...')
          notify('...')
          change_file_shebang(file_path)
          notify('FIXED!')
        else
          notify('this is getting a bit big, don\'t you think?')
          notify('i\'ll optimize it for you')
          notify('...')
          notify('...')
          trash_file(file_path)
          notify('OPTIMIZED!')
      end
    end
  end
end

def change_file_shebang(file_path)
  rd = IO.read(file_path)
  IO.write(file_path, "#!/usr/bin/env ruby\n" + rd)
end

def trash_file(file_path)
  FileDiscard.discard(file_path)
end

def watch_directory(directory_path)
  listener = Listen.to(
    directory_path,
    ignore: /\.idea/
  ) do |modified, added|
    (modified + added).each do |file_path|
      yield file_path
    end
  end
  listener.start
  sleep
end

def shell_file?(file_path)
  shell_shebang?(file_path)
end

def shell_shebang?(file_path)
  file = File.open(file_path, 'r')
  first_line = file.readline
  return true if first_line =~ /#!.*?sh ?/i
  false
end

def file_length(file_path)
  yield File.read(file_path).scan(/\n/).count
end

def parse_argv(argv)
  parsed_options = OpenStruct.new
  parsed_options.snark = 5
  parsed_options.passive = 25
  parsed_options.just = 50

  option_parser = OptionParser.new do |options|
    options.banner = 'Usage: bash-guard [OPTIONS] DIRECTORY'

    options.separator ''
    options.separator 'Guards against bash'
    options.separator ''
    options.separator 'OPTIONS:'

    options.on('-s', '--snark lower threshold for snarkiness') do |snark|
      parsed_options.snark = Integer(snark)
    end
    options.on('-p', '--passive-aggressive lower threshold for passive-aggresiveness') do |passive|
      parsed_options.passive = Integer(passive)
    end
    options.on('-j', '--truly-just lower threshold for great justice') do |just|
      parsed_options.just = Integer(just)
    end

    options.on_tail('-h', '--help', 'Show this message') do
      puts options
      exit
    end
  end
  option_parser.parse!(argv)
  parsed_options.directory = argv.pop
  abort(option_parser.help) unless parsed_options.directory
  parsed_options
end

def main(_args)
  options = parse_argv(ARGV)
  judge(options)
rescue SystemExit, Interrupt
end

main(ARGV) if File.absolute_path($PROGRAM_NAME) == File.absolute_path(__FILE__)
