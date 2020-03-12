require "test_helper"

describe "Synthetic" do
  it "branching" do
    skip
    load_typedefs :stdlib, :active_record

    class SiteSettings
      class << self
        reserved_usernames = []
        attr_accessor :reserved_usernames
      end

      def self.reserved_username?(username)
        SiteSettings.reserved_usernames.include? username
      end
    end
    RDL.type SiteSettings, 'self.reserved_username?', '(String) -> %bool', wrap: false

    define :username_available?, "(String) -> %bool", [User, UserEmail, SiteSettings] do

      reset {
        SiteSettings.reserved_usernames = []
      }

      spec "returns true when user doesn't exist" do
        pre {
          username_available? 'bruce1'
        }

        post { |result|
          assert { result == true }
        }
      end

      spec "returns false when user exists" do
        pre {
          u = Fabricate(:user)
          username_available? u.username
        }

        post { |result|
          assert { result == false }
        }
      end

      spec "returns false when username is reserved" do
        pre {
          SiteSettings.reserved_usernames = ['apple', 'dog']
          username_available? 'apple'
        }

        post { |result|
          assert { result == false }
        }
      end

      putsyn generate_program
    end
  end
end
