require 'pathname'

base = ARGV[0] || "."

Dir.glob("**/*.hs", base: base){|fname|
  s = File.read(File.join(base, fname))
  if s.gsub!(/[ \t]+$/, "")
    puts fname
    File.write(File.join(base, fname), s)
  end
}
