FRAMEWORKS = begin
  attempt1 = "/Applications/Xcode.app/Contents/Developer/Library/Frameworks"
  if File.directory? "#{attempt1}/XCTest.framework"
    attempt1
  else
    "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks"
  end
end

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

def clone! repo
  Dir.chdir "/tmp" do
    system "git clone #{repo}"
  end unless File.directory? "/tmp/#{File.basename(repo)}"
end

def prepare!
  clone! "https://github.com/mxcl/ChuzzleKit"
  clone! "https://github.com/mxcl/OMGHTTPURLRQ"

  File.open('/tmp/PromiseKitTests.m', 'w') do |f|
    f.puts  # make line numbers correlate
    f.puts
    f.puts(OBJC.sub('#define URL', "#define URL @\"file:///tmp/hi.text\""))
  end
  
  File.open('/tmp/hi.text', 'w') do |f|
    f.print("hi")
  end
end

def compile!
  abort unless system <<-EOS
    clang -g -O0 -ObjC -F#{FRAMEWORKS} -I. -fmodules -fobjc-arc \
          -framework XCTest \
          -isystem/tmp/ChuzzleKit -isystem/tmp/OMGHTTPURLRQ \
          /tmp/PromiseKitTests.m \
          NSURLConnection+PromiseKit.m PMKPromise.m PMKPromise+When.m PMKPromise+Until.m \
          /tmp/ChuzzleKit/*.m /tmp/OMGHTTPURLRQ/*.m \
          -Wall -Weverything -Wno-unused-parameter -Wno-missing-field-initializers \
          -Wno-documentation -Wno-gnu-conditional-omitted-operand \
          -Wno-pointer-arith -Wno-disabled-macro-expansion \
          -Wno-gnu-statement-expression -Wno-strict-selector-match -Wno-vla \
          -Wno-selector -Wno-missing-prototypes -Wno-direct-ivar-access \
          -Wno-missing-noreturn -Wno-pedantic \
          -Wno-format-nonliteral \
          -Wno-incomplete-module -Wno-objc-interface-ivars \
          -Wno-auto-import \
          -headerpad_max_install_names \
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

if not ARGV.include? '-d'
  exit! test!.exitstatus
else
  system "lldb /tmp/PromiseKitTests"
  File.delete("/tmp/PromiseKitTests.m")
  File.delete("/tmp/PromiseKitTests")
  exit! 0
end
