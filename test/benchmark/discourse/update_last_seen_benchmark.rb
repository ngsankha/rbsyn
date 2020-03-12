# benchmark: true
# source: https://github.com/discourse/discourse/blob/bd49d4af1a19feb303f0658ae51bfeba81687519/app/models/user.rb#L728
require "test_helper"

describe "Discourse" do
  it "update_last_seen!" do
    skip

    define :update_last_seen!, "TODO", [] do

      assert_equal generate_program, %{
def update_last_seen!(now = Time.zone.now)
  now_date = now.to_date
  # Only update last seen once every minute
  redis_key = "user:#{id}:#{now_date}"
  return unless Discourse.redis.setnx(redis_key, "1")

  Discourse.redis.expire(redis_key, SiteSetting.active_user_rate_limit_secs)
  update_previous_visit(now)
  # using update_column to avoid the AR transaction
  update_column(:last_seen_at, now)
  update_column(:first_seen_at, now) unless self.first_seen_at

  DiscourseEvent.trigger(:user_seen, self)
end
}.strip

    end
  end
end
