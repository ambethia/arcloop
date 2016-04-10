require 'neatjson'

desc 'Build swflux cli tool'
task :swflux do
  Dir.chdir('./swflux') do
    system 'haxe build.hxml'
  end
end

desc 'Convert test swfs to json'
task :convert => [:swflux] do
  Dir.glob('./swflux/test/*.swf').each do |file|
    puts "Converting... #{File.basename(file)}"
    source = JSON[`./swflux/dist/swflux #{file}`]
    formatted = JSON.neat_generate(source)
    File.open("./webgl-prototype/test/#{File.basename(file, '.swf')}.json", 'w') { |f| f.write(formatted) }
  end
end
