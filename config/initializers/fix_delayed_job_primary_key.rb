# config/initializers/fix_delayed_job_primary_key.rb
if defined?(Delayed::Backend::ActiveRecord::Job)
  Delayed::Backend::ActiveRecord::Job.primary_key = :id
end