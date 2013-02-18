guard 'rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end


guard 'rspec', :spec_paths => "spec-dummy/spec", cli: "-I spec-dummy/spec --tag ~dynamic",
  env: { 'RAILS_ENV' => 'test_static' } do
end

guard 'rspec', :spec_paths => "spec-dummy/spec", cli: "-I spec-dummy/spec --tag ~static",
  env: { 'RAILS_ENV' => 'test_dynamic' } do
end
