binstubs = nil

bundle_config_path = Pathname.new(__FILE__) + '../.bundle/config'
if File.exist?(bundle_config_path)
  yaml = File.read(bundle_config_path)
  binstubs = YAML.load(yaml)["BUNDLE_BIN"]
end

guard 'rspec', binstubs: binstubs do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end

guard 'rspec', :spec_paths => "spec-dummy/spec", cli: "-I spec-dummy/spec --tag ~dynamic",
  binstubs: binstubs,
  env: { 'RAILS_ENV' => 'test_static' } do
end

guard 'rspec', :spec_paths => "spec-dummy/spec", cli: "-I spec-dummy/spec --tag ~static",
  binstubs: binstubs,
  env: { 'RAILS_ENV' => 'test_dynamic' } do
end
