RSpec.configure do |config|
  config.before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end
end
