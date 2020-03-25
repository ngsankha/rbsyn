Fabricator(:upload, class_name: Upload) do
  url { sequence(:upload_id) { |i| "https://s3.amazonaws.com/bucket/#{i}" } }
end
