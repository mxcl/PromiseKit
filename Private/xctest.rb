FRAMEWORKS = "/Applications/Xcode.app/Contents/Developer/Library/Frameworks"

def bold(s); s; end
def red(s); "\e[31m#{s}\e[0m"; end
def green(s); "\e[32m#{s}\e[0m"; end
def tab(n, s); s.gsub(/^/, " " * n); end
def log(message); $stdout.puts(message); end

def each_test_line
  require "stringio"
  require "open3"

  Open3.popen3("/tmp/PromiseKitTests") do |stdin, stdout, stderr, wait_thr|
    while line = stderr.gets
      yield line, stderr
    end
    exit_status = wait_thr.value
  end
end

def test!
  test_method = nil
  each_test_line do |line, stderr|
    case line
    when /Test Suite '(.*)' started/
      log bold($1) unless $1 == 'tmp'
    when /Test Suite '.*' finished/
    when /\[(\w+) (\w+)\]' started.$/
      test_method = $2
    when /\s(passed|failed)\s\((.*)\)/
      result = if $1 == "passed"
        green("PASS") 
      else
        red("FAIL")
      end
      result = tab(2, result)
      time = $2.gsub(/\sseconds/, "s")
      log "#{result} #{test_method} (#{time})"
    when /^(Executed(.?)+)$/
      if stderr.eof?
        summary = $1
        if /(\d+) failures?/.match(summary)[1] == "0"
          summary.gsub!(/(\d+ failures?)/, green('\1'))
        else
          summary.gsub!(/(\d+ failures?)/, red('\1'))
        end
        log summary
      end
    else
      log line.strip
    end
  end
end

def prepare!
  Dir.chdir "/tmp" do
    system "git clone https://github.com/mxcl/ChuzzleKit"
  end unless File.directory? "/tmp/ChuzzleKit"

  File.open('/tmp/PromiseKitTests.m', 'w') do |f|
    f.puts("\n\n")  # make line numbers correlate
    f.puts(OBJC)
  end
end

def compile!
  abort unless system <<-EOS
    clang -g -O0 -ObjC -F#{FRAMEWORKS} -I. -fmodules -fobjc-arc \
          -framework XCTest \
          -I/tmp/ChuzzleKit \
          /tmp/PromiseKitTests.m \
          /tmp/ChuzzleKit/*.m \
          -Wall -Weverything -Wno-unused-parameter -Wno-missing-field-initializers \
          -Wno-documentation -Wno-gnu-conditional-omitted-operand \
          -Wno-pointer-arith -Wno-disabled-macro-expansion \
          -Wno-gnu-statement-expression -Wno-strict-selector-match -Wno-vla \
          -Wno-selector -Wno-missing-prototypes -Wno-direct-ivar-access \
          -Wno-missing-noreturn -Wno-pedantic \
          -Wno-format-nonliteral \
          -Wno-incomplete-module \
          -o /tmp/PromiseKitTests
  EOS
  abort unless system <<-EOS
      install_name_tool -change \
          @rpath/XCTest.framework/Versions/A/XCTest \
          #{FRAMEWORKS}/XCTest.framework/XCTest \
          /tmp/PromiseKitTests
  EOS
end

prepare!
compile!

begin              
  require 'webrick'
  require 'sinatra/base'
  require 'logger'
rescue LoadError
  abort "gem install sinatra webrick"
end

class PMKHTTPD < Sinatra::Base
  set :port, 61231
  set :server_settings, {AccessLog: [], Logger: WEBrick::Log::new("/dev/null", 7)}
  set :logging, false
  get '/' do
    content_type 'text/plain', :charset => 'utf-8'
    'hi'
  end
end

PMKHTTPD.run! do
  Thread.new do
    if not ARGV.include? '-d'
      exit! test!.exitstatus
    else
      system "lldb /tmp/PromiseKitTests"
      File.delete("/tmp/PromiseKitTests.m")
      File.delete("/tmp/PromiseKitTests")
      exit! 0
    end
  end
end
